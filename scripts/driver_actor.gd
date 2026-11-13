extends Node3D
## Procedural interaction poses; regional hits transfer to an articulated body.
enum State { SEATED, EXITING, OUTSIDE, ENTERING, SEARCHING, IN_CUSTODY, INJURED }
const ActiveBody = preload("res://scripts/active_body.gd")
enum CorpseExit { NONE, OPENING, FALLING, DONE }
var seated_physics := false
var corpse_exit_chance := .35
var corpse_exit_rolled := false
var corpse_exit_selected := false
var corpse_exit_stage: CorpseExit = CorpseExit.NONE
var corpse_exit_clock := 0.0
var seat_pelvis_local := Vector3.ZERO
var combat: Node
var physical_actor: Node3D
var region_meshes: Dictionary = {}
var shot_shapes: Array[StaticBody3D] = []
var last_world_position := Vector3.ZERO
var measured_velocity := Vector3.ZERO
const Timings = preload("res://scripts/interaction_timings.gd")
const DURATION := Timings.DRIVER_TRANSITION
const SEARCH_DURATION := Timings.PERSON_SEARCH
var arrested := false
var surrendered := false
var search_clock := 0.0
var search_ready := false
var state: State = State.SEATED
var progress := 0.0
var initial_door_angle := 0.0
var seat := Vector3.ZERO
var outside := Vector3.ZERO
var door: AnimatableBody3D
var rig: Node3D
var torso: MeshInstance3D
var head: MeshInstance3D
var limbs: Array[Node3D] = []
var body: StaticBody3D
var collider: CollisionShape3D
var handcuffs: MeshInstance3D

