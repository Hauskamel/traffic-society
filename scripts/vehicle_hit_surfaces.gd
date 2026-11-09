extends Node
const HitSurface = preload("res://scripts/vehicle_hit_surface.gd")
const SHOT_LAYER := 16
const MAX_MARKS := 64
var vehicle: Node3D
var zones: Array[HitSurface] = []
var marks: Array[MeshInstance3D] = []
var last_zone := ""
var last_kind := ""
var flat_tires := 0
var flat_steers: Array[Node3D] = []
var wheel_positions: Dictionary = {}
var damage_sound: AudioStreamPlayer3D
static var hole_material: StandardMaterial3D

func _ready() -> void:
	process_physics_priority = 1

func build(root: Node) -> void:
	for node in root.get_children():
		if node == vehicle.driver or node == vehicle.marker or node == vehicle.cargo_props or node is HitSurface:
			continue
		if node is MeshInstance3D and (node.mesh is BoxMesh or node.mesh is CylinderMesh):
			add_surface(node)
		else:
			build(node)

func add_surface(mesh: MeshInstance3D) -> void:
	var zone := HitSurface.new()
	zone.vehicle = vehicle
	zone.surface = mesh
	zone.zone_id = str(vehicle.get_path_to(mesh))
	zone.collision_layer = SHOT_LAYER
	zone.collision_mask = 0
	zone.kind = "body"
	var material = mesh.material_override
	if material is StandardMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		zone.kind = "glass"
	elif mesh.mesh is CylinderMesh:
		zone.kind = "tire"
	else:
		var parent := mesh.get_parent()
		if vehicle.wheels.has(parent):
			zone.kind = "wheel"
	var hit := CollisionShape3D.new()
	if mesh.mesh is BoxMesh:
		var shape := BoxShape3D.new()
		shape.size = mesh.mesh.size
		hit.shape = shape
	else:
		hit.shape = mesh.mesh.create_convex_shape()
	zone.add_child(hit)
	mesh.add_child(zone)
	zones.append(zone)

func add_mark(zone: HitSurface, point: Vector3, normal: Vector3) -> void:
	if normal.length_squared() < 0.5:
		return
	if hole_material == null:
		hole_material = StandardMaterial3D.new()
		hole_material.albedo_texture = preload("res://assets/effects/bullet_hole.svg")
		hole_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		hole_material.alpha_scissor_threshold = 0.12
		hole_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		hole_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mark := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.085, 0.085)
	mark.mesh = quad
	mark.material_override = hole_material
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	zone.surface.add_child(mark)
	mark.global_position = point + normal.normalized() * 0.002
	var up := Vector3.RIGHT if absf(normal.normalized().dot(Vector3.UP)) > 0.95 else Vector3.UP
	mark.look_at(mark.global_position + normal, up, true)
	marks.append(mark)
	last_zone = zone.zone_id
	last_kind = zone.kind
	while marks.size() > MAX_MARKS:
		var old := marks.pop_front() as MeshInstance3D
		old.queue_free()

func register_damage(zone: HitSurface, point: Vector3, normal: Vector3) -> void:
	if zone.kind == "glass" and zone.damage_state >= 2:
		return
	add_mark(zone, point, normal)
	if zone.kind == "glass":
		zone.damage_state += 1
		if zone.damage_state == 1:
			crack_glass(zone)
		else:
			zone.collision_layer = 0
			zone.surface.hide()
			play_damage(preload("res://assets/audio/glass_break.wav"))
			glass_fragments(point)
	elif zone.kind == "tire" and zone.damage_state == 0:
		zone.damage_state = 1
		flatten_tire(zone)

func play_damage(stream: AudioStream) -> void:
	if not is_instance_valid(damage_sound):
		damage_sound = AudioStreamPlayer3D.new()
		vehicle.add_child(damage_sound)
		damage_sound.volume_db = -13
	damage_sound.stream = stream
	damage_sound.play()

