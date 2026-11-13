## Prüft LCD-Raster und bewusst funktionslose Einsatzknöpfe des Funkgeräts.
## Visuelle Prüfung im Fenster; die Backend-Sperre ist auch headless prüfbar.

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


## Prüft Anzeige, Anzahl und Nebenwirkungsfreiheit der Auswahlknöpfe.
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
	check(view.service_buttons.size() == 4, "Display contains four service buttons")
	var grids = view.find_children("*", "GridContainer", true, false)
	check(grids.size() == 1 and grids[0].columns == 2, "Two buttons per row")
	for i in range(4):
		var button: Button = view.service_buttons[i]
		check(
			button.text == view.SERVICES[i][1] and button.icon != null,
			"Every service has an icon and caption"
		)
		check(
			button.pressed.get_connections().is_empty(), "Service buttons have no dispatch callback"
		)
		button.pressed.emit()
	check(
		not scene.patrol.active() and scene.traffic.cars.size() == 4,
		"Preview clicks dispatch no units"
	)
	if DisplayServer.get_name() != "headless":
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("user://walkie-talkie.png")
	scene.set_radio_open(false)
	check(not view.visible and not scene.radio_open, "Radio closes without changing incident state")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print(
			"PASS: LCD radio, 2x2 icons/captions, inert service buttons, no dispatch and open/close"
		)
	quit(0 if failures.is_empty() else 1)
