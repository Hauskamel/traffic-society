extends SceneTree
const Trace = preload("res://game/weapons/projectile_trace.gd")
var failures: Array[String]=[]
var scene: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok:
		failures.append(text)
		push_error(text)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func cast_at(point: Vector3) -> void:
	scene.eyes.global_position=point+Vector3.LEFT*2
	scene.eyes.look_at(point)
	scene.equipment.pistol_action.cast_shot()
func run() -> void:
	scene=load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.position=Vector3(60,.08,60)
	var gun=scene.equipment.pistol_action
	for car in scene.traffic.cars:
		car.position=Vector3(7.1,.08,5)
		car.state=car.State.PARKED
		car.speed=0
		car.driver.reset()
		car.driver.corpse_exit_chance=0
		await frames(2)
		var glass: Node
		for zone in car.hit_surfaces.zones:
			if zone.kind=="glass" and zone.surface.get_parent()==car.driver_door: glass=zone
		cast_at(car.driver.torso.global_position)
		check(gun.last_glass_panes==1 and is_equal_approx(gun.last_retention,.8),"One intact pane transmits 80 percent impact")
		check(glass.damage_state==1 and car.driver.is_injured(),"Same first shot cracks glass and injures seated NPC")
		if car.driver.is_injured():
			check(is_equal_approx(car.driver.physical_actor.strength.torso,.24),"Glass reduces torso damage below direct 95 percent loss")
		car.driver.reset()
		await frames(2)
		cast_at(car.driver.head.global_position)
		check(glass.damage_state==2 and car.driver.is_dead(),"Cracked pane also transmits lethal headshot and breaks")
		car.driver.reset()
		await frames(2)
		cast_at(car.driver.head.global_position)
		check(gun.last_glass_panes==0 and gun.last_retention==1 and car.driver.is_dead(),"Broken pane imposes no further attenuation")
		car.driver.reset()
		await frames(2)
		car.position=Vector3(60,.08,60)
	# Two real shot-only glass surfaces in front of a world wall. No NPC/actor
	# path is required to verify layering, solid occlusion and once-per-pane hits.
	var car=scene.traffic.cars[0]
	var panes: Array[Node]=[]
	for zone in car.hit_surfaces.zones:
		if zone.kind=="glass" and zone.damage_state==0 and panes.size()<2:
			zone.surface.global_position=Vector3(20,1.5,-float(panes.size())*2)
			zone.surface.global_rotation=Vector3.ZERO
			panes.append(zone)
	var wall:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(3,3,.2)
	shape.shape=box
	wall.add_child(shape)
	scene.add_child(wall)
	wall.position=Vector3(20,1.5,-4)
	await frames(2)
	var ignored: Array[RID]=[]
	var result:=Trace.trace(scene.get_world_3d(),Vector3(20,1.5,2),Vector3(20,1.5,-8),1|16,ignored)
	check(result.panes==2 and is_equal_approx(result.retention,.64),"Attenuation accumulates per pane")
	check(result.hit.get("collider")==wall,"Solid wall still stops transmitted shot")
	check(panes[0].damage_state==1 and panes[1].damage_state==1,"Each pane receives exactly one glass hit per shot")
	for sound in scene.find_children("*","AudioStreamPlayer3D",true,false):
		sound.stop()
		sound.stream=null
	scene.queue_free()
	await process_frame
	OS.delay_msec(80)
	# NPC bullets use the same transmission rule for player damage.
	scene=load("res://prototypes/combat/combat_test.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.combat.set_physics_process(false)
	scene.combat.phase=scene.combat.Phase.AIMING
	scene.combat.gun.reparent(scene,false)
	scene.combat.gun.position=Vector3(20,1.1,2)
	scene.combat.gun.rotation=Vector3.ZERO
	scene.player.position=Vector3(20,0,-3)
	scene.combat.aim_target=Vector3(20,1.1,-3)
	for zone in scene.test_car.hit_surfaces.zones:
		if zone.kind=="glass" and zone.surface.get_parent()==scene.test_car and zone.surface.position.z<0:
			zone.surface.global_position=Vector3(20,1.1,0)
			zone.surface.global_rotation=Vector3.ZERO
			break
	await frames(2)
	scene.combat.fire()
	check(is_equal_approx(scene.health.value,80),"NPC shot through intact glass causes reduced 20 rather than 25 player damage")
	for sound in scene.find_children("*","AudioStreamPlayer3D",true,false):
		sound.stop()
		sound.stream=null
	scene.queue_free()
	await process_frame
	OS.delay_msec(80)
	if failures.is_empty(): print("PASS: four models, intact/cracked/broken glass, reduced body damage, lethal headshots, multiple panes and solid occlusion")
	quit(0 if failures.is_empty() else 1)
