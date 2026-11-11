extends SceneTree
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		check(car.cargo_inventory != car.inventory, "Vehicle and driver inventories must be separate")
		check(car.cargo_inventory.items.size() == (4 if car.model_kind == "van" else 3), "Each vehicle must have its authored cargo items")
	var car = scene.traffic.cars[0]
	var original = car.cargo_inventory
	var id: String = original.items[0].id
	check(original.transfer_to(id, scene.player_inventory), "Cargo must transfer to player")
	car.refresh_cargo_props()
	check(not car.cargo_props.get_child(0).visible, "Taken cargo must disappear from the world")
	car.state = car.State.FINISHED
	scene.traffic._physics_process(0)
	check(scene.traffic.spawn_next(52), "Old vehicle must be allowed to return")
	var returned = scene.traffic.cars.back()
	check(returned.cargo_inventory == original and original.items.size() == 2, "Returning car must not regenerate taken cargo")
	check(not returned.cargo_props.get_child(0).visible, "Respawn visuals must match missing cargo")
	scene.inventory_view.open_view(scene.player_inventory, returned.inventory, returned.driver_name)
	scene.inventory_view.select_item(id, "player")
	check(scene.inventory_view.return_button.disabled, "Cargo must not be returned into a person's pockets")
	scene.inventory_view.open_view(scene.player_inventory, returned.cargo_inventory, "Fahrzeug " + returned.plate_number, "Fahrzeug " + returned.plate_number, true)
	scene.inventory_view.select_item(id, "player")
	scene.inventory_view.return_button.pressed.emit()
	check(original.items.size() == 3 and returned.cargo_props.get_child(0).visible, "Return must restore the item in the correct vehicle")
	# An entirely emptied vehicle must remain empty on its next appearance.
	while not original.items.is_empty():
		original.transfer_to(original.items[0].id, scene.player_inventory)
	returned.state = returned.State.FINISHED
	scene.traffic._physics_process(0)
	check(scene.traffic.spawn_next(52), "Emptied vehicle must return")
	var empty_car = scene.traffic.cars.back()
	check(empty_car.cargo_inventory.items.is_empty(), "Empty inventory must remain empty after respawn")
	for prop in empty_car.cargo_props.get_children():
		check(not prop.visible, "Empty respawn must have no visible cargo")
	scene.inventory_view.open_view(scene.player_inventory, empty_car.cargo_inventory, "Fahrzeug " + empty_car.plate_number, "Fahrzeug " + empty_car.plate_number, true)
	scene.inventory_view.select_item(id, "player")
	scene.inventory_view.return_button.pressed.emit()
	check(empty_car.cargo_props.get_child(0).visible, "Returning after empty respawn must restore its original representation")
	scene.inventory_view.close_view()
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: four fixed cargo inventories, separation, transfer, matching props, respawn persistence and correct return location")
	quit(0 if failures.is_empty() else 1)
