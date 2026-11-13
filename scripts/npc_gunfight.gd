extends Node
## Authored test encounter. Mood/dialogue selection can opt into this later.
enum Phase { SEATED, WAITING, REACHING, DRAWING, AIMING, SURRENDERED, DISABLED }
const ProjectileTrace = preload("res://scripts/projectile_trace.gd")
const Models = preload("res://scripts/weapon_visuals.gd")
const REACH_SECONDS := .65
const DRAW_SECONDS := .70
const SHOT_INTERVAL := .9
var scene: Node3D
var driver: Node3D
var phase: Phase = Phase.SEATED
var clock := 0.0
var aim_clock := 0.0
var fire_clock := .45
var shots := 0
var aim_target := Vector3.ZERO
var gun: Node3D
var dropped: RigidBody3D
var sound: AudioStreamPlayer3D
var flash: MeshInstance3D
var flash_clock := 0.0
var report := "Fahrer sitzt im Auto."
func _ready() -> void:
	gun = Models.build(driver.rig,"pistol")
	gun.position = Vector3(.27,.93,.08)
	gun.rotation.x = -PI/2
	sound = AudioStreamPlayer3D.new()
	sound.stream = preload("res://assets/audio/pistol.wav")
	sound.volume_db = -13
	driver.add_child(sound)
	flash = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = .025
	ball.height = .06
	flash.mesh = ball
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffe8a0")
	flash.material_override = mat
	gun.add_child(flash)
	flash.position = Vector3(0,.023,-.15)
	flash.hide()
func enter(next: Phase) -> void:
	phase = next
	clock = 0
	if next == Phase.REACHING:
		report = "Er greift zur Waffe!"
		scene.begin_reaction_window()
	elif next == Phase.DRAWING:
		gun.reparent(driver.region_meshes.right_forearm,false)
		gun.position = Vector3(0,-.21,0)
		report = "Er zieht die Pistole!"
	elif next == Phase.AIMING:
		aim_target = scene.player.global_position+Vector3(0,1.1,0)
		report = "In Deckung!"
func pose_arm(index: int, upper: float, side: float, elbow: float) -> void:
	driver.limbs[index].rotation = Vector3(upper,0,side)
	var forearm: MeshInstance3D = driver.region_meshes["right_forearm" if index == 3 else "left_forearm"]
	forearm.rotation.x = elbow
	forearm.position = Vector3(0,-.35,0)+Basis(Vector3.RIGHT,elbow)*Vector3(0,-.16,0)
func player_is_aiming() -> bool:
	var gear = scene.equipment
	if scene.health.dead or gear.selected != 0 or gear.state != gear.State.AIMING or gear.draw < .95 or gear.pistol_action.reloading: return false
	var origin: Vector3 = scene.eyes.global_position
	var hit: Dictionary = gear.pistol_action.shot_query(origin,origin-scene.eyes.global_basis.z*25)
	return not hit.is_empty() and hit.collider.has_meta("actor") and hit.collider.get_meta("actor") == driver
func surrender() -> void:
	if phase in [Phase.SURRENDERED,Phase.DISABLED]: return
	phase = Phase.SURRENDERED
	driver.surrendered = true
	# Restore the elbow geometry before the ordinary hands-up pose.
	if not driver.is_injured():
		for i in [2,3]: pose_arm(i,0,0,0)
		driver.raise_hands()
		if gun.get_parent() != driver.rig: drop_gun()
	report = "Er gibt auf. Naehern und [E] Handschellen anlegen."
	scene.end_reaction_window()
func on_body_hit(region: String) -> void:
	drop_gun()
	if region.contains("arm") and not driver.physical_actor.collapsed:
		phase = Phase.SURRENDERED
		driver.surrendered = true
		report = "Entwaffnet. Er gibt auf. [E] Handschellen anlegen."
	else:
		phase = Phase.DISABLED
		report = "Angriff beendet: NPC getroffen."
	scene.end_reaction_window()
