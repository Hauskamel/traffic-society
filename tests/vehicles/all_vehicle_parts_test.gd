## Integrationsprüfung: all vehicle parts.
## Start über Godot --script; fehlgeschlagene Bedingungen ergeben Exitcode 1.

extends SceneTree
## Requires a display: godot --path . --script res://tests/vehicles/all_vehicle_parts_test.gd
var failures: Array[String] = []


## Startet den Testlauf verzögert nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Sammelt eine fehlgeschlagene Bedingung und gibt den zugehörigen Fehler aus.
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


## Löst die vorhandene E-Interaktion der Testszene aus.
func press_e(scene: Node) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	scene._unhandled_input(event)


## Führt die prozedurale Animation mit festem Simulationsschritt weiter.
func animate(car: Node) -> void:
	for i in range(60):
		for part in car.parts:
			part._physics_process(1.0 / 60.0)


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	for index in range(4):
		var scene = load("res://game/world/main.tscn").instantiate()
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.traffic.set_physics_process(false)
		for other in scene.traffic.cars:
			other.set_physics_process(false)
			other.driver.set_physics_process(false)
			for part in other.parts:
				part.set_physics_process(false)
		var car = scene.traffic.cars[index]
		car.position = Vector3(7.1, 0.08, 5)
		car.state = car.State.PARKED
		scene.traffic.controlled_car = car
		scene.aerial = false
		scene.update_camera()
		check(
			car.parts.size() == (4 if car.model_kind == "van" else 3),
			"Every model must have cabin doors and a rear opening: " + car.model_kind
		)
		for part in car.parts:
			if part.kind == "trunk":
				scene.player.position = Vector3(
					part.global_position.x, 0.1, car.position.z + car.body_length / 2.0 + 1.7
				)
			else:
				scene.player.position = Vector3(
					4.8 if part.kind == "driver_door" else 9.4, 0.1, part.global_position.z
				)
			scene.eyes.look_at(part.global_position)
			await physics_frame
			await physics_frame
			scene.refresh_encounter_ui()
			var label: String = car.model_kind + ": " + part.title
			check(
				scene.hovered_part == part and part.highlighted,
				"Highlight correct closed area: " + label
			)
			check(scene.interact_hint.text.contains(part.title), "Show named E prompt: " + label)
			press_e(scene)
			animate(car)
			check(part.opened and absf(part.angle()) > 1, "E must open area: " + label)
			check(not car.release(), "Open area must block departure: " + label)
			scene.eyes.look_at(part.global_position)
			await physics_frame
			await physics_frame
			scene.refresh_encounter_ui()
			check(scene.hovered_part == part, "Opened area must stay selectable: " + label)
			press_e(scene)
			animate(car)
			check(part.is_closed(), "E must close area: " + label)
		# Screenshot each model with its rear opening fully open.
		for part in car.parts:
			if part.kind == "trunk":
				part.toggle()
		animate(car)
		scene.player.position = Vector3(7.1, 0.1, car.position.z + car.body_length / 2.0 + 2.0)
		scene.eyes.look_at(car.to_global(Vector3(0, 1.15, car.body_length / 2.0 - 0.7)))
		scene.refresh_encounter_ui()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://rear-" + car.model_kind + ".png")
		for part in car.parts:
			if part.kind == "trunk":
				part.toggle()
		animate(car)
		check(car.release(), "Closed vehicle must accept departure: " + car.model_kind)
		scene.queue_free()
		await process_frame
	if failures.is_empty():
		print(
			"PASS: all four models, both cabin doors, sedan trunk, hatchback, van twin doors, pickup tailgate, hover/E, open-close and departure guards"
		)
	quit(0 if failures.is_empty() else 1)
