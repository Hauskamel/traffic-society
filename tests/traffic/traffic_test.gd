extends SceneTree
## Run: godot --headless --path . --script res://tests/traffic/traffic_test.gd
var errors: Array[String] = []
var scene: Node
var traffic: Node
var seen_plates: Dictionary = {}

func check(ok: bool, message: String) -> void:
	if not ok and not errors.has(message):
		errors.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func step() -> void:
	traffic._physics_process(1.0 / 60.0)
	var identities: Dictionary = {}
	for car in traffic.cars:
		car.set_physics_process(false)
		car._physics_process(1.0 / 60.0)
		check(not identities.has(car.driver_name), "Driver must never appear in two cars simultaneously")
		identities[car.driver_name] = true
		seen_plates[car.plate_number] = true
	for i in range(traffic.cars.size()):
		for j in range(i + 1, traffic.cars.size()):
			var a = traffic.cars[i]
			var b = traffic.cars[j]
			if a.state == a.State.FINISHED or b.state == b.State.FINISHED:
				continue
			var overlap: bool = absf(a.position.x - b.position.x) < 1.8 and absf(a.position.z - b.position.z) < (a.body_length + b.body_length) / 2.0 - 0.1
			check(not overlap, "Moving cars must not overlap")

func run() -> void:
	scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.set_physics_process(false)
	traffic = scene.traffic
	traffic.set_physics_process(false)
	check(traffic.cars.size() == 4, "Initial traffic must contain four different models")
	var models: Dictionary = {}
	for car in traffic.cars:
		car.set_physics_process(false)
		models[car.model_kind] = true
	check(models.size() == 4, "Models must differ in geometry, not only paint")
	# Two minutes without commands: all vehicles must pass without pulling over.
	for i in range(7200):
		step()
		for car in traffic.cars:
			check(car.state == car.State.DRIVING or car.state == car.State.FINISHED, "No car may stop for a control without an order")
	check(seen_plates.size() == 4, "All prepared identities must circulate")
	check(traffic.cars.size() > 0 and traffic.cars.size() <= 4, "Traffic must remain replenished and bounded")
	# Select an eligible car, but do not issue a stop yet.
	var target: Node
	for i in range(800):
		for car in traffic.cars:
			if car.can_stop():
				target = car
				break
		if target != null:
			break
		step()
	check(target != null, "Replenished traffic must offer another controllable car")
	if target == null:
		quit(1)
		return
	traffic.select_car(target)
	for i in range(30):
		step()
	check(target.state == target.State.DRIVING, "Selection alone must not stop a vehicle")
	scene.aerial = false
	scene.order_stop()
	check(target.state == target.State.DRIVING, "Control orders must not work from first person")
	scene.aerial = true
	check(traffic.request_control(), "Explicit order must reserve the bay")
	check(not traffic.request_control(), "Only one control may be active")
	for i in range(3600):
		step()
	check(target.state == target.State.PARKED, "Ordered car must park while other traffic passes")
	check(traffic.controlled_car == target, "Parking control must retain its owner")
	for car in traffic.cars:
		if car != target and car.can_stop():
			traffic.select_car(car)
			check(not traffic.request_control(), "Occupied bay must reject a second car")
			break
	check(target.release(), "Parked vehicle must accept release")
	for i in range(7200):
		step()
		if traffic.controlled_car == null:
			break
	check(traffic.controlled_car == null, "Released vehicle must merge and eventually free the bay")
	check(traffic.cars.size() <= 4, "Traffic must stay bounded after a control")
	# Repeat controls for each body shape at different traffic phases.
	var phase := 0
	for kind in ["sedan", "hatch", "van", "pickup"]:
		var next_target: Node
		for i in range(6000):
			for car in traffic.cars:
				if car.model_kind == kind and car.can_stop():
					next_target = car
					break
			if next_target != null:
				break
			step()
		check(next_target != null, "Every model must return for another control: " + kind)
		if next_target == null:
			continue
		traffic.select_car(next_target)
		check(traffic.request_control(), "Control must work for model: " + kind)
		for i in range(3000):
			step()
			if next_target.state == next_target.State.PARKED:
				break
		check(next_target.state == next_target.State.PARKED, "Every model must park: " + kind)
		for i in range(phase * 145):
			step()
		check(next_target.release(), "Every model must accept release: " + kind)
		for i in range(7200):
			step()
			if traffic.controlled_car == null:
				break
		check(traffic.controlled_car == null, "Every model must merge without getting stuck: " + kind)
		phase += 1

	scene.queue_free()
	await process_frame
	if errors.is_empty():
		print("PASS: continuous traffic, four models, no automatic controls, unique drivers, spacing, bay reservation, release and replenishment")
	quit(0 if errors.is_empty() else 1)
