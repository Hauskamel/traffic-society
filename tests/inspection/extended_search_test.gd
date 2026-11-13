extends SceneTree
const CargoItem = preload("res://game/inspection/cargo_item.gd")
var failures: Array[String] = []
var scene: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_input(event)
func target_for(prop: Node) -> CargoItem:
	for child in prop.get_children():
		if child is CargoItem:
			return child
	return null
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://extended-" + name + ".png")
func run() -> void:
	scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	scene.aerial = false
	scene.update_camera()
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		car.state = car.State.PARKED
		car.position = Vector3(50, 0.08, 50)
	for car in scene.traffic.cars:
		car.position = Vector3(7.1, 0.08, 5)
		scene.traffic.controlled_car = car
		var prop = car.cargo_props.get_child(0)
		var target := target_for(prop)
		scene.player.position = car.to_global(Vector3(0, 0.02, car.body_length / 2 + 0.65))
		scene.eyes.look_at(target.global_position + Vector3(0, 0.1, 0))
		check(not target.can_use(scene.eyes.global_position), "Closed cargo blocks object inspection")
		check(not car.cargo_zone.can_use(scene.eyes.global_position) and not scene.begin_cargo_search(car), "Whole-floor search is removed")
		for part in car.parts:
			if part.kind == "trunk":
				part.toggle()
				part._physics_process(2)
		await physics_frame
		await physics_frame
		scene.update_part_focus()
		check(scene.hovered_part is CargoItem and scene.hovered_part.item.id == target.item.id, "Crosshair picks real individual object: " + car.model_kind)
		var wall := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4, 4, 0.1)
		collision.shape = box
		wall.add_child(collision)
		scene.add_child(wall)
		wall.global_position = (scene.eyes.global_position + target.global_position) / 2
		await physics_frame
		await physics_frame
		scene.update_part_focus()
		check(scene.hovered_part == null, "Solid wall prevents selecting cargo through it")
		wall.queue_free()
		await physics_frame
		await physics_frame
		key(KEY_E)
		check(scene.inventory_view.visible and scene.inventory_view.focused_item_id == target.item.id, "E opens only the selected object")
		check(scene.inventory_view.inspection.visible and car.cargo_search_active, "Container opens directly in interactive view and locks departure")
		check(not scene.search_progress.visible and not is_instance_valid(scene.cargo_search_car), "No cargo search wait or progress bar")
		check(scene.inventory_view.left_grid.get_child_count() <= 2, "No unseen vehicle-wide item list is exposed")
		var before: String = scene.inventory_view.selected_id
		scene.inventory_view.select_item(car.cargo_inventory.items[1].id, "npc")
		check(scene.inventory_view.selected_id == before, "Cannot select another unseen cargo item")
		await capture(car.model_kind + "-closed")
		key(KEY_ESCAPE)
		check(scene.inventory_view.visible and not scene.inventory_view.inspection.visible, "First Escape returns to focused inventory")
		key(KEY_ESCAPE)
		check(not scene.inventory_view.visible and not car.cargo_search_active, "Second Escape releases vehicle inspection lock")
		await capture(car.model_kind + "-world")
		car.position = Vector3(50, 0.08, 50)
	var van = scene.traffic.cars[2]
	check(van.has_node("Shelf") and van.cargo_inventory.items.size() == 4, "Van has shelf, three identical buckets and water barrel")
	check(scene.traffic.cars[3].cargo_inventory.items[1].icon == "ladder", "Pickup carries visible ladder")
	for container in [van.cargo_inventory.items[1], scene.traffic.cars[0].cargo_inventory.items[1], van.cargo_inventory.items[3]]:
		scene.inventory_view.open_view(scene.player_inventory)
		var view = scene.inventory_view.inspection
		view.open_view(container, scene.player_inventory)
		await physics_frame
		await physics_frame
		check(not view.preview.crate.contents_root.visible, "Closed container hides contents")
		if not container.unlocked:
			view.activate("latch")
		view.activate("lid")
		view.preview.crate._process(2)
		if container.container_type != "water_barrel":
			check(not view.preview.crate.contents_root.visible, "Lid alone does not reveal concealed compartment")
			view.activate(container.contents.items[0].id)
			check(view.selected_id.is_empty(), "Hidden contents cannot be selected through insert")
			view.activate("insert")
			view.preview.crate._process(2)
		check(view.preview.crate.contents_root.visible, "Package becomes visually available after required steps")
		await physics_frame
		await physics_frame
		var id: String = container.contents.items[0].id
		var parcel = view.preview.crate.contents_root.get_child(0)
		var pixel: Vector2 = view.preview.camera.unproject_position(parcel.global_position) * view.preview.size / Vector2(view.preview.viewport.size)
		check(view.preview.pick(pixel) == id, "Uncovered package is actually visible and clickable in 3D: " + container.container_type)
		view.activate(id)
		check(view.selected_id == id and view.detail.text.contains("bestaetigt"), "Visible package can be inspected without automatic drug confirmation")
		await capture(container.container_type + "-found")
		var count: int = scene.player_inventory.items.size()
		view.take_selected()
		check(container.contents.items.is_empty() and scene.player_inventory.items.size() == count + 1, "Take moves item without duplication")
		view.return_item(id)
		check(container.contents.items.size() == 1 and scene.player_inventory.items.size() == count, "Return restores same original container")
		view.close_view()
		view.open_view(container, scene.player_inventory)
		check(container.opened and view.preview.crate.contents_root.visible, "Reopening preserves lid and insert state")
		scene.inventory_view.close_view()
	var bobby = scene.traffic.cars[0]
	bobby.position = Vector3(7.1, 0.08, 5)
	scene.traffic.controlled_car = bobby
	scene.player.position = bobby.to_global(Vector3(0, 0.02, bobby.body_length / 2 + 0.65))
	var original_box: Dictionary = bobby.cargo_inventory.items[0]
	while not bobby.cargo_inventory.items.is_empty():
		bobby.cargo_inventory.transfer_to(bobby.cargo_inventory.items[0].id, scene.player_inventory)
	bobby.refresh_cargo_props()
	key(KEY_I)
	scene.inventory_view.select_item(original_box.id, "player")
	check(scene.inventory_view.npc_inventory == null and scene.inventory_view.vehicle_return_button.visible, "Empty car permits placing known item back from I without revealing cargo list")
	scene.inventory_view.vehicle_return_button.pressed.emit()
	check(bobby.cargo_inventory.items.size() == 1 and bobby.cargo_props.get_child(0).visible, "Returning known container restores world representation after emptying")
	scene.inventory_view.close_view()
	if failures.is_empty():
		print("PASS: four direct world targets, no floor search, access gates, focused inventory, no delay, four container types, inserts, visible discoveries, transfers and persistence")
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
