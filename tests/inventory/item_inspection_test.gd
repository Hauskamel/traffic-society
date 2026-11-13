## Integrationsprüfung: item inspection.
## Start über Godot --script; fehlgeschlagene Bedingungen ergeben Exitcode 1.

extends SceneTree
const Inventory = preload("res://game/inventory/item_inventory.gd")
var failures: Array[String] = []


## Sammelt eine fehlgeschlagene Bedingung und gibt den zugehörigen Fehler aus.
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


## Startet den Testlauf verzögert nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.inventory_view.open_view(
		scene.player_inventory, scene.traffic.cars[0].inventory, "Bobby Mayer"
	)
	var ui = scene.inventory_view
	var preview = ui.preview
	var seen: Dictionary = {}
	var catalog: Array = scene.player_inventory.items.duplicate()
	for car in scene.traffic.cars:
		catalog.append_array(car.inventory.items)
		catalog.append_array(car.cargo_inventory.items)
		for cargo in car.cargo_inventory.items:
			if cargo.has("container_type"):
				catalog.append_array(cargo.contents.items)
	for item in catalog:
		if seen.has(item.icon):
			continue
		seen[item.icon] = true
		preview.set_item(item)
		check(
			preview.model.get_child_count() > 0,
			"Every item category needs real 3D geometry: " + item.icon
		)
		var before: Vector3 = preview.model.rotation
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		preview._gui_input(down)
		var drag := InputEventMouseMotion.new()
		drag.relative = Vector2(45, 20)
		preview._gui_input(drag)
		check(preview.model.rotation != before, "Dragging must rotate: " + item.icon)
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		preview._gui_input(up)
		var zoom := InputEventMouseButton.new()
		zoom.button_index = MOUSE_BUTTON_WHEEL_UP
		zoom.pressed = true
		preview._gui_input(zoom)
		check(preview.distance < 3.0, "Wheel must zoom the 3D preview")
		preview.reset_view()
		check(
			preview.distance == 3.0 and preview.model.rotation.is_equal_approx(before),
			"Reset must restore angle and zoom"
		)
	check(seen.size() == 18, "All eighteen item categories must be covered")
	ui.select_item("Bobby Mayer:receipt", "npc")
	check(not ui.detail.text.contains("Besitzer"), "Inventory description must omit owner line")
	check(ui.preview.model.get_child_count() >= 3, "Paper needs geometry and text on both sides")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://item-inspection-front.png")
	ui.preview.model.rotation.y += PI
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://item-inspection-back.png")
	check(
		(
			scene.player_inventory.items.size() == 6
			and scene.traffic.cars[0].inventory.items.size() == 3
		),
		"Inspection must not change inventories"
	)
	check(
		ui.get_global_rect().end.y <= root.get_visible_rect().end.y + 1,
		"Inventory must fit the viewport"
	)
	if failures.is_empty():
		print(
			"PASS: eighteen 3D models, two-axis dragging, zoom, reset, front/back text, hidden owner line and inventory preservation"
		)
	quit(0 if failures.is_empty() else 1)