func crack_glass(zone: HitSurface) -> void:
	var dimensions: Vector3 = zone.surface.mesh.size
	var axis := 0 if dimensions.x < dimensions.z else 2
	var material := StandardMaterial3D.new()
	material.albedo_texture = preload("res://assets/effects/glass_cracks.svg")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.1
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1.0, 1.0]:
		var cracks := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(dimensions.z if axis == 0 else dimensions.x, dimensions.y)
		cracks.mesh = quad
		cracks.material_override = material
		cracks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.surface.add_child(cracks)
		cracks.position[axis] = side * (dimensions[axis] / 2 + 0.003)
		cracks.rotation.y = side * PI / 2 if axis == 0 else (0.0 if side > 0 else PI)

func glass_fragments(point: Vector3) -> void:
	var root := vehicle.get_parent()
	for i in range(8):
		var shard := MeshInstance3D.new()
		var triangle := PrismMesh.new()
		triangle.size = Vector3(0.025, 0.05, 0.008)
		shard.mesh = triangle
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("b4d2da")
		shard.material_override = material
		root.add_child(shard)
		shard.global_position = point
		var tween := shard.create_tween().set_parallel(true)
		var end := point + Vector3(sin(i * 2.4) * 0.45, 0, cos(i * 2.4) * 0.45)
		end.y = 0.1
		tween.tween_property(shard, "global_position", end, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(shard, "rotation", Vector3(i, i * 0.7, i * 0.3), 0.7)
		tween.chain().tween_property(shard, "scale", Vector3.ZERO, 0.2)
		tween.chain().tween_callback(shard.queue_free)

func flatten_tire(zone: HitSurface) -> void:
	var spin: Node3D = zone.surface.get_parent()
	var steer: Node3D = spin.get_parent()
	if flat_steers.has(steer):
		return
	if wheel_positions.is_empty():
		for wheel in vehicle.wheels:
			var support: Node3D = wheel.get_parent()
			wheel_positions[support.get_instance_id()] = support.position
	flat_steers.append(steer)
	flat_tires = flat_steers.size()
	zone.surface.hide()
	zone.collision_layer = 0
	for child in spin.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			child.scale.x = 1.4
	var rubber := MeshInstance3D.new()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var a := TAU * i / 12
		var b := TAU * (i + 1) / 12
		var left_a := Vector3(-0.15, maxf(-0.22, cos(a) * 0.35), sin(a) * 0.35)
		var left_b := Vector3(-0.15, maxf(-0.22, cos(b) * 0.35), sin(b) * 0.35)
		var right_a := left_a + Vector3(0.3, 0, 0)
		var right_b := left_b + Vector3(0.3, 0, 0)
		for vertex in [left_a, left_b, right_a, right_a, left_b, right_b, Vector3(-0.15, 0, 0), left_b, left_a, Vector3(0.15, 0, 0), right_a, right_b]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	rubber.mesh = tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("202b31")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	rubber.material_override = material
	steer.add_child(rubber)
	var flat := HitSurface.new()
	flat.vehicle = vehicle
	flat.surface = rubber
	flat.kind = "tire"
	flat.zone_id = zone.zone_id + ":flat"
	flat.damage_state = 1
	flat.collision_layer = SHOT_LAYER
	flat.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = rubber.mesh.create_convex_shape()
	flat.add_child(collision)
	rubber.add_child(flat)
	zones.append(flat)
	play_damage(preload("res://assets/audio/tire_hiss.wav"))
	apply_stance()

func speed_cap() -> float:
	return [1000.0, 3.0, 1.8, 0.9, 0.45][mini(flat_tires, 4)]

func apply_stance() -> void:
	if flat_tires == 0:
		return
	var left := 0.0
	var right := 0.0
	var front := 0.0
	var rear := 0.0
	for steer in flat_steers:
		if steer.position.x < 0:
			left += 0.065
		else:
			right += 0.065
		if steer.position.z < 0:
			front += 0.065
		else:
			rear += 0.065
	vehicle.position.y = 0.08 - 0.0325 * flat_tires
	vehicle.rotation.z = (left - right) / 1.84
	vehicle.rotation.x = (rear - front) / (vehicle.body_length * 0.64)
	for spin in vehicle.wheels:
		var steer: Node3D = spin.get_parent()
		steer.position = wheel_positions[steer.get_instance_id()]
		steer.global_position.y = 0.08 + (0.22 if flat_steers.has(steer) else 0.35)

func _physics_process(_delta: float) -> void:
	apply_stance()
