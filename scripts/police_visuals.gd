extends RefCounted

static func box(parent: Node3D, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
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

static func avatar(parent: Node3D) -> Node3D:
	var rig := Node3D.new()
	parent.add_child(rig)
	box(rig, Vector3(0, 1.15, 0), Vector3(0.46, 0.58, 0.29), "365a78")
	box(rig, Vector3(0, 0.87, 0), Vector3(0.48, 0.08, 0.31), "202e3b")
	box(rig, Vector3(0, 1.62, 0), Vector3(0.29, 0.32, 0.28), "d7b49a")
	box(rig, Vector3(0, 1.81, -0.01), Vector3(0.34, 0.08, 0.37), "d9e0df")
	box(rig, Vector3(0.12, 1.28, -0.155), Vector3(0.08, 0.1, 0.02), "efd58b")
	for i in range(2):
		var arm := Node3D.new()
		arm.name = "Arm" + str(i)
		rig.add_child(arm)
		arm.position = Vector3(-0.31 if i == 0 else 0.31, 1.34, 0)
		box(arm, Vector3(0, -0.27, 0), Vector3(0.15, 0.55, 0.18), "365a78")
		box(arm, Vector3(0, -0.59, 0), Vector3(0.14, 0.15, 0.15), "d7b49a")
	for i in range(2):
		var leg := Node3D.new()
		leg.name = "Leg" + str(i)
		rig.add_child(leg)
		leg.position = Vector3(-0.13 if i == 0 else 0.13, 0.85, 0)
		box(leg, Vector3(0, -0.4, 0), Vector3(0.18, 0.8, 0.21), "243d52")
		box(leg, Vector3(0, -0.8, -0.07), Vector3(0.2, 0.12, 0.34), "17232b")
	var handset := radio(rig)
	handset.position = Vector3(-0.18, 1.34, -0.2)
	handset.scale = Vector3.ONE * 0.5
	var marker := Label3D.new()
	marker.text = "DU"
	marker.font_size = 64
	marker.pixel_size = 0.006
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color("efd58b")
	marker.position.y = 2.2
	rig.add_child(marker)
	return rig

static func radio(parent: Node3D) -> Node3D:
	var handset := Node3D.new()
	parent.add_child(handset)
	box(handset, Vector3.ZERO, Vector3(0.24, 0.38, 0.1), "17232b")
	box(handset, Vector3(-0.075, 0.3, 0), Vector3(0.025, 0.25, 0.025), "263943")
	box(handset, Vector3(0, 0.05, 0.056), Vector3(0.19, 0.15, 0.018), "a6c2a0")
	for y in [-0.08, -0.12, -0.16]:
		box(handset, Vector3(0, y, 0.057), Vector3(0.17, 0.015, 0.01), "617b83")
	var screen := Label3D.new()
	screen.text = "STREIFE\nBEREIT"
	screen.font_size = 22
	screen.pixel_size = 0.0009
	screen.outline_size = 0
	screen.modulate = Color("17232b")
	screen.position = Vector3(0, 0.05, 0.068)
	handset.add_child(screen)
	handset.set_meta("screen", screen)
	return handset
