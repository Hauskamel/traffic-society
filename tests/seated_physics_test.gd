extends SceneTree
var scene: Node
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures.append(text)
		push_error(text)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("user://seated-"+label+".png")
func run() -> void:
	scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.traffic.set_physics_process(false)
	for other in scene.traffic.cars:
		other.set_physics_process(false)
		other.position=Vector3(60,.08,60)
	for car in scene.traffic.cars:
		for eject in [false,true]:
			car.new_test_drive()
			car.position=Vector3(7.1,.08,25)
			car.rotation=Vector3.ZERO
			var road: Array[Vector3]=[car.position,car.position+Vector3(0,0,-60)]
			car.set_route(road)
			car.driver.reset()
			car.driver.corpse_exit_chance=1.0 if eject else 0.0
			car.set_physics_process(true)
			await frames(2)
			var driver=car.driver
			driver.receive_hit("left_forearm",driver.region_meshes.left_forearm.global_position,Vector3(0,0,-3))
			check(not driver.is_dead() and driver.seated_physics,"Nonfatal seated hit has articulated physics and remains alive")
			var speed: float=car.speed
			var initial: Vector3=car.position
			await frames(180)
			check(car.speed>=speed-.01 and car.state==car.State.DRIVING and car.position.distance_to(initial)>15,"Injured living driver continues normal traffic speed")
			check(driver.physical_actor.bodies.pelvis.global_position.distance_to(car.to_global(driver.seat))<1.4,"Passive seated body follows moving cabin")
			check(driver.corpse_exit_stage==driver.CorpseExit.NONE and not driver.corpse_exit_rolled,"No death decision or exit on nonfatal injury")
			if not eject:
				var short_route: Array[Vector3]=[car.position,car.position+Vector3(0,0,-.2)]
				car.set_route(short_route)
			var head: RigidBody3D=driver.physical_actor.bodies.head
			driver.receive_hit("head",head.global_position,Vector3(0,0,-3))
			check(driver.is_dead() and driver.corpse_exit_selected==eject,"Death samples configured corpse exit once")
			# A subsequent hit must not re-roll the selected outcome.
			driver.corpse_exit_chance=0.0 if eject else 1.0
			driver.receive_hit("head",head.global_position,Vector3.ZERO)
			check(driver.corpse_exit_selected==eject,"Further hits do not resample corpse exit")
			var at_death: Vector3=car.position
			var start_speed: float=car.speed
			await frames(30)
			check(car.speed>0 and car.speed<start_speed and car.position.distance_to(at_death)>1,"Dead driver coasts forward without immediate stop")
			check(absf(car.driver_door.rotation.y)<.01,"Door stays closed while coasting")
			var previous: float=car.speed
			for i in range(360):
				await physics_frame
				check(car.speed<=previous+.001,"Dead vehicle slows monotonically")
				previous=car.speed
			check(car.state==car.State.PARKED and car.speed==0,"Dead vehicle comes to rest")
			var coast_distance: float=car.position.distance_to(at_death)
			check(coast_distance>10 and coast_distance<18,"Coast distance matches gentle deceleration")
			await frames(240)
			var pelvis: RigidBody3D=driver.physical_actor.bodies.pelvis
			if eject:
				check(driver.corpse_exit_stage==driver.CorpseExit.DONE and absf(car.driver_door.rotation.y)>1,"Selected corpse exits through an open door after stopping")
				check(car.to_local(pelvis.global_position).x < -1.1 and pelvis.global_position.y<.5,"Corpse falls outside cabin onto ground")
				check(not is_instance_valid(driver.physical_actor.seat_support),"Fall releases seat restraint")
			else:
				check(driver.corpse_exit_stage==driver.CorpseExit.NONE and absf(car.driver_door.rotation.y)<.01,"Unselected corpse stays seated with closed door")
				check(pelvis.global_position.distance_to(car.to_global(driver.seat))<1.4,"Unselected corpse remains in cabin")
			for segment in driver.physical_actor.bodies.values():
				check(segment.global_position.is_finite() and segment.linear_velocity.length()<15,"Corpse physics remains bounded")
			scene.eyes.make_current()
			scene.eyes.global_position=car.global_position+Vector3(-4,2.8,3)
			scene.eyes.look_at(car.global_position+Vector3(-.8,.5,0))
			await capture(car.model_kind+("-outside" if eject else "-inside"))
			car.set_physics_process(false)
			car.new_test_drive()
			await frames(2)
			check(not driver.is_injured() and not driver.corpse_exit_rolled and not car.death_coasting and car.all_parts_closed(),"Reset clears corpse, door and coasting state")
			car.position=Vector3(60,.08,60)
	scene.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: all models, living injured traffic, seated restraint, smooth death coasting, probabilistic exit branches, open door, physical ground fall and reset")
	quit(0 if failures.is_empty() else 1)
