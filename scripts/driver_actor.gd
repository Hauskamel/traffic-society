extends Node3D
## Procedural placeholder animation, replaceable by a rigged GLB later.
enum State { SEATED, EXITING, OUTSIDE, ENTERING, SEARCHING, IN_CUSTODY }
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
	rig = Node3D.new()
	add_child(rig)
	torso = block(Vector3(0, 1.13, 0), Vector3(0.45, 0.57, 0.28), "b79b69", rig)
	head = block(Vector3(0, 1.59, 0), Vector3(0.29, 0.32, 0.28), "d7b49a", rig)
	block(Vector3(0, 1.77, 0.02), Vector3(0.3, 0.08, 0.26), "514638", rig)
	for x in [-0.07, 0.07]:
		block(Vector3(x, 1.63, -0.145), Vector3(0.035, 0.035, 0.015), "24323b", rig)
	for x in [-0.13, 0.13]:
		var leg := Node3D.new()
		rig.add_child(leg)
		leg.position = Vector3(x, 0.85, 0)
		block(Vector3(0, -0.4, 0), Vector3(0.17, 0.8, 0.2), "354350", leg)
		block(Vector3(0, -0.8, -0.06), Vector3(0.19, 0.12, 0.32), "24323b", leg)
		limbs.append(leg)
	for x in [-0.31, 0.31]:
		var arm := Node3D.new()
		rig.add_child(arm)
		arm.position = Vector3(x, 1.34, 0)
		block(Vector3(0, -0.27, 0), Vector3(0.15, 0.53, 0.18), "b79b69", arm)
		block(Vector3(0, -0.55, 0), Vector3(0.14, 0.15, 0.15), "d7b49a", arm)
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

func reset() -> void:
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
	return not surrendered and not arrested and state == State.SEATED and absf(door.rotation.y) < 0.01

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
	position = seat.lerp(outside, movement)
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
	if arrested or state in [State.SEARCHING, State.IN_CUSTODY]:
		return false
	surrendered = true
	if state == State.ENTERING:
		state = State.EXITING
		progress = 1.0 - progress
	raise_hands()
	return true
