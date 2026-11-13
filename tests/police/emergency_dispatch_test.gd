## Prüft Funkkontingente, verzögerten Spawn, Besatzungen, Blaulicht und Spaziergänge.
extends SceneTree
var errors: Array[String] = []


## Startet die Szenario-Prüfung nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Sammelt eine fehlgeschlagene Bedingung.
func check(ok: bool, text: String) -> void:
	if not ok:
		errors.append(text)
		push_error(text)


## Wartet echte Physikschritte mit laufender Fahrzeug-/Figurensteuerung ab.
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame


## Prüft Limits, jede Besatzung und die spätere Bewegung ohne Fachaufgaben.
func run() -> void:
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.position = Vector3(-50, .08, 50)
	var dispatch = scene.emergency_dispatch
	dispatch.set_physics_process(false)
	check(scene.radio_panel.service_buttons.size() == 3, "Polizei button removed")
	check(
		(
			scene.control_hint.text.contains("Inventar")
			and scene.control_hint.text.contains("Funkgerät")
		),
		"HUD shows essential controls"
	)
	for button in scene.radio_panel.service_buttons:
		button.pressed.emit()
	check(
		dispatch.used.fire == 1 and dispatch.used.medical == 1 and dispatch.used.backup == 1,
		"Each button requests correct service"
	)
	check(
		dispatch.request("backup") and not dispatch.request("backup"),
		"Backup can be requested twice only"
	)
	check(
		(
			not dispatch.request("fire")
			and not dispatch.request("medical")
			and not dispatch.request("invalid")
		),
		"One-use and unknown-service guards"
	)
	for button in scene.radio_panel.service_buttons:
		check(button.disabled, "Exhausted service disabled")
	dispatch._physics_process(9.9)
	check(dispatch.units.is_empty(), "No unit before ten seconds")
	dispatch._physics_process(.11)
	check(
		dispatch.units.size() == 1,
		"First unit spawns after ten seconds; occupied entry queues others"
	)
	check(dispatch.units[0].service == "fire", "Spawn queue preserves request order")
	dispatch.set_physics_process(true)
	await frames(2400)
	check(
		dispatch.units.size() == 4 and dispatch.pending.is_empty(),
		"All four reserved vehicles arrive"
	)
	var totals := {"backup": 0, "medical": 0, "fire": 0}
	for unit in dispatch.units:
		totals[unit.service] += 1
		check(unit.state == unit.State.PARKED, "Response unit reaches its separate parking space")
		check(unit.crew.size() == (4 if unit.service == "fire" else 2), "Expected crew count")
		check(
			unit.blue_lights.enabled and unit.blue_lights.lights.size() == 2,
			"Blue beacons present and enabled"
		)
		unit.blue_lights.clock = .01
		unit.blue_lights._process(0)
		check(
			unit.blue_lights.lights[0].light_energy + unit.blue_lights.lights[1].light_energy > 0,
			"Beacon actually emits light"
		)
		unit.blue_lights._process(.16)
		var before: Array[Vector3] = []
		for actor in unit.crew:
			check(actor.state == actor.State.OUTSIDE, "Crew exits quickly")
			check(
				actor.transition_duration < 1.0, "Emergency exits faster than civilian transition"
			)
			before.append(actor.global_position)
		if unit.service == "medical":
			check(
				unit.has_node("Stretcher") and unit.cargo_accessible(),
				"Ambulance has rear stretcher and open cargo doors"
			)
		if unit.service == "fire":
			check(
				unit.body_length > 6 and unit.crew[2].seat.z < 0 and unit.crew[3].seat.z > 0,
				"Large fire truck has three front seats and one rear seat"
			)
		await frames(120)
		var moved := 0
		for i in range(unit.crew.size()):
			if unit.crew[i].global_position.distance_to(before[i]) > .1:
				moved += 1
		check(
			moved == unit.crew.size(), "Every crew member wanders instead of performing a mission"
		)
	check(
		totals.backup == 2 and totals.medical == 1 and totals.fire == 1,
		"Final vehicle limits respected"
	)
	if DisplayServer.get_name() != "headless":
		scene.overview.make_current()
		scene.overview.global_position = Vector3(35, 32, 30)
		scene.overview.look_at(Vector3(14, 0, 1))
		scene.overview.size = 52
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("user://emergency-units.png")
	scene.queue_free()
	await process_frame
	if errors.is_empty():
		print(
			"PASS: three buttons, quotas, delayed queued spawn, four vehicles, ten crew, beacons, stretcher, fast exits and wandering"
		)
	quit(0 if errors.is_empty() else 1)
