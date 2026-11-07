extends SceneTree
## Run: godot --headless --path . --script res://tests/fundamentals_test.gd
var errors: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func advance_car(car: Node, until: int, frames := 6000) -> void:
	for i in range(frames):
		car._physics_process(1.0 / 60.0)
		if car.state == until:
			return
	check(false, "Car did not reach requested state before timeout")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	var car = scene.traffic.cars[0]
	scene.traffic.set_physics_process(false)
	for other in scene.traffic.cars:
		other.set_physics_process(false)
	scene.set_physics_process(false)
	car.set_physics_process(false)
	check(car.can_stop(), "Car must be selectable at the start")
	check(not car.release(), "A driving car cannot be released")
	scene.traffic.select_car(car)
	check(scene.traffic.request_control(), "Control request must succeed")
	check(not car.request_stop(), "Duplicate stop request must be rejected")
	check(not scene.can_interact(), "Car cannot be released while entering the bay")
	advance_car(car, car.State.PARKED)
	check(car.position.distance_to(Vector3(7.1, 0.08, 5)) < 0.05, "Car must park in the designated space")
	check(car.speed == 0, "Parked car must be stationary")
	check(absf(car.rotation.y) < 0.01, "Parked car must face the exit")
	check(not scene.can_interact(), "Overview must not allow releasing at a distance")
	await physics_frame
	# The officer must collide with the parked body.
	scene.player.position = Vector3(4, 0.1, 5)
	var hit = scene.player.move_and_collide(Vector3(4, 0, 0))
	check(hit != null and hit.get_collider() == car, "Parked car must block the officer")
	# Validate range and side; headless cannot capture a mouse, so look checks
	# are covered in the graphical test instead.
	scene.aerial = false
	scene.player.position = Vector3(20, 0.1, 20)
	check(not scene.can_interact(), "Release must fail when too far away")
	check(car.release(), "Parked car must accept release")
	check(not car.release(), "Duplicate release must be rejected")
	advance_car(car, car.State.FINISHED)
	check(car.position.z < -60 and not car.visible, "Departed car must leave and disappear")
	car.new_test_drive()
	check(car.visible and car.can_stop(), "New test drive must restore visible selectable car")
	check(car.wheels.size() == 4, "Car must have four animated wheels")
	# Missed encounter: no reversing into the bay after the entry.
	for i in range(600):
		car._physics_process(1.0 / 60.0)
	check(not car.request_stop(), "Stop request after the entry must be rejected")
	advance_car(car, car.State.FINISHED)
	car.new_test_drive()
	check(car.request_stop(), "Second encounter must be repeatable")
	advance_car(car, car.State.PARKED)
	check(car.release(), "Second encounter release must work")
	advance_car(car, car.State.FINISHED)
	scene.queue_free()
	await process_frame
	if errors.is_empty():
		print("PASS: pull-over, parking, collision, departure, missed entry, repeat encounters")
	quit(0 if errors.is_empty() else 1)
