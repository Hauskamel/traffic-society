extends SceneTree
## Run with a display: godot --path . --script res://tests/fundamentals_interaction_test.gd
var failed := false

func check(ok: bool, text: String) -> void:
	if not ok:
		failed = true
		push_error(text)

func _initialize() -> void:
	call_deferred("run")

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + name + ".png")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.set_physics_process(false)
	scene.car.set_physics_process(false)
	await screenshot("fundamentals-overview")
	var click := InputEventMouseButton.new()
	click.position = scene.overview.unproject_position(scene.car.global_position + Vector3(0, 1, 0))
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	print("Vehicle screen location: ", click.position)
	check(root.get_visible_rect().has_point(click.position), "Starting car must be visible")
	scene._unhandled_input(click)
	check(scene.car.state == scene.TrafficCar.State.PULLING_OVER, "Click must select car via physics ray")
	# Avoid a hanging test if picking fails.
	if scene.car.state == scene.TrafficCar.State.DRIVING:
		scene.order_stop()
	for i in range(4000):
		scene.car._physics_process(1.0 / 60.0)
		if scene.car.state == scene.TrafficCar.State.PARKED:
			break
	await physics_frame
	scene.refresh_encounter_ui()
	await screenshot("fundamentals-parked")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	scene._unhandled_input(tab)
	check(scene.eyes.current, "Tab must enter first-person view")
	scene.player.position = Vector3(4.8, 0.1, 5.0)
	scene.player.rotation.y = -PI / 2
	scene.eyes.look_at(scene.car.window_point.global_position)
	scene.refresh_encounter_ui()
	check(scene.can_release(), "Looking at nearby driver window must enable release")
	await screenshot("fundamentals-driver-window")
	# Facing away and the passenger side must not enable interaction.
	scene.player.rotation.y += PI
	check(not scene.can_release(), "Looking away must prevent release")
	scene.player.position = Vector3(9, 0.1, 5)
	scene.eyes.look_at(scene.car.window_point.global_position)
	check(not scene.can_release(), "Passenger side must prevent release")
	scene.player.position = Vector3(4.8, 0.1, 5)
	scene.eyes.look_at(scene.car.window_point.global_position)
	var interact := InputEventKey.new()
	interact.keycode = KEY_E
	interact.pressed = true
	scene._unhandled_input(interact)
	check(scene.car.state == scene.TrafficCar.State.LEAVING, "E must release the car")
	if not failed:
		print("PASS: vehicle picking, visible spawn, camera switch, window distance/side/look, E release")
	quit(1 if failed else 0)
