extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures.append(text)
		push_error(text)
func run() -> void:
	var game = load("res://game/world/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.document_view.open_view(game.traffic.cars[0])
	check(Engine.time_scale < 1, "Fixture enters slowed document mode")
	var key := InputEventKey.new()
	key.keycode = KEY_F9
	key.pressed = true
	game._unhandled_input(key)
	await process_frame
	await process_frame
	check(current_scene.name == "BodyPhysicsLab" and current_scene.actors.size() == 2, "F9 loads interactive lab")
	check(is_equal_approx(Engine.time_scale,1), "Leaving document mode restores simulation speed before lab")
	var lab = current_scene
	lab.region.select(4)
	lab.comparison_hit()
	check(lab.actors[0].strength.left_upper_arm < 1 and lab.actors[1].strength.left_upper_arm < 1, "UI comparison uses selected region for both actors")
	await physics_frame
	await physics_frame
	lab.injury_slider.value = .25
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = lab.camera.unproject_position(lab.actors[0].bodies.head.global_position)
	lab._unhandled_input(mouse)
	check(is_equal_approx(lab.actors[0].strength.head,.75) and lab.actors[1].strength.head == 1, "World ray hits only the actually clicked head region")
	lab.reset_actors()
	check(lab.actors[0].strength.left_upper_arm == 1, "Reset rebuilds clean bodies")
	lab.return_to_game()
	await process_frame
	await process_frame
	check(current_scene.name == "Kontrollpunkt" and current_scene.traffic.cars.size() == 4, "Lab returns to playable main scene")
	if failures.is_empty(): print("PASS: F9 lab entry, time-scale cleanup, region selection, reset and main-scene return")
	quit(0 if failures.is_empty() else 1)
