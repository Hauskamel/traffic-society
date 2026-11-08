extends SceneTree
var failures: Array[String] = []
var scene: Node
var stages: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func step() -> void:
	scene.traffic._physics_process(1.0 / 60.0)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		car._physics_process(1.0 / 60.0)
		for part in car.parts:
			part.set_physics_process(false)
			part._physics_process(1.0 / 60.0)
		car.driver._physics_process(1.0 / 60.0)
	scene.patrol._physics_process(1.0 / 60.0)
	stages[scene.patrol.stage] = true

func scenario(index: int, roadside := false) -> void:
	stages.clear()
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	scene.patrol.set_physics_process(false)
	var source = scene.traffic.cars[index]
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
	source.position = Vector3(2 if roadside else 7.1, 0.08, 5)
	source.surrender_stop = roadside
	source.state = source.State.PARKED
	source.speed = 0
	var bay_car = scene.traffic.cars[1] if roadside else null
	if roadside:
		bay_car.position = Vector3(7.1, 0.08, 5)
		bay_car.state = bay_car.State.PARKED
	scene.traffic.controlled_car = bay_car if roadside else source
	check(not scene.patrol.request_pickup(source), "Non-arrested person cannot be collected")
	check(source.driver.request_exit(), "Source driver must exit")
	for i in range(300):
		source.driver._physics_process(1.0 / 60.0)
	check(source.driver.set_arrested(true), "Outside driver can be arrested")
	check(not source.request_departure(), "Arrested person cannot be released to drive")
	check(scene.patrol.request_pickup(source), "Arrested person must accept pickup request")
	check(not scene.patrol.request_pickup(source), "Duplicate requests must be rejected")
	for i in range(600):
		step()
	check(scene.patrol.patrol == null, "Patrol must not spawn after only ten seconds")
	check(scene.patrol.cancel_waiting() and not source.pickup_reserved, "Pending request can be cancelled")
	check(scene.patrol.request_pickup(source), "Cancelled request can be requested again")
	for i in range(1190):
		step()
	check(scene.patrol.patrol == null, "Patrol must not spawn before 20 seconds")
	var arrested_name: String = source.driver_name
	var parked_checked := false
	for i in range(15000):
		step()
		if scene.patrol.stage == scene.PatrolDispatch.Stage.EXITING and not parked_checked:
			check(scene.patrol.patrol.position.distance_to(Vector3(7.1, 0.08, -5)) < 0.1, "Patrol must park in space two ahead of the source")
			parked_checked = true
		if scene.patrol.stage == scene.PatrolDispatch.Stage.COMPLETE:
			break
	check(parked_checked, "Patrol must reach the second space")
	check(stages.has(scene.PatrolDispatch.Stage.ESCORTING) and stages.has(scene.PatrolDispatch.Stage.BOARDING), "Officer must escort and board the suspect")
	check(stages.has(scene.PatrolDispatch.Stage.DEPARTING), "Patrol must depart with the suspect")
	check(scene.patrol.stage == scene.PatrolDispatch.Stage.COMPLETE, "Pickup must finish without getting stuck")
	check(scene.traffic.in_custody.has(arrested_name), "Collected driver must be recorded in custody")
	check(scene.traffic.controlled_car == (bay_car if roadside else null), "Pickup cleanup preserves any other ongoing bay control")
	for i in range(3000):
		step()
	for car in scene.traffic.cars:
		check(car.driver_name != arrested_name, "Arrested driver must not respawn in traffic")
	scene.queue_free()
	await process_frame

func run() -> void:
	for index in range(4):
		await scenario(index)
	await scenario(0, true)
	if failures.is_empty():
		print("PASS: arrest, duplicate/cancel guards, 20-second spawn delay, second space, officer exit/escort/boarding/return, departure and custody cleanup")
	quit(0 if failures.is_empty() else 1)
