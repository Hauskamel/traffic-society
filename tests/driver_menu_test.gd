extends SceneTree
## Graphical test: godot --path . --script res://tests/driver_menu_test.gd
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func key(scene: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_input(event)

func wheel(scene: Node, button: int) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	scene._unhandled_input(event)

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + name + ".png")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for other in scene.traffic.cars:
		other.set_physics_process(false)
		other.driver.set_physics_process(false)
	var car = scene.traffic.cars[0]
	car.position = Vector3(7.1, 0.08, 5)
	car.state = car.State.PARKED
	scene.traffic.controlled_car = car
	key(scene, KEY_TAB)
	scene.player.position = Vector3(4.9, 0.1, car.window_point.global_position.z)
	scene.eyes.look_at(car.window_point.global_position)
	await physics_frame
	await physics_frame
	key(scene, KEY_E)
	check(scene.interaction_open, "E must open menu")
	var zoom: float = scene.overview.size
	wheel(scene, MOUSE_BUTTON_WHEEL_UP)
	check(scene.interaction_index == scene.interaction_actions.size() - 1, "Wheel up wraps to last action")
	wheel(scene, MOUSE_BUTTON_WHEEL_DOWN)
	check(scene.interaction_index == 0, "Wheel down wraps to first action")
	check(scene.overview.size == zoom, "Menu scrolling must not change overview zoom")
	var yaw: float = scene.player.rotation.y
	var pitch: float = scene.eyes.rotation.x
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(50, 50)
	scene._unhandled_input(mouse)
	check(scene.player.rotation.y == yaw and scene.eyes.rotation.x == pitch, "Menu must pause mouse look")
	key(scene, KEY_ESCAPE)
	check(not scene.interaction_open and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Escape closes menu and retains game control")
	key(scene, KEY_E)
	scene.refresh_encounter_ui()
	await capture("driver-menu-seated")
	key(scene, KEY_E)
	check(car.driver.state == car.driver.State.EXITING, "Confirming first action must start exit")
	check(not scene.interaction_open, "Action must close menu")
	for i in range(70):
		car.driver._physics_process(1.0 / 60.0)
	scene.refresh_encounter_ui()
	await capture("driver-exiting")
	for i in range(240):
		car.driver._physics_process(1.0 / 60.0)
	check(car.driver.state == car.driver.State.OUTSIDE, "Driver must stand outside")
	scene.eyes.look_at(car.driver.interaction_point())
	key(scene, KEY_E)
	check(scene.interaction_actions.has("Einsteigen lassen") and scene.interaction_actions.has("Person durchsuchen"), "Outside menu must offer entry and search")
	scene.refresh_encounter_ui()
	await capture("driver-menu-outside")
	wheel(scene, MOUSE_BUTTON_WHEEL_DOWN)
	wheel(scene, MOUSE_BUTTON_WHEEL_DOWN)
	key(scene, KEY_E)
	check(not scene.interaction_open and car.driver.state == car.driver.State.OUTSIDE, "End conversation must leave driver waiting")
	key(scene, KEY_E)
	wheel(scene, MOUSE_BUTTON_WHEEL_DOWN)
	key(scene, KEY_E)
	check(car.driver.state == car.driver.State.ENTERING, "Confirming entry must start animation")
	for i in range(300):
		car.driver._physics_process(1.0 / 60.0)
	check(car.driver.can_drive(), "Driver must return to seat")
	scene.eyes.look_at(car.window_point.global_position)
	key(scene, KEY_E)
	wheel(scene, MOUSE_BUTTON_WHEEL_DOWN)
	key(scene, KEY_E)
	check(car.state == car.State.LEAVING, "Wheel-selected release must work after re-entry")
	key(scene, KEY_TAB)
	wheel(scene, MOUSE_BUTTON_WHEEL_UP)
	check(scene.overview.size < zoom, "Mouse wheel must still zoom overview")
	if failures.is_empty():
		print("PASS: E menu, wheel navigation/wrap, frozen look, Esc, exit, outside actions, re-entry, release and overview zoom")
	quit(0 if failures.is_empty() else 1)
