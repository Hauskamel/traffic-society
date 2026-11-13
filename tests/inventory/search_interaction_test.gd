## Integrationsprüfung: search interaction.
## Start über Godot --script; fehlgeschlagene Bedingungen ergeben Exitcode 1.

extends SceneTree
var failures: Array[String] = []


## Startet den Testlauf verzögert nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Sammelt eine fehlgeschlagene Bedingung und gibt den zugehörigen Fehler aus.
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


## Übergibt ein Tastaturereignis an die getestete Eingabesteuerung.
func key(scene: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_input(event)


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var car = scene.traffic.cars[0]
	car.set_physics_process(false)
	car.driver.set_physics_process(false)
	car.position = Vector3(7.1, 0.08, 5)
	car.state = car.State.PARKED
	scene.traffic.controlled_car = car
	check(car.driver.request_exit(), "Driver must exit before search")
	for i in range(300):
		car.driver._physics_process(1.0 / 60.0)
	scene.aerial = false
	scene.update_camera()
	scene.player.position = Vector3(3.8, 0.1, car.driver.global_position.z)
	scene.eyes.look_at(car.driver.interaction_point())
	await physics_frame
	await physics_frame
	key(scene, KEY_E)
	check(
		scene.interaction_actions[0] == "Person durchsuchen",
		"Outside menu must offer one search action"
	)
	key(scene, KEY_E)
	check(car.driver.state == car.driver.State.SEARCHING, "Confirm must start search pose")
	check(
		not scene.inventory_view.visible, "Items must stay hidden until search animation completes"
	)
	check(
		not car.driver.request_enter() and not car.release(),
		"Driver must not enter or leave during search"
	)
	for i in range(60):
		car.driver._physics_process(1.0 / 60.0)
		scene._physics_process(1.0 / 60.0)
	check(scene.search_progress.size.y <= 10, "Progress indicator must remain compact")
	check(
		(
			scene.search_progress.visible
			and not scene.crosshair.visible
			and scene.search_progress.value > 0
			and scene.search_progress.value < 100
		),
		"Search must show a partial progress bar instead of crosshair"
	)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://search-progress.png")
	for i in range(240):
		car.driver._physics_process(1.0 / 60.0)
	scene._physics_process(1.0 / 60.0)
	var ui = scene.inventory_view
	check(
		ui.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"Completed search must open inventory with cursor"
	)
	check(
		ui.npc_inventory == car.inventory and ui.player_inventory == scene.player_inventory,
		"View must use real inventories"
	)
	var before_count: int = scene.player_inventory.items.size()
	ui.left_grid.get_child(2).pressed.emit()
	check(
		ui.detail_name.text == "Quittung" and ui.detail.text.contains("Werkstatt"),
		"Selecting receipt must reveal authored details"
	)
	check(
		scene.player_inventory.items.size() == before_count, "Inspecting must not transfer the item"
	)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://search-inventory.png")
	ui.take_button.pressed.emit()
	check(
		scene.player_inventory.items.size() == before_count + 1 and car.inventory.items.size() == 2,
		"Take button must move selected item"
	)
	ui.return_button.pressed.emit()
	check(
		scene.player_inventory.items.size() == before_count and car.inventory.items.size() == 3,
		"Return button must restore item"
	)
	# Held movement and mouse input must not move/look through the UI.
	var position_before: Vector3 = scene.player.position
	var yaw: float = scene.player.rotation.y
	var pressed := InputEventKey.new()
	pressed.keycode = KEY_W
	pressed.physical_keycode = KEY_W
	pressed.pressed = true
	Input.parse_input_event(pressed)
	for i in range(5):
		scene._physics_process(1.0 / 60.0)
	var released := pressed.duplicate() as InputEventKey
	released.pressed = false
	Input.parse_input_event(released)
	check(
		(
			Vector2(scene.player.position.x, scene.player.position.z).distance_to(
				Vector2(position_before.x, position_before.z)
			)
			< 0.01
		),
		"Inventory must lock player movement"
	)
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(80, 30)
	scene._unhandled_input(mouse)
	check(scene.player.rotation.y == yaw, "Inventory must lock mouse look")
	var traffic_car = scene.traffic.cars[1]
	var z_before: float = traffic_car.position.z
	for i in range(30):
		await physics_frame
	check(traffic_car.position.z < z_before, "Traffic must continue while inventory is open")
	key(scene, KEY_ESCAPE)
	check(
		not ui.visible and car.driver.state == car.driver.State.OUTSIDE,
		"Escape must close inventory and restore waiting pose"
	)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Closing must restore game mouse look")
	key(scene, KEY_I)
	check(ui.visible and ui.npc_inventory == null, "I must show only the player's own inventory")
	key(scene, KEY_ESCAPE)
	# Cancelling the short animation must not leave the driver locked.
	scene.eyes.look_at(car.driver.interaction_point())
	key(scene, KEY_E)
	key(scene, KEY_E)
	key(scene, KEY_ESCAPE)
	check(
		(
			car.driver.state == car.driver.State.OUTSIDE
			and not ui.visible
			and scene.searching_driver == null
		),
		"Cancelling search must restore control without revealing or moving items"
	)
	check(car.driver.request_enter(), "Driver must still accept entry after search")
	if failures.is_empty():
		print(
			"PASS: search menu/pose, delayed discovery, three-column inventory, inspect/take/return, movement/look lock, live traffic, Esc, own inventory and cancellation"
		)
	quit(0 if failures.is_empty() else 1)
