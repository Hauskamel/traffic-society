extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	for index in range(4):
		var scene = load("res://game/world/main.tscn").instantiate()
		root.add_child(scene)
		scene.set_physics_process(false)
		var traffic = scene.traffic
		traffic.set_physics_process(false)
		for vehicle in traffic.cars:
			vehicle.set_physics_process(false)
		var departing = traffic.cars[index]
		var arriving = traffic.cars[(index + 1) % 4]
		departing.position = Vector3(7.1, 0.08, 5)
		departing.state = departing.State.PARKED
		traffic.controlled_car = departing
		arriving.new_test_drive()
		arriving.position = Vector3(2, 0.08, 52)
		traffic.select_car(arriving)
		check(not traffic.request_control(), "Parked car must keep its space reserved")
		check(departing.release(), "Old control must be released first")
		departing.position.z = -departing.body_length / 2.0 + 0.1
		check(not traffic.request_control(), "Rear still inside parking space must block a new order")
		departing.position.z = -(departing.body_length + 0.1) / 2.0 - 0.02
		check(traffic.request_control(), "New order must succeed immediately after the full rear clears the space")
		check(traffic.controlled_car == arriving, "New vehicle must own the reservation")
		check(departing.state == departing.State.LEAVING and departing.position.z > -12, "Old car must still be departing within the lay-by")
		check(traffic.cars.has(departing), "Old car must remain in traffic")
		# Finishing the old departure must not remove the new reservation.
		departing.state = departing.State.FINISHED
		traffic._physics_process(0)
		check(traffic.controlled_car == arriving, "Old departure cleanup must preserve the new control")
		scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("PASS: all four lengths, occupied space, rear clearance, overlapping departure/new control and independent cleanup")
	quit(0 if failures.is_empty() else 1)
