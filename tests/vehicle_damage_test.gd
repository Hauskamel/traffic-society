extends SceneTree
var failures: Array[String] = []
var scene: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		car.hit_surfaces.set_physics_process(false)
		car.position = Vector3(50, 0.08, 50)
	var gun = scene.equipment.pistol_action
	for car in scene.traffic.cars:
		car.position = Vector3(7.1, 0.08, 5)
		var glass: Node
		var tires: Array[Node] = []
		var rim: Node
		for zone in car.hit_surfaces.zones:
			if zone.kind == "glass" and zone.surface.get_parent() == car.driver_door:
				glass = zone
			elif zone.kind == "tire":
				tires.append(zone)
			elif zone.kind == "wheel":
				rim = zone
		await physics_frame
		await physics_frame
		var at: Vector3 = glass.surface.global_position
		var hit: Dictionary = gun.shot_query(at + Vector3.LEFT * 3, at + Vector3.RIGHT * 0.1)
		check(not hit.is_empty() and hit.collider == glass, "Intact side glass blocks shot")
		glass.register_hit(at + Vector3.LEFT * 0.018, Vector3.LEFT)
		check(glass.damage_state == 1 and glass.surface.visible and glass.collision_layer == 16, "First hit cracks but retains window")
		check(glass.surface.get_child_count() >= 3, "Crack overlays are visible on both window faces")
		glass.register_hit(at + Vector3.LEFT * 0.018, Vector3.LEFT)
		check(glass.damage_state == 2 and not glass.surface.visible and glass.collision_layer == 0, "Second hit destroys glass and disables shot blocker")
		await physics_frame
		hit = gun.shot_query(at + Vector3.LEFT * 3, at + Vector3.RIGHT * 0.1)
		check(hit.is_empty() or hit.collider != glass, "Further shots pass through broken window opening")
		check(not car.driver.arrested and not car.driver.surrendered, "Damage does not injure or arrest NPC")
		rim.register_hit(rim.surface.global_position, Vector3.LEFT)
		check(car.hit_surfaces.flat_tires == 0, "Rim hits do not puncture tires")
		var speed: float = car.speed
		for i in range(4):
			var tire = tires[i]
			tire.register_hit(tire.surface.global_position + Vector3.LEFT * 0.11, Vector3.LEFT)
			check(car.hit_surfaces.flat_tires == i + 1 and not tire.surface.visible and tire.collision_layer == 0, "Each original tire punctures independently")
			tire.register_hit(tire.surface.global_position, Vector3.LEFT)
			check(car.hit_surfaces.flat_tires == i + 1, "Repeated hits do not count another tire")
			check(car.hit_surfaces.speed_cap() > 0, "Damaged vehicle can still clear control space")
		check(car.position.y < 0.08, "Vehicle settles lower on damaged tires")
		car._physics_process(0.1)
		check(car.speed < speed and car.speed > car.hit_surfaces.speed_cap(), "Speed decreases smoothly rather than instant stop")
		for i in range(600):
			car._physics_process(1.0 / 60.0)
			car.hit_surfaces.apply_stance()
		check(car.speed <= car.hit_surfaces.speed_cap() + 0.01, "Four damaged tires enforce low speed")
		check(car.request_surrender(), "Damaged vehicle still supports surrender")
		for i in range(400):
			car._physics_process(1.0 / 60.0)
			car.hit_surfaces.apply_stance()
			car.driver._physics_process(1.0 / 60.0)
		check(absf(car.driver.global_position.y) < 0.03, "Outside driver remains grounded beside lowered car")
		check(car.driver.state == car.driver.State.OUTSIDE and car.state == car.State.PARKED, "Driver stops and exits with damaged tires")
		car.driver.set_arrested(true)
		car.driver.set_arrested(false)
		check(car.request_departure(), "Released driver can enter and depart damaged vehicle")
		for i in range(300):
			car.driver._physics_process(1.0 / 60.0)
			car._physics_process(1.0 / 60.0)
		check(car.state == car.State.LEAVING and car.speed > 0, "Departure progresses despite four flat tires")
		car.state = car.State.PARKED
		car.position = Vector3(50, 0.08, 50)
		if is_instance_valid(car.hit_surfaces.damage_sound):
			car.hit_surfaces.damage_sound.stop()
	if DisplayServer.get_name() != "headless":
		var car = scene.traffic.cars[0]
		car.position = Vector3(7.1, 0.08, 5)
		car.hit_surfaces.apply_stance()
		scene.aerial = false
		scene.update_camera()
		scene.player.position = Vector3(3.6, 0.1, 6.7)
		scene.eyes.look_at(car.global_position + Vector3(0, 0.6, 0))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://vehicle-damage.png")
	var car = scene.traffic.cars[0]
	car.position = Vector3(7.1, 0.08, 5)
	var windshield: Node
	for zone in car.hit_surfaces.zones:
		if zone.kind == "glass" and zone.surface.get_parent() == car and zone.surface.position.z < 0 and zone.damage_state == 0:
			windshield = zone
	scene.aerial = false
	scene.update_camera()
	scene.player.position = windshield.surface.global_position + Vector3(0, 0, -3)
	scene.player.position.y = 0.1
	scene.eyes.look_at(windshield.surface.global_position)
	scene.equipment.state = scene.equipment.State.AIMING
	scene.equipment.draw = 1
	await physics_frame
	await physics_frame
	check(gun.fire() and windshield.damage_state == 1, "Real first pistol shot cracks windshield")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://glass-cracked.png")
	gun.tick(0.2)
	check(gun.fire() and windshield.damage_state == 2, "Real second pistol shot destroys windshield")
	gun.sound.stop()
	gun.click.stop()
	if is_instance_valid(car.hit_surfaces.damage_sound):
		car.hit_surfaces.damage_sound.stop()
	await create_timer(1.2).timeout
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: four models, crack/break/through-shot, independent tires, rim exclusion, repeat guard, smooth slowdown, surrender, exit and damaged departure")
	quit(0 if failures.is_empty() else 1)
