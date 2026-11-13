extends SceneTree
## Requires a display: godot --path . --script res://tests/vehicles/vehicle_parts_test.gd
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func press_e(scene: Node) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	scene._unhandled_input(event)

func animate(car: Node, frames := 60) -> void:
	for i in range(frames):
		for part in car.parts:
			part._physics_process(1.0 / 60.0)
		car.driver._physics_process(1.0 / 60.0)

func run() -> void:
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for other in scene.traffic.cars:
		other.set_physics_process(false)
		other.driver.set_physics_process(false)
		for part in other.parts:
			part.set_physics_process(false)
	var car = scene.traffic.cars[0]
	car.position = Vector3(7.1, 0.08, 5)
	car.state = car.State.PARKED
	scene.traffic.controlled_car = car
	scene.aerial = false
	scene.update_camera()
	check(car.parts.size() == 3, "Sedan must have two doors and a trunk")
	for part in car.parts:
		if part.kind == "trunk":
			scene.player.position = Vector3(7.1, 0.1, 8.8)
		elif part.kind == "driver_door":
			scene.player.position = Vector3(4.8, 0.1, 4.7)
		else:
			scene.player.position = Vector3(9.4, 0.1, 4.7)
		scene.eyes.look_at(part.global_position)
		await physics_frame
		await physics_frame
		scene.refresh_encounter_ui()
		check(scene.hovered_part == part and part.highlighted, "Crosshair must highlight the correct area: " + part.kind)
		check(scene.interact_hint.text.contains(part.title), "E hint must name the hovered part")
		press_e(scene)
		animate(car)
		check(part.opened and absf(part.angle()) > 1, "E must animate opening: " + part.kind)
		check(not car.release(), "Car must not drive with an open part")
		scene.eyes.look_at(part.global_position)
		await physics_frame
		await physics_frame
		scene.refresh_encounter_ui()
		check(scene.hovered_part == part, "Open part must remain targetable for closing")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://part-" + part.kind + ".png")
		press_e(scene)
		animate(car)
		check(part.is_closed(), "E must close the open part")
		scene.eyes.rotation.x = 1.2
		scene.refresh_encounter_ui()
		check(scene.hovered_part == null and not part.highlighted, "Looking away must remove highlight")
	# World geometry must still occlude a highlighted door.
	var left = car.parts[2]
	scene.player.position = Vector3(4.8, 0.1, 4.7)
	scene.eyes.look_at(left.global_position)
	var wall := StaticBody3D.new()
	var wall_hit := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(0.15, 2.0, 2.0)
	wall_hit.shape = wall_shape
	wall.add_child(wall_hit)
	scene.add_child(wall)
	wall.global_position = Vector3(5.5, 1.0, left.global_position.z)
	await physics_frame
	await physics_frame
	scene.update_part_focus()
	check(scene.hovered_part == null, "A wall must block crosshair interaction")
	wall.queue_free()
	await physics_frame
	await physics_frame
	scene.player.position = Vector3(7.1, 0.1, 12)
	scene.eyes.look_at(car.parts[0].global_position)
	scene.update_part_focus()
	check(scene.hovered_part == null, "Out-of-range trunk must not highlight")
	# Window remains a separate driver interaction, above the door's hit area.
	scene.player.position = Vector3(4.8, 0.1, car.window_point.global_position.z)
	scene.eyes.look_at(car.window_point.global_position)
	await physics_frame
	await physics_frame
	press_e(scene)
	check(scene.interaction_open, "Looking at window must still open the driver menu")
	scene.close_interaction()
	# Driver animation must take over a manually opened door without snapping it shut.
	var door = car.parts[2]
	door.toggle()
	animate(car)
	check(car.driver.request_exit(), "Driver must exit through a manually opened door")
	animate(car, 1)
	check(absf(car.driver_door.rotation.y) > 1.0, "Exit must not snap an already open door closed")
	check(not door.toggle(), "Manual toggle must be blocked during driver animation")
	animate(car, 300)
	check(door.is_closed(), "Automatic exit must leave the manual part in a closed state")
	check(car.driver.request_enter(), "Driver must still re-enter")
	animate(car, 300)
	check(car.release(), "Closed car with seated driver must accept release")
	check(not door.toggle(), "Moving vehicles must not allow opening parts")
	if failures.is_empty():
		print("PASS: crosshair highlighting, named E prompts, both doors/trunk open-close, driver menu, animation handoff and release guards")
	quit(0 if failures.is_empty() else 1)
