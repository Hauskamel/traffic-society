extends SceneTree
var failures: Array[String] = []
var scene: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func key(code: int, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	scene._unhandled_input(event)
func right(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = pressed
	scene._unhandled_input(event)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://equipment-" + name + ".png")
func run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var gear = scene.equipment
	check(gear.available(0) and gear.available(1) and scene.player_inventory.items.size() == 4, "Both weapons must exist in player inventory")
	check(gear.belt_guns[0].visible and gear.belt_guns[1].visible, "Both weapons start in separate holsters")
	await capture("holsters")
	key(KEY_TAB)
	gear.tick(0)
	for index in range(2):
		key(KEY_1 if index == 0 else KEY_2)
		right(true)
		check(gear.state == gear.State.HOLSTERED, "Right click alone cannot draw")
		right(false)
		key(KEY_SHIFT)
		check(gear.state == gear.State.REACHING and gear.hand_guns[index].visible == false, "Shift reaches without drawing")
		gear.tick(0.25)
		await capture("reach-" + str(index))
		right(true)
		gear.tick(0.3)
		check(gear.state == gear.State.AIMING and gear.hand_guns[index].visible and not gear.belt_guns[index].visible, "Selected weapon moves from belt into aim pose")
		check(gear.belt_guns[1-index].visible, "Other weapon remains holstered")
		await capture("aim-" + str(index))
		key(KEY_SHIFT, false)
		check(gear.state == gear.State.AIMING, "Aim stays while right mouse is held")
		right(false)
		gear.tick(0.3)
		check(gear.state == gear.State.HOLSTERED and gear.belt_guns[index].visible, "Release returns weapon to holster")
	key(KEY_SHIFT)
	right(true)
	gear.tick(0.25)
	check(gear.state == gear.State.AIMING, "Fast Shift-right combination waits for reaching automatically")
	key(KEY_1)
	gear.tick(0)
	check(gear.state == gear.State.HOLSTERED, "Switching weapons cancels aim")
	key(KEY_SHIFT)
	gear.tick(0.25)
	right(true)
	key(KEY_I)
	gear.tick(0)
	check(scene.inventory_view.visible and gear.state == gear.State.HOLSTERED and not gear.hand.visible, "Inventory safely holsters and hides weapons")
	key(KEY_ESCAPE)
	key(KEY_SHIFT)
	gear.tick(0.25)
	right(true)
	key(KEY_T)
	gear.tick(0)
	check(scene.radio_open and not gear.hand.visible, "Radio does not overlap held weapon")
	key(KEY_T)
	key(KEY_TAB)
	gear.tick(0)
	check(gear.state == gear.State.HOLSTERED and not gear.bar.visible and gear.belt_guns[0].visible and gear.belt_guns[1].visible, "Overview shows both holstered weapons, no first-person bar")
	if failures.is_empty():
		print("PASS: inventory weapons, holsters, selection, reach/draw/aim/release, fast combination, switching, inventory/radio/overview cleanup")
	quit(0 if failures.is_empty() else 1)
