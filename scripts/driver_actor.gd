extends Node3D
## Procedural placeholder animation, replaceable by a rigged GLB later.
enum State { SEATED, EXITING, OUTSIDE, ENTERING }
const DURATION := 2.4
var state: State = State.SEATED
var progress := 0.0
var seat := Vector3.ZERO
var outside := Vector3.ZERO
var door: AnimatableBody3D
var rig: Node3D
var torso: MeshInstance3D
var head: MeshInstance3D
var limbs: Array[Node3D] = []
var body: StaticBody3D
var collider: CollisionShape3D
var message := ""

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
	state = State.SEATED
	progress = 0
	collider.disabled = true
	apply_pose(0)

func space_clear() -> bool:
	# Covers the door sweep and the entire short path beside the vehicle.
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.85, 1.95, 2.2)
	query.shape = shape
	query.transform = get_parent().global_transform * Transform3D(Basis.IDENTITY, Vector3(-1.93, 1.1, outside.z))
	query.collision_mask = 7
	query.exclude = [get_parent().get_rid(), body.get_rid(), door.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func request_exit() -> bool:
	if state != State.SEATED:
		return false
	if not space_clear():
		message = "Bitte seitlich Platz machen: Tuer und Ausstiegsweg sind blockiert."
		return false
	message = ""
	state = State.EXITING
	progress = 0
	return true

func request_enter() -> bool:
	if state != State.OUTSIDE:
		return false
	if not space_clear():
		message = "Bitte vom Einstiegsweg zuruecktreten."
		return false
	message = ""
	collider.disabled = true
	state = State.ENTERING
	progress = 0
	return true

func is_busy() -> bool:
	return state == State.EXITING or state == State.ENTERING

func can_drive() -> bool:
	return state == State.SEATED and absf(door.rotation.y) < 0.01

func interaction_point() -> Vector3:
	return global_position + Vector3(0, 1.35, 0)

func apply_pose(t: float) -> void:
	var door_open := minf(clampf(t / 0.22, 0, 1), clampf((1.0 - t) / 0.18, 0, 1))
	door.rotation.y = -1.15 * smoothstep(0.0, 1.0, door_open)
	var movement := smoothstep(0.0, 1.0, clampf((t - 0.24) / 0.55, 0, 1))
	position = seat.lerp(outside, movement)
	rotation.y = lerpf(0, PI / 2.0, movement)
	rig.scale = Vector3.ONE * lerpf(0.78, 1.0, movement)
	for i in range(limbs.size()):
		var seated_angle := 0.95 if i < 2 else 0.55
		var sway := sin(movement * TAU * 2) * 0.2 * sin(movement * PI)
		limbs[i].rotation.x = lerpf(seated_angle, 0, movement) + sway * (1 if i % 2 == 0 else -1)
	body.global_position = global_position

func _physics_process(delta: float) -> void:
	if not is_busy():
		return
	# Pause safely if the officer steps into the path during the animation.
	if not space_clear():
		message = "Bewegung pausiert: bitte Tuer und Weg freihalten."
		return
	message = ""
	progress = minf(1.0, progress + delta / DURATION)
	apply_pose(progress if state == State.EXITING else 1.0 - progress)
	if progress >= 1.0:
		state = State.OUTSIDE if state == State.EXITING else State.SEATED
		collider.disabled = state != State.OUTSIDE