func drop_gun() -> void:
	if is_instance_valid(dropped): return
	var at := gun.global_transform
	dropped = RigidBody3D.new()
	dropped.mass = .7
	dropped.collision_layer = 0
	dropped.collision_mask = 1 | 2
	scene.add_child(dropped)
	dropped.global_transform = at
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.045,.13,.22)
	collider.shape = box
	dropped.add_child(collider)
	gun.reparent(dropped,true)
	flash.hide()
func ignore_bodies(node: Node, ignored: Array[RID]) -> void:
	if node is CollisionObject3D: ignored.append(node.get_rid())
	for child in node.get_children(): ignore_bodies(child,ignored)
func shot_query(target: Vector3) -> Dictionary:
	var ignored: Array[RID] = []
	ignore_bodies(driver,ignored)
	var origin := gun.to_global(Vector3(0,.023,-.16))
	var query := PhysicsRayQueryParameters3D.create(origin,origin+(target-origin).normalized()*60,1|4|16|32,ignored)
	return scene.get_world_3d().direct_space_state.intersect_ray(query)
func fire() -> void:
	if phase != Phase.AIMING or scene.health.dead or driver.is_injured(): return
	shots += 1
	# Small deterministic variation makes the test reproducible, not perfectly
	# accurate. Obstacles still decide whether the shot reaches the player.
	var target: Vector3 = aim_target+Vector3(.10*sin(shots*2.1),.08*cos(shots*1.7),0)
	var ignored: Array[RID] = []
	ignore_bodies(driver,ignored)
	var origin := gun.to_global(Vector3(0,.023,-.16))
	var trajectory := ProjectileTrace.trace(scene.get_world_3d(),origin,origin+(target-origin).normalized()*60,1|4|16|32,ignored)
	var hit: Dictionary = trajectory.hit
	if not hit.is_empty():
		if hit.collider == scene.player: scene.health.receive_hit(25*float(trajectory.retention),hit.position)
		elif hit.collider.has_method("register_hit"): hit.collider.register_hit(hit.position,hit.normal)
	var end: Vector3 = hit.position if not hit.is_empty() else target
	var line := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("e8d4a1")
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,mat)
	mesh.surface_add_vertex(gun.to_global(Vector3(0,.023,-.16)))
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	line.mesh = mesh
	scene.add_child(line)
	var life := line.create_tween()
	life.tween_interval(.06)
	life.tween_callback(line.queue_free)
	sound.play()
	flash_clock = .06
	flash.show()
func _physics_process(delta: float) -> void:
	flash_clock = maxf(0,flash_clock-delta)
	flash.visible = flash_clock > 0 and phase == Phase.AIMING
	if phase in [Phase.SURRENDERED,Phase.DISABLED] or scene.health.dead: return
	if driver.is_injured(): return
	if phase == Phase.SEATED:
		if driver.state == driver.State.OUTSIDE: enter(Phase.WAITING)
		return
	clock += delta
	if phase in [Phase.REACHING,Phase.DRAWING]:
		aim_clock = aim_clock+delta/maxf(Engine.time_scale,.001) if player_is_aiming() else 0
		if aim_clock >= .22:
			surrender()
			return
	var target: Vector3 = scene.player.global_position+Vector3(0,1.1,0)
	var offset: Vector3 = target-driver.global_position
	driver.rotation.y = atan2(-offset.x,-offset.z)-driver.get_parent().global_rotation.y
	match phase:
		Phase.WAITING:
			if clock >= .8: enter(Phase.REACHING)
		Phase.REACHING:
			var t := smoothstep(0,REACH_SECONDS,clock)
			pose_arm(3,-.1*t,-.4*t,-.9*t)
			if clock >= REACH_SECONDS: enter(Phase.DRAWING)
		Phase.DRAWING:
			var t := smoothstep(0,DRAW_SECONDS,clock)
			pose_arm(3,lerpf(-.1,-1.35,t),lerpf(-.4,0,t),lerpf(-.9,.1,t))
			gun.look_at(target)
			if clock >= DRAW_SECONDS: enter(Phase.AIMING)
		Phase.AIMING:
			aim_target = aim_target.move_toward(target,delta*2.5)
			pose_arm(3,-1.35,0,.1)
			gun.look_at(aim_target)
			fire_clock -= delta
			if fire_clock <= 0:
				fire_clock = SHOT_INTERVAL
				fire()
