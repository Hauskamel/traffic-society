extends "res://scripts/toolbox_model.gd"
var insert: Node3D
var cylindrical := false

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: String, token := "body", solid := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 20
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = at
	if interactive and solid:
		var body := StaticBody3D.new()
		body.set_meta("part", token)
		var hit := CollisionShape3D.new()
		var collider := CylinderShape3D.new()
		collider.radius = radius
		collider.height = height
		hit.shape = collider
		body.add_child(hit)
		mesh.add_child(body)
	return mesh

func configure(data: Dictionary, enable_input := false) -> void:
	item = data
	interactive = enable_input
	cylindrical = item.container_type in ["paint_bucket", "water_barrel"]
	if cylindrical:
		var barrel: bool = item.container_type == "water_barrel"
		var radius := 0.5 if barrel else 0.43
		var top := 0.75 if barrel else 0.40
		var tint := "426d89" if barrel else "e1e0d6"
		cylinder(self, Vector3(0, -0.25, 0), radius, 0.06, tint)
		for i in range(20):
			var angle := TAU * i / 20
			var wall := piece(self, Vector3(sin(angle) * radius, (top - 0.25) / 2, cos(angle) * radius), Vector3(radius * 0.33, top + 0.25, 0.045), tint)
			wall.rotation.y = angle
		lid = Node3D.new()
		lid.position.y = top + 0.035
		add_child(lid)
		cylinder(lid, Vector3.ZERO, radius + 0.035, 0.065, "59696d", "lid")
		piece(lid, Vector3(0, 0.07, 0), Vector3(0.22, 0.08, 0.08), "9aa8a5", "lid")
		latch = Node3D.new()
		add_child(latch)
		if barrel:
			var water := cylinder(self, Vector3(0, 0.26, 0), radius - 0.04, 0.01, "5aabb9", "body", false)
			water.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			water.material_override.albedo_color.a = 0.32
		else:
			insert = Node3D.new()
			add_child(insert)
			cylinder(insert, Vector3(0, 0.15, 0), radius - 0.025, 0.06, "f6f4e8", "insert")
			piece(insert, Vector3(0.24, 0.19, 0.06), Vector3(0.1, 0.035, 0.12), "aa916c", "insert")
	else:
		piece(self, Vector3(0, -0.25, 0), Vector3(1.5, 0.06, 0.9), "d9dedb")
		for x in [-0.72, 0.72]:
			piece(self, Vector3(x, -0.02, 0), Vector3(0.06, 0.45, 0.9), "4b8294")
		for z in [-0.42, 0.42]:
			piece(self, Vector3(0, -0.02, z), Vector3(1.4, 0.45, 0.06), "4b8294")
		lid = Node3D.new()
		lid.position = Vector3(0, 0.24, -0.45)
		add_child(lid)
		piece(lid, Vector3(0, 0, 0.45), Vector3(1.52, 0.1, 0.92), "d9dedb", "lid")
		latch = Node3D.new()
		latch.position = Vector3(0, 0.25, 0.49)
		add_child(latch)
		piece(latch, Vector3(0, -0.05, 0), Vector3(0.18, 0.15, 0.05), "d3b86f", "latch")
		insert = Node3D.new()
		add_child(insert)
		piece(insert, Vector3(0, 0.05, 0), Vector3(1.28, 0.06, 0.70), "93aeb4", "insert")
		piece(insert, Vector3(-0.28, 0.13, 0), Vector3(0.28, 0.12, 0.3), "b3c577", "insert")
		piece(insert, Vector3(0.25, 0.16, 0), Vector3(0.13, 0.2, 0.13), "d4e3dd", "insert")
	contents_root = Node3D.new()
	add_child(contents_root)
	for inside in item.contents.items:
		var prop := Node3D.new()
		prop.name = inside.icon
		prop.position = Vector3(0, -0.12, 0)
		contents_root.add_child(prop)
		piece(prop, Vector3.ZERO, Vector3(0.42, 0.12, 0.27), "e1dfd1", inside.id)
		piece(prop, Vector3(0, 0.065, 0), Vector3(0.08, 0.012, 0.29), "ab916b", inside.id)
	apply_pose(true)

func apply_pose(snap := false, delta := 0.0) -> void:
	if cylindrical:
		var closed_y := 0.785 if item.container_type == "water_barrel" else 0.435
		var target := closed_y + (0.65 if item.opened else 0.0)
		lid.position.y = target if snap else move_toward(lid.position.y, target, delta * 1.7)
		moving = absf(lid.position.y - target) > 0.01
	else:
		var target := -1.95 if item.opened else 0.0
		lid.rotation.x = target if snap else move_toward(lid.rotation.x, target, delta * 2.8)
		latch.rotation.x = -1.2 if item.unlocked else 0.0
		moving = absf(lid.rotation.x - target) > 0.01
	if is_instance_valid(insert):
		var target := Vector3(1.0, 0.35, 0) if item.insert_removed else Vector3.ZERO
		insert.position = target if snap else insert.position.move_toward(target, delta * 2.0)
		moving = moving or insert.position.distance_to(target) > 0.01
		insert.visible = item.opened
	contents_root.visible = item.opened and item.insert_removed and not moving
	if interactive:
		for node in contents_root.find_children("*", "StaticBody3D", true, false):
			node.collision_layer = 1 if contents_root.visible else 0
		if is_instance_valid(insert):
			for node in insert.find_children("*", "StaticBody3D", true, false):
				node.collision_layer = 1 if insert.visible else 0

func _process(delta: float) -> void:
	if not item.is_empty():
		apply_pose(false, delta)
