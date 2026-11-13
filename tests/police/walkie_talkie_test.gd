## Prüft LCD-Raster und verbundene Einsatzknöpfe des Funkgeräts.
## Visuelle Prüfung im Fenster; die Anforderungen sind auch headless prüfbar.

extends SceneTree
var failures: Array[String] = []


## Startet den Test nach dem Aufbau des Szenenbaums.
func _initialize() -> void:
	call_deferred("run")


## Sammelt eine fehlgeschlagene Prüfbedingung.
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


## Prüft Anzeige, Knopfanbindung und verzögerte Einsatzanforderung.
func run() -> void:
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.aerial = false
	scene.update_camera()
	scene.set_radio_open(true)
	await process_frame
	await process_frame
	var view = scene.radio_panel
	check(view.visible and scene.radio_open, "Radio close-up opens in first person")
	check(view.service_buttons.size() == 3, "Display contains three service buttons")
	var grids = view.find_children("*", "GridContainer", true, false)
	check(grids.size() == 1 and grids[0].columns == 2, "Two buttons per row")
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("user://walkie-talkie-ready.png")
	for i in range(3):
		var button: Button = view.service_buttons[i]
		check(
			button.text.begins_with(view.SERVICES[i][1]) and button.icon != null,
			"Every service has an icon and caption"
		)
		check(not button.pressed.get_connections().is_empty(), "Service buttons are connected")
		button.pressed.emit()
	check(
		not scene.patrol.active() and scene.traffic.cars.size() == 4,
		"Requests do not spawn units immediately"
	)
	if DisplayServer.get_name() != "headless":
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("user://walkie-talkie.png")
	check(scene.emergency_dispatch.pending.size() == 3, "Three clicks queue three service requests")
	scene.set_radio_open(false)
	check(not view.visible and not scene.radio_open, "Radio closes without changing incident state")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print(
			"PASS: LCD radio, 2x2 icons/captions, connected service buttons, delayed dispatch and open/close"
		)
	quit(0 if failures.is_empty() else 1)
