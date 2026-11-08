extends Node
const HitSurface = preload("res://scripts/vehicle_hit_surface.gd")
const SHOT_LAYER := 16
const MAX_MARKS := 64
var vehicle: Node3D
var zones: Array[HitSurface] = []
var marks: Array[MeshInstance3D] = []
var last_zone := ""
var last_kind := ""
static var hole_material: StandardMaterial3D

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
