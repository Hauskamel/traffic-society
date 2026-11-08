extends SceneTree
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
	for index in range(4):
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
		var offset := -0.45 if car.model_kind == "van" else 0.0
		scene.player.position = Vector3(7.1 + offset, 0.1, 5 + car.body_length / 2.0 + 1.6)
		scene.eyes.look_at(car.cargo_zone.global_position + Vector3(offset, 0, 0))
		await physics_frame
		await physics_frame
		check(not scene.begin_cargo_search(car), "Closed cargo must reject a search: " + car.model_kind)
		var rear: Node
		for part in car.parts:
			if part.kind == "trunk":
				rear = part
				break
		rear.toggle()
		for i in range(60):
			rear._physics_process(1.0 / 60.0)
		await physics_frame
		await physics_frame
		scene.refresh_encounter_ui()
		check(scene.hovered_part == car.cargo_zone and car.cargo_zone.highlighted, "Crosshair must mark open interior separately: " + car.model_kind)
		check(scene.interact_hint.text.contains("durchsuchen"), "Interior hint must offer search")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://cargo-world-" + car.model_kind + ".png")
		key(scene, KEY_E)
		check(scene.cargo_search_car == car and not scene.inventory_view.visible, "E must begin short search before revealing cargo")
		for i in range(210):
			scene._physics_process(1.0 / 60.0)
		var ui = scene.inventory_view
		check(ui.visible and ui.vehicle_mode and ui.npc_inventory == car.cargo_inventory, "Search must open correct cargo inventory: " + car.model_kind)
		check(car.driver.state == car.driver.State.SEATED, "Driver must be allowed to remain seated")
		check(not car.release(), "Departure must be blocked while cargo is being searched")
		var id: String = car.cargo_inventory.items[0].id
		ui.select_item(id, "npc")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://cargo-content-" + car.model_kind + ".png")
		ui.take_button.pressed.emit()
		check(not car.cargo_props.get_child(0).visible, "Taking item must remove matching world prop")
		ui.return_button.pressed.emit()
		check(car.cargo_props.get_child(0).visible, "Returning must restore world prop")
		while not car.cargo_inventory.items.is_empty():
			ui.select_item(car.cargo_inventory.items[0].id, "npc")
			ui.take_button.pressed.emit()
		for prop in car.cargo_props.get_children():
			check(not prop.visible, "Empty inventory must leave no cargo props")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://cargo-inventory-" + car.model_kind + ".png")
		key(scene, KEY_ESCAPE)
		check(not ui.visible and not car.cargo_search_active and scene.cargo_search_car == null, "Escape must release search state")
		check(car.driver.state == car.driver.State.SEATED, "Closing cargo search must not alter driver state")
		scene.refresh_encounter_ui()
		key(scene, KEY_E)
		key(scene, KEY_ESCAPE)
		check(not ui.visible and scene.cargo_search_car == null, "Short search must be cancellable")
		scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("PASS: all four interiors, closed/open access, one van door, hover/E, delayed inventory, seated driver, take/return/empty props, Esc and cancellation")
	quit(0 if failures.is_empty() else 1)
