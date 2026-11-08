extends SubViewportContainer
## Isolated 3D inspection scene; no mutations to the inventory item.
var viewport: SubViewport
var world: Node3D
var model: Node3D
var camera: Camera3D
var selected_id := ""
var dragging := false
var distance := 3.0

func _ready() -> void:
	custom_minimum_size = Vector2(300, 200)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	viewport = SubViewport.new()
	viewport.size = Vector2i(512, 384)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var setting := Environment.new()
	setting.background_mode = Environment.BG_COLOR
	setting.background_color = Color("17232b")
	setting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	setting.ambient_light_color = Color("d4dfe4")
	setting.ambient_light_energy = 0.65
	environment.environment = setting
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 1.1
	world.add_child(light)
	camera = Camera3D.new()
	camera.fov = 35
	world.add_child(camera)
	camera.current = true
	reset_view()

func material(color: String, metallic := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.metallic = 0.65 if metallic else 0
	mat.roughness = 0.5
	return mat

func cube(at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	mesh.position = at
	model.add_child(mesh)
	return mesh

func ring(at: Vector3, radius: float, color: String) -> void:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.78
	torus.outer_radius = radius
	mesh.mesh = torus
	mesh.material_override = material(color, true)
	mesh.position = at
	mesh.rotation.x = PI / 2
	model.add_child(mesh)

func text_on_surface(text: String, at: Vector3, back := false, width := 350.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 44
	label.pixel_size = 0.002
	label.width = width
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("263943")
	label.outline_size = 0
	label.position = at
	label.rotation.y = PI if back else 0
	model.add_child(label)

func set_item(item: Dictionary) -> void:
	var id: String = item.get("id", "")
	if id == selected_id:
		return
	selected_id = id
	if is_instance_valid(model):
		world.remove_child(model)
		model.queue_free()
	model = Node3D.new()
	world.add_child(model)
	if item.is_empty():
		return
	match item.icon:
		"keys":
			ring(Vector3(-0.25, 0.25, 0), 0.22, "d5bd7e")
			cube(Vector3(0, -0.12, 0), Vector3(0.12, 0.68, 0.07), "c9c2a5").rotation.z = -0.4
			cube(Vector3(0.2, -0.12, 0.08), Vector3(0.12, 0.68, 0.07), "adb9bf").rotation.z = -0.7
			for y in [-0.3, -0.4]:
				cube(Vector3(0.12, y, 0), Vector3(0.17, 0.06, 0.07), "c9c2a5")
			cube(Vector3(-0.43, -0.05, 0.04), Vector3(0.4, 0.23, 0.06), "d8cba6")
			text_on_surface(item.owner, Vector3(-0.43, -0.05, 0.078), false, 160)
		"wallet":
			cube(Vector3.ZERO, Vector3(1, 0.65, 0.13), "92624d")
			cube(Vector3(0, 0, 0.075), Vector3(0.94, 0.59, 0.025), "a97555")
			cube(Vector3(0.35, 0, 0.11), Vector3(0.3, 0.18, 0.08), "c29b68")
		"receipt":
			cube(Vector3.ZERO, Vector3(0.9, 1.2, 0.018), "e1ddbf")
			var lines: PackedStringArray = item.description.split("\n", false)
			text_on_surface(item.name + "\n\n" + lines[0], Vector3(0, 0.12, 0.012))
			text_on_surface("Notizen\n\n" + ("\n".join(lines.slice(1)) if lines.size() > 1 else "Keine weiteren Vermerke."), Vector3(0, 0.1, -0.012), true)
		"case":
			cube(Vector3.ZERO, Vector3(1.1, 0.62, 0.5), "617b83")
			cube(Vector3(0, 0, 0.26), Vector3(1.1, 0.07, 0.035), "d3bd87")
			for x in [-0.2, 0.2]:
				cube(Vector3(x, 0.4, 0), Vector3(0.07, 0.2, 0.12), "d3bd87")
			cube(Vector3(0, 0.49, 0), Vector3(0.46, 0.07, 0.12), "d3bd87")
		"parcel":
			cube(Vector3.ZERO, Vector3(0.95, 0.7, 0.65), "b08e63")
			cube(Vector3.ZERO, Vector3(0.1, 0.71, 0.66), "e1c68b")
			cube(Vector3(0.15, 0.1, 0.334), Vector3(0.5, 0.25, 0.01), "e1ddbf")
			text_on_surface(item.name, Vector3(0.15, 0.1, 0.343), false, 220)
		"bag":
			cube(Vector3(0, -0.12, 0), Vector3(0.85, 0.8, 0.4), "839975")
			ring(Vector3(0, 0.4, 0), 0.23, "d3bd87")
		"rope":
			for i in range(4):
				ring(Vector3(0, 0, -0.12 + i * 0.08), 0.43, "c4a36b")
			cube(Vector3(0.35, -0.4, 0), Vector3(0.09, 0.4, 0.09), "c4a36b").rotation.z = 0.4
		"gloves":
			for x in [-0.25, 0.25]:
				cube(Vector3(x, -0.05, 0), Vector3(0.34, 0.6, 0.1), "b99d6c")
				for finger in range(4):
					cube(Vector3(x - 0.12 + finger * 0.08, 0.34, 0), Vector3(0.065, 0.25, 0.1), "b99d6c")
				cube(Vector3(x + 0.21, 0.06, 0), Vector3(0.16, 0.22, 0.1), "b99d6c").rotation.z = -0.5
		"radio":
			var handset: Node3D = preload("res://scripts/police_visuals.gd").radio(model)
			handset.scale = Vector3.ONE * 1.8
			handset.position.y = -0.15
		"flashlight":
			var mesh := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.18
			cylinder.bottom_radius = 0.13
			cylinder.height = 1.0
			mesh.mesh = cylinder
			mesh.material_override = material("617b83", true)
			model.add_child(mesh)
			cube(Vector3(0, 0.51, 0), Vector3(0.29, 0.04, 0.29), "efd58b")
			cube(Vector3(0, 0, 0.15), Vector3(0.1, 0.18, 0.05), "24323b")
		_:
			cube(Vector3.ZERO, Vector3(0.8, 0.8, 0.5), "617b83")
	reset_view()

func reset_view() -> void:
	distance = 3.0
	if is_instance_valid(model):
		model.rotation = Vector3(-0.12, -0.25, 0)
	if is_instance_valid(camera):
		camera.position = Vector3(0, 0.05, distance)
		camera.look_at(Vector3.ZERO)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance + (-0.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.2), 1.7, 5.0)
			camera.position.z = distance
		accept_event()
	elif event is InputEventMouseMotion and dragging and is_instance_valid(model):
		model.rotation.y += event.relative.x * 0.012
		model.rotation.x += event.relative.y * 0.012
		accept_event()