func block(at: Vector3, size: Vector3, color: String, parent: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = at
	return mesh

func _ready() -> void:
	add_to_group("shootable_drivers")
	rig = Node3D.new()
	add_child(rig)
	for region in ["pelvis", "torso", "head"]:
		var data: Array = ActiveBody.SPEC[region]
		region_meshes[region] = region_piece(region, data[0], data[1], "d7b49a" if region == "head" else ("354350" if region == "pelvis" else "b79b69"), rig)
	torso = region_meshes.torso
	head = region_meshes.head
	block(Vector3(0, .17, .02), Vector3(.28,.06,.26), "514638", head)
	for x in [-.07,.07]:
		block(Vector3(x,.03,-.135),Vector3(.035,.035,.015),"24323b",head)
	for side in ["left", "right"]:
		var leg := Node3D.new()
		rig.add_child(leg)
		leg.position = Vector3(-.14 if side == "left" else .14, 1.0, 0)
		region_meshes[side+"_thigh"] = region_piece(side+"_thigh",Vector3(0,-.20,0),ActiveBody.SPEC[side+"_thigh"][1],"354350",leg)
		var shin := region_piece(side+"_shin",Vector3(0,-.61,0),ActiveBody.SPEC[side+"_shin"][1],"354350",leg)
		region_meshes[side+"_shin"] = shin
		region_piece(side+"_shin",ActiveBody.FOOT_OFFSET,Vector3(.19,.15,.30),"24323b",shin)
		limbs.append(leg)
	for side in ["left", "right"]:
		var arm := Node3D.new()
		rig.add_child(arm)
		arm.position = Vector3(-.31 if side == "left" else .31,1.45,0)
		region_meshes[side+"_upper_arm"] = region_piece(side+"_upper_arm",Vector3(0,-.18,0),ActiveBody.SPEC[side+"_upper_arm"][1],"b79b69",arm)
		var forearm := region_piece(side+"_forearm",Vector3(0,-.51,0),ActiveBody.SPEC[side+"_forearm"][1],"b79b69",arm)
		region_meshes[side+"_forearm"] = forearm
		region_piece(side+"_forearm",ActiveBody.HAND_OFFSET,Vector3(.14,.12,.17),"d7b49a",forearm)
		limbs.append(arm)
	handcuffs = block(Vector3(0, 0.86, 0.3), Vector3(0.36, 0.045, 0.05), "a8b2ae", rig)
	handcuffs.visible = false
	body = StaticBody3D.new()
	body.collision_layer = 4
	body.collision_mask = 0
	add_child(body)
	collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	body.add_child(collider)
	reset()

func region_piece(region: String, at: Vector3, size: Vector3, color: String, parent: Node3D) -> MeshInstance3D:
	var mesh := block(at, size, color, parent)
	var target := StaticBody3D.new()
	target.collision_layer = 32
	target.collision_mask = 0
	target.set_meta("actor", self)
	target.set_meta("region", region)
	mesh.add_child(target)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	target.add_child(shape)
	shot_shapes.append(target)
	return mesh

func is_injured() -> bool:
	return is_instance_valid(physical_actor)

func is_dead() -> bool:
	return is_injured() and physical_actor.dead

func is_corpse_exiting() -> bool:
	return corpse_exit_stage in [CorpseExit.OPENING, CorpseExit.FALLING]

func receive_hit(region: String, point: Vector3, impulse: Vector3, severity := ActiveBody.DEFAULT_STRENGTH_LOSS) -> void:
	if not region_meshes.has(region): return
	if not is_injured():
		var in_vehicle := state in [State.SEATED, State.IN_CUSTODY] or (state in [State.ENTERING, State.EXITING] and rig.scale.x < .9)
		seated_physics = in_vehicle
		var velocity := measured_velocity
		var car := get_parent()
		if in_vehicle and car is AnimatableBody3D:
			velocity = -car.global_basis.z * car.speed
		var scale_factor := rig.global_basis.get_scale().x
		physical_actor = ActiveBody.new()
		physical_actor.model_scale = scale_factor
		physical_actor.top_level = true
		physical_actor.transform = Transform3D(global_basis.orthonormalized(), global_position)
		add_child(physical_actor)
		physical_actor.heading = global_rotation.y
		physical_actor.posture_enabled = not in_vehicle
		for key in physical_actor.bodies:
			var segment: RigidBody3D = physical_actor.bodies[key]
			var pose: Transform3D = region_meshes[key].global_transform
			segment.global_transform = Transform3D(pose.basis.orthonormalized(), pose.origin)
			segment.linear_velocity = velocity
			segment.set_meta("actor", self)
			# Keep clothing, hair and face details when switching renderers.
			segment.get_child(1).material_override = region_meshes[key].material_override.duplicate()
		for detail in head.get_children():
			if detail is MeshInstance3D:
				var copy := detail.duplicate()
				physical_actor.bodies.head.add_child(copy)
				copy.position *= scale_factor
				copy.scale *= scale_factor
		# Interaction vehicle colliders are coarse; exclude those overlapping the
		# cabin. A dedicated seat/floor supports a seated injured body instead.
		if car is AnimatableBody3D:
			for obstacle in car.find_children("*", "CollisionObject3D", true, false):
				if obstacle is PhysicsBody3D and not physical_actor.is_ancestor_of(obstacle):
					for segment in physical_actor.bodies.values(): segment.add_collision_exception_with(obstacle)
			if in_vehicle:
				build_seat_support(car, scale_factor)
		# Keep anatomical neutral joint frames from construction, even when the
		# captured pose has raised arms or bent seated legs.
		for target in shot_shapes: target.collision_layer = 0
		collider.set_deferred("disabled", true)
		rig.hide()
		surrendered = false
		search_ready = false
		state = State.INJURED
	physical_actor.receive_hit(region, point, impulse, severity)
	if is_dead() and seated_physics and not corpse_exit_rolled and get_parent() is AnimatableBody3D and get_parent().get("driver") == self:
		corpse_exit_rolled = true
		var chance := clampf(corpse_exit_chance,0,1)
		corpse_exit_selected = chance >= 1 or (chance > 0 and randf() < chance)
	if is_instance_valid(combat): combat.on_body_hit(region)

func build_seat_support(car: Node3D, factor: float) -> void:
	var support := AnimatableBody3D.new()
	support.sync_to_physics = false
	support.name = "InjuredDriverSeat"
	support.collision_layer = 64
	support.collision_mask = 0
	car.add_child(support)
	support.global_transform = Transform3D(global_basis.orthonormalized(),global_position)
	for data in [[Vector3(0,.89,.02),Vector3(.50,.10,.42)], [Vector3(0,1.13,.22),Vector3(.50,.50,.08)], [Vector3(0,.20,-.30),Vector3(.60,.08,.95)]]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = data[1] * factor
		shape.shape = box
		shape.position = data[0] * factor
		support.add_child(shape)
	physical_actor.seat_support = support
	seat_pelvis_local = support.to_local(physical_actor.bodies.pelvis.global_position)

func update_seated_physics(delta: float) -> void:
	if not seated_physics: return
	var car := get_parent()
	if not car is AnimatableBody3D: return
	var pelvis: RigidBody3D = physical_actor.bodies.pelvis
	var seat_support: Node3D = physical_actor.seat_support
	if corpse_exit_stage in [CorpseExit.NONE, CorpseExit.OPENING] and is_instance_valid(seat_support):
		# Soft seat restraint carries the passive articulated body with a moving
		# cabin. The torso and limbs remain free to slump and react to impulses.
		var target: Vector3 = seat_support.to_global(seat_pelvis_local)
		var velocity: Vector3 = -car.global_basis.z*car.speed
		var force: Vector3 = ((target-pelvis.global_position)*45-(pelvis.linear_velocity-velocity)*7)*physical_actor.total_mass
		pelvis.apply_central_force(force.limit_length(physical_actor.total_mass*45))
	if not is_dead() or not corpse_exit_selected: return
	if car.speed > .05 or car.state != car.State.PARKED: return
	if corpse_exit_stage == CorpseExit.NONE:
		corpse_exit_stage = CorpseExit.OPENING
		for part in car.parts:
			if part.kind == "driver_door": part.opened = true
	if corpse_exit_stage == CorpseExit.OPENING:
		if absf(door.rotation.y) < 1.0: return
		corpse_exit_stage = CorpseExit.FALLING
		corpse_exit_clock = 0
		if is_instance_valid(seat_support): seat_support.queue_free()
		physical_actor.seat_support = null
	if corpse_exit_stage == CorpseExit.FALLING:
		corpse_exit_clock += delta
		var left: Vector3 = -car.global_basis.x
		var goal: Vector3 = car.to_global(Vector3(-1.8,0,seat.z))
		var gap: float = (goal-pelvis.global_position).dot(left)
		# Short outward assistance clears simplified cabin geometry; gravity and
		# articulated joints produce the fall, without teleport or exit animation.
		var acceleration := clampf(gap*16-pelvis.linear_velocity.dot(left)*5,-5,8)
		for region in ["pelvis","torso"]:
			var segment: RigidBody3D = physical_actor.bodies[region]
			segment.apply_central_force(left*acceleration*segment.mass*2)
		if corpse_exit_clock >= 2.0:
			corpse_exit_stage = CorpseExit.DONE

func reset() -> void:
	seated_physics = false
	corpse_exit_rolled = false
	corpse_exit_selected = false
	corpse_exit_stage = CorpseExit.NONE
	corpse_exit_clock = 0
	if is_injured():
		physical_actor.queue_free()
		physical_actor = null
	rig.show()
	for target in shot_shapes: target.collision_layer = 32
	surrendered = false
	arrested = false
	handcuffs.visible = false
	search_clock = 0
	search_ready = false
	for limb in limbs:
		limb.rotation.z = 0
	torso.rotation.x = 0
	state = State.SEATED
	door.collision_layer = 4
	progress = 0
	collider.disabled = true
	apply_pose(0)

func request_exit() -> bool:
	if state != State.SEATED:
		return false
	# Animations intentionally pass through obstacles for responsive interaction.
	initial_door_angle = door.rotation.y
	door.collision_layer = 0
	state = State.EXITING
	progress = 0
	return true

func request_enter() -> bool:
	if state != State.OUTSIDE or arrested or surrendered:
		return false
	collider.disabled = true
	initial_door_angle = door.rotation.y
	door.collision_layer = 0
	state = State.ENTERING
	progress = 0
	return true

func is_busy() -> bool:
	return state == State.EXITING or state == State.ENTERING or state == State.SEARCHING

func can_drive() -> bool:
	return not is_injured() and not surrendered and not arrested and state == State.SEATED and absf(door.rotation.y) < 0.01

func interaction_point() -> Vector3:
	return global_position + Vector3(0, 1.35, 0)

func apply_pose(t: float) -> void:
	var door_open := minf(clampf(t / 0.22, 0, 1), clampf((1.0 - t) / 0.18, 0, 1))
	door.rotation.y = -1.15 * smoothstep(0.0, 1.0, door_open)
	if state == State.EXITING and t < 0.22:
		door.rotation.y = lerpf(initial_door_angle, -1.15, smoothstep(0.0, 0.22, t))
	elif state == State.ENTERING and t > 0.82:
		door.rotation.y = lerpf(initial_door_angle, -1.15, smoothstep(0.0, 0.18, 1.0 - t))
	var movement := smoothstep(0.0, 1.0, clampf((t - 0.24) / 0.55, 0, 1))
	var destination := outside
	var car := get_parent()
	if car is AnimatableBody3D and car.get("hit_surfaces") != null and car.hit_surfaces.flat_tires > 0:
		var grounded: Vector3 = car.to_global(outside)
		grounded.y = 0
		destination = car.to_local(grounded)
	position = seat.lerp(destination, movement)
	rotation.y = lerpf(0, PI / 2.0, movement)
	rig.scale = Vector3.ONE * lerpf(0.78, 1.0, movement)
	for i in range(limbs.size()):
		var seated_angle := 0.95 if i < 2 else 0.55
		var sway := sin(movement * TAU * 2) * 0.2 * sin(movement * PI)
		limbs[i].rotation.x = lerpf(seated_angle, 0, movement) + sway * (1 if i % 2 == 0 else -1)
	body.global_position = global_position
	if surrendered and not arrested:
		raise_hands()

func begin_search() -> bool:
	if state != State.OUTSIDE:
		return false
	state = State.SEARCHING
	search_clock = 0.0
	search_ready = false
	return true

func end_search() -> void:
	if state != State.SEARCHING:
		return
	state = State.OUTSIDE
	search_ready = false
	limbs[2].rotation.z = 0
	limbs[3].rotation.z = 0
	torso.rotation.x = 0

func _physics_process(delta: float) -> void:
	measured_velocity = (global_position - last_world_position) / maxf(delta, .0001)
	last_world_position = global_position
	if is_injured():
		update_seated_physics(delta)
		return
	var car := get_parent()
	if state == State.OUTSIDE and car is AnimatableBody3D and car.get("hit_surfaces") != null and car.hit_surfaces.flat_tires > 0:
		global_position.y = 0
	if surrendered and not arrested and state != State.SEARCHING:
		raise_hands()
	if arrested and state in [State.OUTSIDE, State.IN_CUSTODY]:
		limbs[2].rotation.x = -0.7
		limbs[3].rotation.x = -0.7
		limbs[2].rotation.z = 0.3
		limbs[3].rotation.z = -0.3
	if state == State.SEARCHING:
		search_clock = minf(SEARCH_DURATION, search_clock + delta)
		var amount := smoothstep(0.0, 0.5, search_clock)
		limbs[2].rotation.z = -1.2 * amount
		limbs[3].rotation.z = 1.2 * amount
		torso.rotation.x = sin(search_clock * 7.0) * 0.035 if search_clock < SEARCH_DURATION else 0.0
		search_ready = search_clock >= SEARCH_DURATION
		return
	if not is_busy():
		return
	progress = minf(1.0, progress + delta / DURATION)
	apply_pose(progress if state == State.EXITING else 1.0 - progress)
	if progress >= 1.0:
		state = State.OUTSIDE if state == State.EXITING else State.SEATED
		collider.disabled = state != State.OUTSIDE
		door.collision_layer = 4


func set_arrested(value: bool) -> bool:
	if state != State.OUTSIDE:
		return false
	arrested = value
	surrendered = false
	handcuffs.visible = value
	for i in [2, 3]:
		limbs[i].rotation.x = 0
		limbs[i].rotation.z = 0
	return true

func raise_hands() -> void:
	for i in [2, 3]:
		limbs[i].rotation.x = -0.15
		limbs[i].rotation.z = -2.65 if i == 2 else 2.65

func request_surrender() -> bool:
	if is_injured() or arrested or state in [State.SEARCHING, State.IN_CUSTODY]:
		return false
	surrendered = true
	if state == State.ENTERING:
		state = State.EXITING
		progress = 1.0 - progress
	raise_hands()
	return true
