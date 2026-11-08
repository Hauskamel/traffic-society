extends SceneTree
var failures: Array[String] = []
var scene: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func pixel(preview: Node, point: Vector3) -> Vector2:
	return preview.camera.unproject_position(point) * preview.size / Vector2(preview.viewport.size)
func click(preview: Node, point: Vector3) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pixel(preview, point)
	preview._gui_input(event)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://toolbox-" + name + ".png")
func run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
	var car = scene.traffic.cars[0]
	var item: Dictionary = car.cargo_inventory.items[0]
	var knife_id: String = item.id + ":knife"
	check(item.contents.items.size() == 2 and not item.opened, "Bobby has authored closed toolbox with two contents")
	check(scene.traffic.cars[3].cargo_inventory.items[1].contents.items.size() == 1, "Mara has only one hammer")
	var ui = scene.inventory_view
	ui.open_view(scene.player_inventory, car.cargo_inventory, "Fahrzeug " + car.plate_number, "Fahrzeug " + car.plate_number, true)
	ui.select_item(item.id, "npc")
	check(ui.inspect_button.visible, "Toolbox offers deeper inspection")
	ui.inspect_button.pressed.emit()
	await process_frame
	await physics_frame
	await physics_frame
	var view = ui.inspection
	var preview = view.preview
	check(view.visible and not preview.crate.contents_root.visible and not view.detail.text.contains("Messer"), "Closed toolbox does not reveal hidden contents in text or model")
	view.activate("lid")
	check(not item.opened, "Latch must be released first")
	var initial_rotation: Vector3 = preview.model.rotation
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_RIGHT
	down.pressed = true
	preview._gui_input(down)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(30, 10)
	preview._gui_input(motion)
	check(preview.model.rotation != initial_rotation, "Right drag rotates the large inspection")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	preview._gui_input(wheel)
	check(preview.distance < 3.5, "Wheel zooms inspection")
	preview.dragging = false
	preview.reset_view()
	await physics_frame
	await physics_frame
	var latch_point: Vector3 = preview.crate.latch.to_global(Vector3(0, -0.05, 0.03))
	check(preview.pick(pixel(preview, latch_point)) == "latch", "Physical ray picks latch")
	click(preview, latch_point)
	check(item.unlocked, "Click opens latch")
	await capture("closed")
	click(preview, preview.crate.lid.to_global(Vector3(0.4, 0, 0.45)))
	check(item.opened, "Physical lid click opens lid")
	preview.crate._process(1)
	await physics_frame
	await physics_frame
	check(preview.crate.contents_root.visible, "Contents visibly revealed by open lid")
	var knife = preview.crate.contents_root.get_node("knife")
	check(preview.pick(pixel(preview, knife.global_position)) == knife_id, "Physical ray selects visible knife")
	preview.mark(knife_id)
	check(not preview.highlighted.is_empty(), "Hovered tool is visibly highlighted")
	click(preview, knife.global_position)
	check(view.selected_id == knife_id and view.detail.text.contains("dunkelroten"), "Click inspects the visible marked blade")
	await capture("open-knife")
	var before: int = scene.player_inventory.items.size()
	scene.player_inventory.capacity = before
	view.take_selected()
	check(item.contents.items.size() == 2 and scene.player_inventory.items.size() == before, "Full inventory preserves content")
	scene.player_inventory.capacity = 12
	view.take_selected()
	check(item.contents.items.size() == 1 and scene.player_inventory.items.size() == before + 1, "Take moves single item without duplication")
	check(not preview.crate.contents_root.has_node("knife"), "Taken knife disappears from box")
	view.take_selected()
	check(scene.player_inventory.items.size() == before + 1, "Repeated take cannot duplicate")
	view.return_item(knife_id)
	check(item.contents.items.size() == 2 and scene.player_inventory.items.size() == before, "Return puts exact item back into original box")
	view.activate("lid")
	preview.crate._process(1)
	view.activate("latch")
	view.activate("lid")
	check(not item.opened and not item.unlocked, "Closed lid can be latched and cannot reopen until unlocked")
	view.activate("latch")
	view.activate("lid")
	preview.crate._process(1)
	view.activate(knife_id)
	view.take_selected()
	var mara: Dictionary = scene.traffic.cars[3].cargo_inventory.items[1]
	view.open_view(mara, scene.player_inventory)
	mara.opened = true
	view.preview.crate._process(1)
	view.return_item(knife_id)
	check(mara.contents.items.size() == 1 and item.contents.items.size() == 1, "Foreign toolbox cannot accept this knife")
	view.open_view(item, scene.player_inventory)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_input(escape)
	check(ui.visible and not view.visible and item.opened, "First Escape level returns to inventory and preserves open state")
	ui.transfer_selected("npc")
	check(ui.selected_source == "player", "Whole toolbox can move to player inventory")
	ui.inspect_selected()
	check(view.visible and item.opened and view.preview.crate.contents_root.get_child_count() == 1, "Carried toolbox preserves state and missing knife")
	view.close_view()
	ui.select_item(knife_id, "player")
	check(ui.return_button.disabled, "Nested content cannot be returned loose into vehicle or NPC")
	ui.transfer_selected("player")
	check(scene.player_inventory.items.size() == before + 2, "Wrong return preserves both box and knife")
	ui.select_item(item.id, "player")
	ui.transfer_selected("player")
	car.state = car.State.FINISHED
	scene.traffic._physics_process(0)
	check(scene.traffic.spawn_next(52), "Vehicle can return for persistence check")
	var returned = scene.traffic.cars.back()
	var restored: Dictionary = {}
	for cargo in returned.cargo_inventory.items:
		if cargo.id == item.id:
			restored = cargo
	check(not restored.is_empty() and restored.contents == item.contents and item.contents.items.size() == 1 and item.opened, "Returning vehicle reuses opened box and removed contents")
	if failures.is_empty():
		print("PASS: authored contents, physical latch/lid/item picking, hidden contents, animation, take/return/full inventory, carrying, Escape and respawn persistence")
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
