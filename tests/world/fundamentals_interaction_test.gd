## Integrationsprüfung: fundamentals interaction.
## Start über Godot --script; fehlgeschlagene Bedingungen ergeben Exitcode 1.

extends SceneTree
## Run with a display: godot --path . --script res://tests/world/fundamentals_interaction_test.gd
var failed := false


## Sammelt eine fehlgeschlagene Bedingung und gibt den zugehörigen Fehler aus.
func check(ok: bool, text: String) -> void:
	if not ok:
		failed = true
		push_error(text)


## Startet den Testlauf verzögert nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Speichert einen Screenshot als visuelle Prüfspur des Testzustands.
func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + name + ".png")


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	var car = scene.traffic.cars[0]
	for other in scene.traffic.cars:
		other.set_physics_process(false)
	car.set_physics_process(false)
	await screenshot("fundamentals-overview")
	var click := InputEventMouseButton.new()
	click.position = scene.overview.unproject_position(car.global_position + Vector3(0, 1, 0))
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	print("Vehicle screen location: ", click.position)
	check(root.get_visible_rect().has_point(click.position), "Starting car must be visible")
	scene._unhandled_input(click)
	check(scene.traffic.selected_car == car, "Click must select the correct car")
	check(car.state == scene.TrafficCar.State.DRIVING, "Selection alone must never stop the car")
	scene.stop_button.pressed.emit()
	check(
		car.state == scene.TrafficCar.State.PULLING_OVER, "Stop button must send the explicit order"
	)
	# Avoid a hanging test if picking fails.
	if car.state == scene.TrafficCar.State.DRIVING:
		scene.order_stop()
	for i in range(4000):
		car._physics_process(1.0 / 60.0)
		if car.state == scene.TrafficCar.State.PARKED:
			break
	await physics_frame
	scene.refresh_encounter_ui()
	await screenshot("fundamentals-parked")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	scene._unhandled_input(tab)
	check(scene.eyes.current, "Tab must enter first-person view")
	scene.player.position = Vector3(4.8, 0.1, 5.0)
	scene.player.rotation.y = -PI / 2
	scene.eyes.look_at(car.window_point.global_position)
	scene.refresh_encounter_ui()
	check(scene.can_interact(), "Looking at nearby driver window must enable release")
	await screenshot("fundamentals-driver-window")
	# Facing away and the passenger side must not enable interaction.
	scene.player.rotation.y += PI
	check(not scene.can_interact(), "Looking away must prevent release")
	scene.player.position = Vector3(9, 0.1, 5)
	scene.eyes.look_at(car.window_point.global_position)
	check(not scene.can_interact(), "Passenger side must prevent release")
	scene.player.position = Vector3(4.8, 0.1, 5)
	scene.eyes.look_at(car.window_point.global_position)
	var interact := InputEventKey.new()
	interact.keycode = KEY_E
	interact.pressed = true
	scene._unhandled_input(interact)
	check(scene.interaction_open, "E must open the interaction menu")
	check(car.state == scene.TrafficCar.State.PARKED, "Opening a menu must not release the car")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	scene._unhandled_input(wheel)
	check(scene.interaction_index == 1, "Mouse wheel must select release")
	scene._unhandled_input(interact)
	check(
		car.state == scene.TrafficCar.State.LEAVING,
		"Confirming release with E must release the car"
	)
	if not failed:
		print(
			"PASS: vehicle picking, visible spawn, camera switch, window distance/side/look, E release"
		)
	quit(1 if failed else 0)
