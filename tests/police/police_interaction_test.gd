## Integrationsprüfung: police interaction.
## Start über Godot --script; fehlgeschlagene Bedingungen ergeben Exitcode 1.

extends SceneTree
var failures: Array[String] = []
var scene: Node


## Startet den Testlauf verzögert nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Sammelt eine fehlgeschlagene Bedingung und gibt den zugehörigen Fehler aus.
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


## Übergibt ein Tastaturereignis an die getestete Eingabesteuerung.
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_input(event)


## Speichert im grafischen Modus einen Screenshot des aktuellen Testzustands.
func capture(name: String) -> void:
	scene.refresh_encounter_ui()
	scene.update_radio()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + name + ".png")


## Führt einen definierten Aktualisierungsschritt der Testszene aus.
func step() -> void:
	scene.traffic._physics_process(1.0 / 60.0)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		car._physics_process(1.0 / 60.0)
		for part in car.parts:
			part.set_physics_process(false)
			part._physics_process(1.0 / 60.0)
		car.driver._physics_process(1.0 / 60.0)
	scene.patrol._physics_process(1.0 / 60.0)


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	scene.patrol.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
	check(scene.player_avatar.visible, "Player body must be visible in overview")
	await capture("police-player-overview")
	var source = scene.traffic.cars[0]
	source.position = Vector3(7.1, 0.08, 5)
	source.state = source.State.PARKED
	scene.traffic.controlled_car = source
	source.driver.request_exit()
	for i in range(300):
		source.driver._physics_process(1.0 / 60.0)
	scene.aerial = false
	scene.update_camera()
	check(not scene.player_avatar.visible, "Player body must not obscure first-person camera")
	scene.player.position = Vector3(3.8, 0.1, source.driver.global_position.z)
	scene.eyes.look_at(source.driver.interaction_point())
	key(KEY_E)
	check(
		(
			scene.interaction_actions.has("Weiterfahren lassen")
			and scene.interaction_actions.has("Einsteigen lassen")
		),
		"Outside menu must keep combined departure and entry-only"
	)
	scene.interaction_index = scene.interaction_actions.find("Festnehmen")
	key(KEY_E)
	check(
		source.driver.arrested and source.driver.handcuffs.visible,
		"Arrest action must visibly restrain driver"
	)
	key(KEY_T)
	check(scene.radio_open and scene.radio_panel.visible, "T must show walkie-talkie close-up")
	for button in scene.radio_panel.service_buttons:
		button.pressed.emit()
	check(not scene.patrol.active(), "Preview service buttons must not request an incident")
	# The established backend is still covered independently of the new inert UI.
	check(scene.patrol.request_pickup(source), "Existing pickup backend remains usable")
	scene.update_radio()
	await capture("police-radio-request")
	key(KEY_T)
	check(
		not scene.radio_open and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED,
		"Closing radio must restore gameplay"
	)
	var captured_parking := false
	var captured_escort := false
	var captured_boarding := false
	for i in range(18000):
		step()
		if scene.patrol.stage == scene.PatrolDispatch.Stage.EXITING and not captured_parking:
			scene.aerial = true
			scene.update_camera()
			await capture("police-second-space")
			captured_parking = true
		if scene.patrol.stage == scene.PatrolDispatch.Stage.ESCORTING and not captured_escort:
			await capture("police-escort")
			captured_escort = true
		if scene.patrol.stage == scene.PatrolDispatch.Stage.BOARDING and not captured_boarding:
			scene.aerial = false
			scene.update_camera()
			scene.player.position = Vector3(10.8, 0.1, -2.5)
			scene.eyes.look_at(scene.patrol.patrol.global_position + Vector3(0.4, 1.0, 0.4))
			await capture("police-prisoner-boarding")
			captured_boarding = true
		if scene.patrol.stage == scene.PatrolDispatch.Stage.COMPLETE:
			break
	check(
		captured_parking and captured_escort and captured_boarding,
		"Whole pickup must be visible in the world"
	)
	check(scene.patrol.stage == scene.PatrolDispatch.Stage.COMPLETE, "Radio pickup must complete")
	if failures.is_empty():
		print(
			"PASS: player avatar, outside actions, arrest, held radio/display, 20-second request, second parking space, escort, boarding and departure"
		)
	quit(0 if failures.is_empty() else 1)
