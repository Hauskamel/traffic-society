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
func mouse(button: int, pressed := true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	scene._unhandled_input(event)
func aim() -> void:
	key(KEY_SHIFT)
	scene.equipment.tick(0.25)
	mouse(MOUSE_BUTTON_RIGHT)
	scene.equipment.tick(0.3)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://shooting-" + name + ".png")
func run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var gear = scene.equipment
	var gun = gear.pistol_action
	check(gun.rounds() == 15 and gun.spare_count() == 2 and gun.total_rounds() == 45, "Start: one loaded magazine plus two full inventory magazines")
	key(KEY_TAB)
	gear.tick(0)
	var at: Vector3 = scene.player.position
	key(KEY_R)
	check(scene.player.position == at, "R must no longer reset player position")
	mouse(MOUSE_BUTTON_LEFT)
	check(gun.shots_fired == 0, "Cannot fire while holstered")
	aim()
	scene.eyes.rotation.x = -0.7
	await physics_frame
	mouse(MOUSE_BUTTON_LEFT)
	check(gun.rounds() == 14 and gun.shots_fired == 1, "Aimed click consumes exactly one round")
	check(not gun.last_hit.is_empty(), "Shot ray finds the ground without damage")
	check(gun.flash.visible and gun.recoil > 0, "Shot has flash and recoil")
	await capture("shot")
	mouse(MOUSE_BUTTON_LEFT)
	check(gun.rounds() == 14, "Cooldown prevents duplicate immediate shots")
	gear.tick(0.2)
	check(gun.rounds() == 14, "Holding without another click does not fire automatically")
	var total: int = gun.total_rounds()
	key(KEY_R)
	check(gun.reloading, "R starts magazine exchange")
	check(not gun.fire(), "Cannot shoot while reloading")
	gear.tick(0.8)
	await capture("reload")
	check(gun.rounds() == 14, "Reload must not grant ammunition before completion")
	gear.tick(1.1)
	check(gun.rounds() == 15 and gun.total_rounds() == total and gun.spare_count() == 2, "Tactical reload preserves rounds and returns partial magazine")
	check(not gun.start_reload(), "Full magazine does not reload")
	for i in range(15):
		gear.tick(0.2)
		mouse(MOUSE_BUTTON_LEFT)
	check(gun.rounds() == 0, "15 single clicks exhaust the loaded magazine")
	gear.tick(0.2)
	check(not gun.fire() and gun.rounds() == 0, "Empty click cannot consume negative ammo")
	key(KEY_R)
	gear.tick(2)
	check(gun.rounds() == 15 and gun.total_rounds() == 29, "Empty reload loads next magazine without duplicating ammo")
	gear.tick(0.2)
	mouse(MOUSE_BUTTON_LEFT)
	gear.tick(0.2)
	mouse(MOUSE_BUTTON_LEFT)
	key(KEY_R)
	check(gun.reloading, "Reload with suitable partial spare must start before cancellation")
	gear.tick(0.6)
	var before: int = gun.total_rounds()
	key(KEY_2)
	gear.tick(2)
	check(not gun.reloading and gun.total_rounds() == before and gun.rounds() == 13, "Switching cancels reload without swapping or losing ammo")
	aim()
	mouse(MOUSE_BUTTON_LEFT)
	check(gun.rounds() == 13, "Taser does not consume Glock ammunition")
	key(KEY_1)
	aim()
	for item in scene.player_inventory.items:
		if item.get("icon") == "magazine":
			item.rounds = 0
	gun.sync_descriptions()
	check(not gun.start_reload(), "No suitable spare cannot create ammunition")
	mouse(MOUSE_BUTTON_RIGHT, false)
	key(KEY_SHIFT, false)
	gear.tick(0.3)
	key(KEY_R)
	check(scene.player.position == at, "R remains harmless when holstered")
	if failures.is_empty():
		print("PASS: loaded/spare ammo, no R reset, aimed single shots, hit/flash/recoil, cooldown, empty click, timed reload, retained partials, cancellation and no ammo creation")
	gun.sound.stop()
	gun.click.stop()
	await create_timer(0.25).timeout
	scene.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
