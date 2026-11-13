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
func shoot_at(point: Vector3, direction := Vector3.RIGHT) -> void:
	scene.eyes.global_position = point-direction*1.5
	scene.eyes.look_at(point,Vector3.UP)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	scene.equipment.pistol_action.cooldown = 0
	if DisplayServer.get_name() == "headless":
		scene.equipment.pistol_action.cast_shot()
	else:
		check(scene.equipment.pistol_action.fire(), "Drawn Glock fires and consumes ammunition")
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("user://npc-physics-"+label+".png")
func run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.traffic.set_physics_process(false)
	scene.aerial = false
	scene.eyes.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	scene.equipment.selected = 0
	scene.equipment.state = scene.equipment.State.AIMING
	scene.equipment.draw = 1
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.position = Vector3(50, .08,50)
	var gun = scene.equipment.pistol_action
	for car in scene.traffic.cars:
		car.position = Vector3(7.1,.08,5)
		car.state = car.State.PARKED
		car.speed = 0
		var driver = car.driver
		driver.corpse_exit_chance = 0
		driver.request_exit()
		await frames(300)
		if car.model_kind == "pickup": driver.request_surrender()
		var point: Vector3 = driver.region_meshes.left_thigh.global_position
		var pose: Vector3 = driver.head.global_position
		var ammo: int = gun.rounds()
		shoot_at(point)
		if DisplayServer.get_name() != "headless": check(gun.rounds() == ammo-1, "NPC hit uses existing ammunition")
		check(not gun.last_hit.is_empty() and gun.last_hit.collider.get_meta("region","") == "left_thigh", "Regional ray selects thigh rather than interaction capsule")
		check(driver.is_injured() and not driver.rig.visible , "Hit transfers the visible model to articulated physics")
		if not driver.is_injured(): continue
		var actor = driver.physical_actor
		check(actor.bodies.head.global_position.distance_to(pose)<.001, "Physics starts at actual visible pose without teleport")
		check(actor.strength.left_thigh<.1 and actor.strength.right_thigh==1, "Local leg loss leaves opposite region healthy")
		await frames(90)
		check(not driver.can_drive() and not driver.request_enter() and not driver.request_exit() and not driver.begin_search(), "Injured driver cannot resume conflicting animations")
		check(actor.bodies.pelvis.global_position.is_finite(), "Injured driver stays finite")
		# Real second shot must hit the now dynamic regional collider.
		shoot_at(actor.bodies.head.global_position,Vector3.FORWARD)
		check(gun.last_hit.collider.get_meta("region","") == "head", "Follow-up hits dynamic head collider")
		check(actor.dead and actor.collapsed, "Head shot removes whole-body muscle control")
		await frames(240)
		check(actor.bodies.torso.global_position.y<.55, "NPC collapses onto actual street")
		if car.model_kind == "pickup":
			check(actor.bodies.left_forearm.global_position.y<.6 and actor.bodies.right_forearm.global_position.y<.6, "Surrendered arms fall instead of locking in raised pose")
		scene.eyes.global_position = actor.bodies.pelvis.global_position + Vector3(-2.5,2,3)
		scene.eyes.look_at(actor.bodies.pelvis.global_position)
		await capture(car.model_kind)
		check(not car.request_departure(), "Incapacitated driver cannot be released")
		driver.reset()
		await frames(2)
		check(not driver.is_injured() and driver.rig.visible, "Reset removes physical replacement and restores hit shapes")
		# A seated head shot, through a destroyed side window.
		var glass: Node
		for zone in car.hit_surfaces.zones:
			if zone.kind == "glass" and zone.surface.get_parent() == car.driver_door:
				glass = zone
		var head_at: Vector3 = driver.head.global_position
		var hit: Dictionary = gun.shot_query(head_at+Vector3.LEFT*2,head_at+Vector3.RIGHT*.05)
		check(not hit.is_empty() and not hit.collider.has_meta("actor"), "Raw visibility ray finds cabin surface before NPC")
		glass.register_hit(glass.global_position,Vector3.LEFT)
		glass.register_hit(glass.global_position,Vector3.LEFT)
		await frames(2)
		var road: Array[Vector3] = [car.position, car.position+Vector3(0,0,-30)]
		car.set_route(road)
		car.state = car.State.DRIVING
		car.speed = 6
		shoot_at(head_at)
		check(driver.is_injured(), "Broken window exposes seated regional hitbox")
		if driver.is_injured():
			check(driver.physical_actor.dead and not driver.physical_actor.posture_enabled, "Seated fatal hit slumps rather than standing up")
			check(is_instance_valid(driver.physical_actor.seat_support), "Cabin has physical seat support")
			check(driver.physical_actor.last_hit.velocity.length()>5, "Moving seated body inherits vehicle velocity")
			car.set_physics_process(true)
			await frames(360)
			car.set_physics_process(false)
			check(car.speed == 0 and car.state == car.State.PARKED, "Dead driver coasts to standstill instead of driving on or exiting")
			await frames(180)
			check(driver.physical_actor.bodies.pelvis.global_position.distance_to(car.to_global(driver.seat))<2, "Braking vehicle retains seated injured body near cabin")
			for body in driver.physical_actor.bodies.values():
				check(body.global_position.is_finite() and body.linear_velocity.length()<20, "Seated ragdoll stays bounded")
			scene.eyes.global_position = driver.physical_actor.bodies.pelvis.global_position + Vector3(-2.5,1,1)
			scene.eyes.look_at(driver.physical_actor.bodies.pelvis.global_position)
			await capture(car.model_kind+"-seated")
		car.position = Vector3(50,.08,50)
		# Reset also cleans the independent seat helper.
		driver.reset()
		await frames(2)
		check(not car.has_node("InjuredDriverSeat"), "Reset cleans seat support")
	var pickup_car = scene.traffic.cars[0]
	pickup_car.position = Vector3(7.1,.08,5)
	pickup_car.state = pickup_car.State.PARKED
	pickup_car.driver.request_exit()
	await frames(300)
	check(pickup_car.driver.set_arrested(true) and scene.patrol.request_pickup(pickup_car), "Uninjured arrested NPC can request pickup")
	shoot_at(pickup_car.driver.head.global_position)
	await frames(2)
	check(not scene.patrol.active() and not pickup_car.pickup_reserved, "Injury aborts pending pickup and releases reservation")
	for sound in scene.find_children("*", "AudioStreamPlayer3D", true, false):
		sound.stop()
		sound.stream = null
	scene.queue_free()
	await frames(2)
	await process_frame
	# Let the audio mixing thread release stopped WAV playbacks before exit.
	OS.delay_msec(80)
	if failures.is_empty(): print("PASS: real Glock shots, regional/dynamic hits, all vehicle models, visible pose transfer, street collapse, cabin occlusion, seated injuries, coasting, interaction guards and cleanup")
	quit(0 if failures.is_empty() else 1)
