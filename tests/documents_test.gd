extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		scene.traffic.controlled_car = car
		car.state = car.State.PARKED
		car.position = Vector3(7.1, 0.08, 5)
		scene.aerial = false
		scene.update_camera()
		scene.player.position = Vector3(4.9, 0.1, car.window_point.global_position.z)
		scene.eyes.look_at(car.window_point.global_position)
		await physics_frame
		await physics_frame
		scene.open_interaction()
		check(scene.interaction_actions.has("Dokumente anfordern"), "Seated driver offers documents")
		scene.interaction_index = scene.interaction_actions.find("Dokumente anfordern")
		scene.confirm_interaction()
		if not scene.document_view.visible:
			quit(1)
			return
		check(scene.document_view.visible and not scene.interaction_open, "Menu opens documents")
		check(scene.document_view.documents.license.Name == car.driver_name, "Document identity matches driver")
		check(scene.document_view.documents.registration.Kennzeichen == car.plate_number, "Registration matches plate")
		check(scene.document_view.cards.size() == 2, "Two documents displayed together")
		check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not scene.can_interact(), "Documents lock world interactions and free mouse")
		await process_frame
		await process_frame
		var view = scene.document_view
		var before: Vector2 = view.cards[0].position
		view.move_card(view.cards[0], Vector2(80, 35))
		check(view.cards[0].position != before, "Document can move within workspace")
		view.move_card(view.cards[0], Vector2(-500, -500))
		check(view.cards[0].position == Vector2.ZERO, "Cards stay reachable")
		view.arrange()
		await process_frame
		if car.driver_name == "Bobby Mayer" and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://documents.png")
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.pressed = true
		scene._unhandled_input(event)
		check(not view.visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Escape returns documents and restores camera input")
		car.driver.request_exit()
		for i in range(300):
			car.driver._physics_process(1.0 / 60.0)
		scene.player.position = Vector3(3.8, 0.1, car.driver.global_position.z)
		scene.eyes.look_at(car.driver.interaction_point())
		scene.open_interaction()
		check(scene.interaction_actions.has("Dokumente anfordern"), "Outside driver also offers documents")
		scene.close_interaction()
	if failures.is_empty():
		print("PASS: four authored document pairs, seated/outside menu, identity/plate, movable cards, bounds, input lock and Escape")
	quit(0 if failures.is_empty() else 1)
