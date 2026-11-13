extends SceneTree
var failures: Array[String] = []
var scene: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func fresh() -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		await process_frame
	scene = load("res://scenes/combat_test/combat_test.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
func exit_driver() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	scene._unhandled_input(key)
	await frames(300)
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("user://combat-"+label+".png")
func run() -> void:
	await fresh()
	check(scene.traffic.cars.size()==1 and not scene.aerial and scene.eyes.current,"One car and first-person start")
	check(scene.test_car.driver.state==scene.test_car.driver.State.SEATED and scene.health.value==100,"Healthy player and seated NPC at start")
	await capture("start")
	await exit_driver()
	check(scene.test_car.driver.state==scene.test_car.driver.State.OUTSIDE,"E orders driver out")
	await frames(55)
	check(scene.slowing and Engine.time_scale<.3 and scene.combat.phase==scene.combat.Phase.REACHING,"Visible reach triggers reaction slow motion")
	await capture("reach")
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		var motion := InputEventMouseMotion.new()
		motion.relative=Vector2(100,0)
		var yaw: float = scene.player.rotation.y
		scene._unhandled_input(motion)
		check(is_equal_approx(angle_difference(yaw,scene.player.rotation.y),-.25*scene.SLOW_SPEED),"Mouse look slows with reaction window")
		scene.eyes.look_at(scene.test_car.driver.head.global_position)
		var shift := InputEventKey.new()
		shift.keycode=KEY_SHIFT
		shift.pressed=true
		scene._unhandled_input(shift)
		var aim := InputEventMouseButton.new()
		aim.button_index=MOUSE_BUTTON_RIGHT
		aim.pressed=true
		scene._unhandled_input(aim)
		await frames(50)
		check(scene.equipment.draw>=.95,"Shift/right-click draws player's gun within the real-time reaction window")
	else:
		# Headless has no captured mouse; verify the same regional aim ray.
		scene.set_physics_process(false)
		scene.equipment.state=scene.equipment.State.AIMING
		scene.equipment.draw=1
		scene.eyes.look_at(scene.test_car.driver.head.global_position)
		check(scene.combat.player_is_aiming(),"Aim ray finds actual NPC region")
		for i in range(20): scene.combat._physics_process(.016)
	check(scene.combat.phase==scene.combat.Phase.SURRENDERED and not scene.slowing and Engine.time_scale==1,"Timely aim causes surrender and ends slow motion")
	check(scene.combat.shots==0,"No premature shot during reaction window")
	if DisplayServer.get_name() != "headless":
		var motion := InputEventMouseMotion.new()
		motion.relative=Vector2(100,0)
		var yaw: float = scene.player.rotation.y
		scene._unhandled_input(motion)
		check(is_equal_approx(angle_difference(yaw,scene.player.rotation.y),-.25),"Normal mouse sensitivity returns after slow motion")

	check(scene.test_car.driver.surrendered and absf(scene.test_car.driver.limbs[3].rotation.z)>2,"Intimidated driver visibly raises hands")
	await capture("surrender")
	await fresh()
	await exit_driver()
	await frames(55)
	scene.set_process(false)
	scene.advance_reaction(2.1)
	scene.set_process(true)
	check(not scene.slowing and Engine.time_scale==1,"Reaction window is bounded in real time")
	await frames(150)
	check(scene.combat.phase==scene.combat.Phase.AIMING and scene.combat.shots>0,"Ignoring threat leads to drawn aimed weapon and shots")
	check(scene.health.value<100,"NPC hits damage player")
	# A wall between the muzzle and player must block the same firing ray.
	scene.combat.set_physics_process(false)
	var target: Vector3 = scene.player.global_position+Vector3(0,1.1,0)
	var muzzle: Vector3 = scene.combat.gun.to_global(Vector3(0,.023,-.16))
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(.35,3,3)
	shape.shape=box
	wall.add_child(shape)
	scene.add_child(wall)
	wall.global_position=(muzzle+target)/2
	await frames(2)
	check(scene.combat.shot_query(target).get("collider")==wall,"Cover blocks NPC shot ray")
	var before: float = scene.health.value
	scene.combat.fire()
	check(scene.health.value==before,"Cover prevents player damage")
	wall.queue_free()
	await frames(2)
	scene.health.receive_hit(100)
	check(scene.health.dead and scene.equipment.state==scene.equipment.State.HOLSTERED and not scene.equipment.hand.visible,"Lethal player damage stops and hides weapon actions")
	var shots: int = scene.combat.shots
	scene.combat.fire()
	check(scene.combat.shots==shots,"NPC stops firing after player death")
	await capture("death")
	# R reloads the entire scene, including dead player, driver and ammo.
	var reset := InputEventKey.new()
	reset.pressed=true
	reset.keycode=KEY_R
	scene._input(reset)
	await process_frame
	await process_frame
	scene=current_scene
	check(scene.health.value==100 and not scene.health.dead and scene.test_car.driver.state==scene.test_car.driver.State.SEATED,"R recreates healthy player and seated driver")
	check(scene.traffic.cars.size()==1 and scene.equipment.pistol_action.rounds()==15 and Engine.time_scale==1,"R resets world, ammunition and time scale")
	await exit_driver()
	await frames(55)
	var driver = scene.test_car.driver
	var point: Vector3 = driver.region_meshes.right_forearm.global_position
	scene.eyes.global_position=point+Vector3(-1.5,0,0)
	scene.eyes.look_at(point)
	scene.equipment.pistol_action.cast_shot()
	check(driver.is_injured() and scene.combat.phase==scene.combat.Phase.SURRENDERED,"Gun-arm hit invokes regional injury and surrender")
	check(is_instance_valid(scene.combat.dropped) and Engine.time_scale==1,"Gun drops physically and slow motion ends after disarming")
	await capture("disarmed")
	# Reset is global even while slow motion is active, not just after death.
	scene.begin_reaction_window()
	scene._input(reset)
	await process_frame
	await process_frame
	scene=current_scene
	check(Engine.time_scale==1 and not scene.slowing and scene.test_car.driver.state==scene.test_car.driver.State.SEATED,"R during slow motion restores the whole initial encounter")
	check(scene.combat.phase==scene.combat.Phase.SEATED and not is_instance_valid(scene.combat.dropped),"R clears dropped gun and combat progression")
	var back := InputEventKey.new()
	back.keycode=KEY_F10
	back.pressed=true
	scene.begin_reaction_window()
	scene._input(back)
	await process_frame
	await process_frame
	scene=current_scene
	check(scene.scene_file_path=="res://main.tscn" and Engine.time_scale==1,"F10 returns to main game and restores time")
	scene._unhandled_input(back)
	await process_frame
	await process_frame
	scene=current_scene
	check(scene.scene_file_path=="res://scenes/combat_test/combat_test.tscn" and scene.traffic.cars.size()==1,"Main-game F10 enters isolated test scenario")
	# Removal during slow motion must restore the previous global speed too.
	scene.begin_reaction_window()
	scene.queue_free()
	await process_frame
	check(Engine.time_scale==1,"Scene cleanup restores global time scale")
	OS.delay_msec(80)
	if failures.is_empty(): print("PASS: first-person start, exit, slow-motion reach, intimidation, NPC fire/player damage, cover, death, full R reset, regional disarm and time cleanup")
	quit(0 if failures.is_empty() else 1)
