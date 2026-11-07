extends AnimatableBody3D
## Authored encounter: +Z to -Z on the right-hand lane, then through the bay.
signal state_changed

enum State { DRIVING, PULLING_OVER, PARKED, LEAVING, FINISHED }
const DRIVER_NAME := "Bobby Mayer"
const PLATE := "TS BM 104"
const ROAD_SPEED := 3.0
const BAY_SPEED := 2.5
var state: State = State.DRIVING
var speed := ROAD_SPEED
var route: Curve3D
var distance := 0.0
var wheels: Array[Node3D] = []
var brake_material: StandardMaterial3D
var marker: MeshInstance3D
var window_point: Marker3D
var front_wheels: Array[Node3D] = []

func material(color: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.8
	return m

func piece(at: Vector3, size: Vector3, m: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = m
	parent.add_child(mesh)
	mesh.position = at
	return mesh

func _ready() -> void:
	name = "BobbyCar"
	sync_to_physics = false
	collision_layer = 2
	collision_mask = 0
	var hit := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(1.85, 1.5, 4.25)
	hit.shape = bounds
	hit.position.y = 0.96
	add_child(hit)
	var paint := material("477e89")
	var trim := material("24323b")
	var glass := material("a5c2cc")
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	glass.albedo_color.a = 0.28
	piece(Vector3(0, 0.75, 0), Vector3(1.8, 0.58, 4.2), paint)
	piece(Vector3(0, 1.22, 0.15), Vector3(1.6, 0.68, 2.15), glass)
	piece(Vector3(0, 1.6, 0.15), Vector3(1.7, 0.12, 2.25), paint)
	piece(Vector3(0, 1.22, 0.15), Vector3(1.65, 0.72, 0.10), paint)
	piece(Vector3(0, 0.52, -2.12), Vector3(1.82, 0.14, 0.14), trim)
	piece(Vector3(0, 0.52, 2.12), Vector3(1.82, 0.14, 0.14), trim)
	piece(Vector3(-0.96, 1.12, -0.4), Vector3(0.2, 0.18, 0.3), paint)
	piece(Vector3(0.96, 1.12, -0.4), Vector3(0.2, 0.18, 0.3), paint)
	brake_material = material("862c2b")
	for x in [-0.61, 0.61]:
		piece(Vector3(x, 0.82, -2.11), Vector3(0.42, 0.2, 0.04), material("fff0c7"))
		piece(Vector3(x, 0.82, 2.11), Vector3(0.42, 0.2, 0.04), brake_material)
	for x in [-0.92, 0.92]:
		for z in [-1.35, 1.35]:
			var steer := Node3D.new()
			add_child(steer)
			steer.position = Vector3(x, 0.35, z)
			if z < 0:
				front_wheels.append(steer)
			var spin := Node3D.new()
			steer.add_child(spin)
			wheels.append(spin)
			var tire := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.35
			cylinder.bottom_radius = 0.35
			cylinder.height = 0.22
			cylinder.radial_segments = 12
			tire.mesh = cylinder
			tire.material_override = trim
			tire.rotation.z = PI / 2
			spin.add_child(tire)
			piece(Vector3(0, 0, 0), Vector3(0.235, 0.17, 0.17), material("a8b2ae"), spin)
	# Fixed seated placeholder driver, ready for a later exit interaction.
	piece(Vector3(-0.43, 1.13, -0.1), Vector3(0.42, 0.49, 0.34), material("b79b69"))
	piece(Vector3(-0.43, 1.37, -0.15), Vector3(0.28, 0.28, 0.28), material("d7b49a"))
	var plate := Label3D.new()
	plate.text = PLATE
	plate.font_size = 32
	plate.pixel_size = 0.008
	plate.position = Vector3(0, 0.59, -2.2)
	plate.rotation.y = PI
	add_child(plate)
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 2.1
	ring.outer_radius = 2.17
	marker.mesh = ring
	marker.material_override = material("efd58b")
	marker.position.y = 0.06
	marker.visible = false
	add_child(marker)
	window_point = Marker3D.new()
	window_point.name = "DriverWindow"
	window_point.position = Vector3(-1.2, 1.3, -0.35)
	add_child(window_point)
	new_test_drive()

func set_route(points: Array[Vector3]) -> void:
	route = Curve3D.new()
	route.bake_interval = 0.08
	for i in range(points.size()):
		var tangent := Vector3.ZERO
		if i > 0 and i < points.size() - 1:
			tangent = (points[i + 1] - points[i - 1]) * 0.12
		route.add_point(points[i], -tangent, tangent)
	distance = 0.0

func new_test_drive() -> void:
	visible = true
	position = Vector3(2, 0.08, 52)
	rotation = Vector3.ZERO
	speed = ROAD_SPEED
	state = State.DRIVING
	marker.visible = false
	for wheel in front_wheels:
		wheel.rotation.y = 0
	set_route([position, Vector3(2, 0.08, -64)])
	state_changed.emit()

func can_stop() -> bool:
	return state == State.DRIVING and position.z > 28.0

func request_stop() -> bool:
	if not can_stop():
		return false
	state = State.PULLING_OVER
	marker.visible = true
	set_route([position, Vector3(2, 0.08, 28), Vector3(4, 0.08, 22),
		Vector3(6.8, 0.08, 17), Vector3(7.1, 0.08, 12), Vector3(7.1, 0.08, 5)])
	state_changed.emit()
	return true

func release() -> bool:
	if state != State.PARKED:
		return false
	state = State.LEAVING
	set_route([position, Vector3(7.1, 0.08, -12), Vector3(6.8, 0.08, -17),
		Vector3(4, 0.08, -22), Vector3(2, 0.08, -28), Vector3(2, 0.08, -64)])
	state_changed.emit()
	return true

func _physics_process(delta: float) -> void:
	if state == State.PARKED or state == State.FINISHED:
		return
	var remaining := route.get_baked_length() - distance
	var target := ROAD_SPEED
	if state == State.PULLING_OVER:
		target = minf(BAY_SPEED, sqrt(maxf(0.0, 2.0 * 1.6 * remaining)))
	elif state == State.LEAVING and position.z > -26:
		target = BAY_SPEED
	speed = move_toward(speed, target, 1.6 * delta)
	var travel := minf(speed * delta, remaining)
	distance += travel
	var next := route.sample_baked(distance, true)
	var ahead := route.sample_baked(minf(distance + 0.3, route.get_baked_length()), true)
	var direction := ahead - next
	var old_yaw := rotation.y
	position = next
	if direction.length_squared() > 0.00001:
		rotation.y = atan2(-direction.x, -direction.z)
	for wheel in wheels:
		wheel.rotation.x -= travel / 0.35
	for wheel in front_wheels:
		wheel.rotation.y = clampf(angle_difference(old_yaw, rotation.y) * 15.0, -0.35, 0.35)
	brake_material.albedo_color = Color("ff5646") if state == State.PULLING_OVER else Color("862c2b")
	if remaining <= 0.025:
		position = route.sample_baked(route.get_baked_length())
		speed = 0
		if state == State.PULLING_OVER:
			state = State.PARKED
			rotation.y = 0
			for wheel in front_wheels:
				wheel.rotation.y = 0
		else:
			state = State.FINISHED
			visible = false
		state_changed.emit()
