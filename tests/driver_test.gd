extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func animate(driver: Node, frames := 180) -> void:
	for i in range(frames):
		driver._physics_process(1.0 / 60.0)

func run() -> void:
	for index in range(4):
		var scene = load("res://main.tscn").instantiate()
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.traffic.set_physics_process(false)
		for other in scene.traffic.cars:
			other.set_physics_process(false)
			other.driver.set_physics_process(false)
		var car = scene.traffic.cars[index]
		var driver = car.driver
		car.position = Vector3(7.1, 0.08, 5)
		car.state = car.State.PARKED
		car.speed = 0
		scene.traffic.controlled_car = car
		scene.player.position = Vector3(4.9, 0.1, driver.global_position.z)
		await physics_frame
		await physics_frame
		check(not driver.request_exit(), "Exit must reject an officer blocking the path: " + car.model_kind)
		scene.player.position = Vector3(3.8, 0.1, driver.global_position.z)
		await physics_frame
		await physics_frame
		check(driver.request_exit(), "Clear exit must work: " + car.model_kind)
		check(not driver.request_exit(), "Duplicate exit must be rejected")
		check(not car.release(), "Car must not drive during exit")
		animate(driver, 45)
		check(absf(car.driver_door.rotation.y) > 0.5, "Door must visibly open")
		var paused_at: float = driver.progress
		scene.player.position = car.to_global(Vector3(-2, 0.1, driver.outside.z))
		await physics_frame
		await physics_frame
		animate(driver, 15)
		check(driver.progress == paused_at, "Obstruction must pause animation")
		scene.player.position = Vector3(3.8, 0.1, 8)
		await physics_frame
		await physics_frame
		animate(driver)
		check(driver.state == driver.State.OUTSIDE, "Driver must finish outside: " + car.model_kind)
		check(absf(driver.global_position.y) < 0.02, "Outside driver must stand on the ground")
		check(not driver.collider.disabled, "Standing driver must have collision")
		check(absf(car.driver_door.rotation.y) < 0.01, "Door must close after exit")
		check(not car.release(), "Car must not drive without its driver")
		# The waiting driver is a physical obstacle for the player.
		scene.player.position = driver.global_position + Vector3(-1.5, 0.05, 0)
		await physics_frame
		await physics_frame
		var hit = scene.player.move_and_collide(Vector3(1.5, 0, 0))
		check(hit != null and hit.get_collider() == driver.body, "Officer must collide with waiting driver")
		scene.player.position = car.to_global(Vector3(-2, 0.1, driver.outside.z))
		await physics_frame
		await physics_frame
		check(not driver.request_enter(), "Blocked return path must be rejected")
		scene.player.position = Vector3(3.8, 0.1, 8)
		await physics_frame
		await physics_frame
		check(driver.request_enter(), "Return must work after making room")
		check(not car.release(), "Car must not drive during entry")
		animate(driver)
		check(driver.can_drive(), "Driver must be seated with a closed door: " + car.model_kind)
		check(driver.collider.disabled, "Seated driver must not leave an outside collider")
		check(car.release(), "Release must work after re-entry")
		scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("PASS: all four models, door animation, blocked paths, pause/resume, exit, driver collision, entry and release guards")
	quit(0 if failures.is_empty() else 1)
