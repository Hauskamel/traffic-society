extends SceneTree
const CargoItem = preload("res://scripts/cargo_item.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func key(scene: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_input(event)

func run() -> void:
	for index in [2, 3]:
		var scene = load("res://main.tscn").instantiate()
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.traffic.set_physics_process(false)
		for other in scene.traffic.cars:
			other.set_physics_process(false)
			other.driver.set_physics_process(false)
			for part in other.parts:
				part.set_physics_process(false)
		var car = scene.traffic.cars[index]
		car.position = Vector3(7.1, 0.08, 5)
		car.state = car.State.PARKED
		scene.traffic.controlled_car = car
		scene.aerial = false
		scene.update_camera()
		scene.player.position = car.to_global(Vector3(0, -0.05, car.body_length / 2.0 + 1.1))
		scene.eyes.look_at(car.cargo_zone.global_position)
		await physics_frame
		await physics_frame
		check(not scene.climber.available(), "Closed loading area must not allow climbing")
		for part in car.parts:
			if part.kind == "trunk":
				part.toggle()
				for i in range(60):
					part._physics_process(1.0 / 60.0)
		await physics_frame
		await physics_frame
		var blocker := StaticBody3D.new()
		var blocker_hit := CollisionShape3D.new()
		var blocker_shape := BoxShape3D.new()
		blocker_shape.size = Vector3(0.7, 1.2, 0.7)
		blocker_hit.shape = blocker_shape
		blocker.add_child(blocker_hit)
		scene.add_child(blocker)
		blocker.global_position = scene.climber.entry(car) + Vector3(0, 0.6, 0)
		await physics_frame
		await physics_frame
		check(not scene.climber.available(), "Occupied landing point must reject climbing")
		blocker.queue_free()
		await physics_frame
		await physics_frame
		check(scene.climber.available(), "Open loading area must offer climbing: " + car.model_kind)
		key(scene, KEY_SPACE)
		check(scene.climber.active, "Space must start the climb")
		for i in range(65):
			scene._physics_process(1.0 / 60.0)
		check(not scene.climber.active and scene.climber.car == car and car.officer_aboard, "Climb must finish on the vehicle: " + car.model_kind)
		check(scene.player.position.y > 0.7, "Player must stand above ground on the load floor")
		check(not scene.search_progress.visible, "Climbing must not show a loading bar")
		check(not car.release(), "Car cannot leave with officer aboard")
		if car.model_kind == "van":
			check(scene.climber.shape().shape.height < 1.8, "Van requires a lower player capsule")
		for part in car.parts:
			if part.kind == "trunk" and part.opened:
				check(not part.toggle(), "Cargo doors must not trap the officer")
		# A short move on the floor must be possible, not blocked by a coarse body box.
		var before: Vector3 = scene.player.position
		scene.player.move_and_collide(Vector3(0, 0, -0.25))
		check(scene.player.position.distance_to(before) > 0.2, "Load floor must be walkable")
		var prop = car.cargo_props.get_child(0)
		var target: Node
		for node in prop.get_children():
			if node is CargoItem:
				target = node
		scene.eyes.look_at(target.global_position)
		check(not car.cargo_zone.can_use(scene.eyes.global_position), "Floor is no longer searchable from inside")
		check(scene.begin_item_inspection(target), "Individual cargo can be inspected while aboard")
		check(scene.inventory_view.visible and not scene.search_progress.visible, "Direct object inspection has no loading bar")
		key(scene, KEY_ESCAPE)
		key(scene, KEY_ESCAPE)
		check(car.officer_aboard, "Closing inspection preserves aboard state")
		key(scene, KEY_SPACE)
		for i in range(65):
			scene._physics_process(1.0 / 60.0)
		check(not scene.climber.active and scene.climber.car == null and not car.officer_aboard, "Space must descend and release vehicle")
		check(scene.player.position.y < 0.2 and is_equal_approx(scene.climber.shape().shape.height, 1.8), "Descent must restore standing capsule on ground")
		# Driver animation alone must never display a search bar.
		check(car.driver.request_exit(), "Driver exit must still work")
		scene.refresh_encounter_ui()
		check(not scene.search_progress.visible, "Exit animation must not display a loading bar")
		scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("PASS: van/pickup climb, walkable floors, crouched van capsule, descent, aboard guards, interior search and search-only progress")
	quit(0 if failures.is_empty() else 1)
