## Integrationsprüfung: compliance.
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
func key(code: int, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	scene._unhandled_input(event)


## Richtet die Testkamera auf den übergebenen Weltpunkt aus.
func aim_at(point: Vector3) -> void:
	scene.eyes.look_at(point)
	scene.equipment.select(0)
	key(KEY_SHIFT)
	scene.equipment.tick(0.25)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	scene._unhandled_input(event)
	scene.equipment.tick(0.3)


## Speichert im grafischen Modus einen Screenshot des aktuellen Testzustands.
func capture(name: String) -> void:
	scene.refresh_encounter_ui()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://compliance-" + name + ".png")


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
	scene.aerial = false
	scene.update_camera()
	var index := 0
	for car in scene.traffic.cars:
		car.position = Vector3(2, 0.08, 8)
		var route: Array[Vector3] = [car.position, Vector3(2, 0.08, -64)]
		car.set_route(route)
		scene.player.position = Vector3(-2, 0.1, 8)
		aim_at(car.driver.head.global_position)
		await physics_frame
		check(
			scene.compliance.aimed_car() == car,
			"Crosshair must identify seated driver: " + car.model_kind
		)
		scene.compliance.tick(0.3)
		check(
			car.driver.surrendered and not car.driver.arrested,
			"Glock forces surrender but does not arrest automatically"
		)
		check(absf(car.driver.limbs[2].rotation.z) > 2, "Hands raised inside cabin")
		var speed: float = car.speed
		car._physics_process(0.1)
		check(
			car.speed < speed and car.speed > 0 and car.driver.state == car.driver.State.SEATED,
			"Driver slows before exiting"
		)
		if index == 0:
			await capture("cabin")
		for i in range(500):
			car._physics_process(1.0 / 60.0)
			car.driver._physics_process(1.0 / 60.0)
		check(
			(
				car.state == car.State.PARKED
				and car.speed == 0
				and car.driver.state == car.driver.State.OUTSIDE
			),
			"Moving driver stops and exits"
		)
		check(absf(car.driver.limbs[2].rotation.z) > 2, "Hands remain raised throughout exit")
		scene.equipment.cancel()
		check(car.driver.surrendered, "Surrender persists when weapon lowered")
		check(
			not car.request_departure() and not car.driver.request_enter(),
			"Surrendered driver cannot drive away or re-enter"
		)
		key(KEY_E)
		check(not car.driver.arrested, "Handcuffing has a proximity requirement")
		scene.player.position = car.driver.global_position + Vector3(-1.3, 0.1, 0)
		aim_at(car.driver.interaction_point())
		await physics_frame
		check(
			scene.compliance.nearby_car(true) == car,
			"Nearby surrendered person becomes handcuff target"
		)
		if index == 0:
			await capture("hands-up")
		key(KEY_E)
		check(
			car.driver.arrested and not car.driver.surrendered and car.driver.handcuffs.visible,
			"E applies handcuffs directly while aiming"
		)
		check(
			scene.equipment.state == scene.equipment.State.HOLSTERED,
			"Handcuffing holsters the weapon"
		)
		scene.equipment.tick(0.3)
		scene.open_interaction()
		check(
			scene.interaction_open and scene.interaction_actions.has("Streife anfordern"),
			"Roadside arrestee supports normal follow-up menu"
		)
		scene.interaction_index = scene.interaction_actions.find("Streife anfordern")
		scene.confirm_interaction()
		check(
			scene.radio_open and scene.radio_car == car,
			"Radio retains roadside arrestee as subject"
		)
		scene.call_patrol()
		check(
			scene.patrol.source == car and car.pickup_reserved,
			"Patrol request uses roadside source, not previous bay subject"
		)
		check(scene.patrol.cancel_waiting(), "Roadside request can be cancelled")
		scene.set_radio_open(false)
		car.driver.set_arrested(false)
		check(car.request_departure(), "Released roadside driver can enter and depart")
		car.state = car.State.FINISHED
		car.position = Vector3(70, 0.08, 70)
		index += 1
	var outside = scene.traffic.cars.back()
	outside.position = Vector3(2, 0.08, 8)
	outside.state = outside.State.PARKED
	outside.driver.state = outside.driver.State.OUTSIDE
	outside.driver.apply_pose(1)
	scene.player.position = Vector3(-4, 0.1, 8)
	aim_at(outside.driver.head.global_position)
	scene.equipment.selected = 1
	scene.compliance.tick(0.4)
	check(not outside.driver.surrendered, "Taser does not trigger Glock surrender")
	scene.equipment.selected = 0
	scene.eyes.look_at(outside.driver.head.global_position + Vector3(0, 0, 10))
	scene.compliance.tick(0.4)
	check(not outside.driver.surrendered, "Looking past NPC must not force surrender")
	scene.eyes.look_at(outside.driver.head.global_position)
	var wall := StaticBody3D.new()
	var hit := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 4, 4)
	hit.shape = box
	wall.add_child(hit)
	scene.add_child(wall)
	wall.global_position = (scene.eyes.global_position + outside.driver.head.global_position) / 2
	await physics_frame
	await physics_frame
	scene.compliance.tick(0.4)
	check(not outside.driver.surrendered, "Solid world wall blocks intimidation")
	wall.queue_free()
	await physics_frame
	await physics_frame
	scene.compliance.tick(0.4)
	check(
		outside.driver.surrendered and outside.driver.state == outside.driver.State.OUTSIDE,
		"Already outside NPC raises hands without entry/exit"
	)
	outside.driver.set_arrested(true)
	scene.compliance.tick(0.4)
	check(
		outside.driver.arrested and not outside.driver.surrendered,
		"Arrested NPC stays cuffed when aimed at"
	)
	if failures.is_empty():
		print(
			"PASS: four seated drivers, Glock aim detection, hands up, braking before exit, persistent surrender, close-range E handcuffs and roadside follow-up"
		)
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
