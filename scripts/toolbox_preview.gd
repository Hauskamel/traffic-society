extends "res://scripts/item_preview.gd"
signal picked(part: String)
signal hovered(part: String)
const ToolboxModel = preload("res://scripts/toolbox_model.gd")
var crate: ToolboxModel
var current_part := ""
var highlighted: Array[MeshInstance3D] = []

func _ready() -> void:
	super._ready()
	mouse_exited.connect(end_hover)

func end_hover() -> void:
	dragging = false
	clear_highlight()
	hovered.emit("")

func set_container(item: Dictionary) -> void:
	clear_highlight()
	if is_instance_valid(model):
		world.remove_child(model)
		model.queue_free()
	model = Node3D.new()
	world.add_child(model)
	crate = ToolboxModel.new()
	model.add_child(crate)
	crate.configure(item, true)
	reset_view()

func rebuild() -> void:
	clear_highlight()
	var data: Dictionary = crate.item
	model.remove_child(crate)
	crate.queue_free()
	crate = ToolboxModel.new()
	model.add_child(crate)
	crate.configure(data, true)

func reset_view() -> void:
	distance = 3.5
	if is_instance_valid(model):
		model.rotation = Vector3.ZERO
	update_camera()

func update_camera() -> void:
	if is_instance_valid(camera):
		camera.position = Vector3(0.35, 0.65, 1).normalized() * distance
		camera.look_at(Vector3(0, 0.25, 0))

func pick(at: Vector2) -> String:
	if not is_instance_valid(crate) or size.x <= 0 or size.y <= 0:
		return ""
	var pixel := at * Vector2(viewport.size) / size
	var start := camera.project_ray_origin(pixel)
	var end := start + camera.project_ray_normal(pixel) * 20
	var query := PhysicsRayQueryParameters3D.create(start, end)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	var collider = hit.get("collider")
	if not is_instance_valid(collider):
		return ""
	var token: String = collider.get_meta("part", "")
	if token not in ["latch", "lid", "body"] and (not crate.item.opened or crate.moving):
		return ""
	return token

func clear_highlight() -> void:
	for mesh in highlighted:
		if is_instance_valid(mesh):
			mesh.material_overlay = null
	highlighted.clear()
	current_part = ""

func mark(part: String) -> void:
	if part == current_part:
		return
	clear_highlight()
	current_part = part
	if part.is_empty() or part == "body":
		return
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1, 0.8, 0.25, 0.3)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for node in crate.find_children("*", "StaticBody3D", true, false):
		if node.get_meta("part", "") == part:
			var mesh = node.get_parent()
			var meshes: Array[Node] = [mesh] if mesh is MeshInstance3D else mesh.find_children("*", "MeshInstance3D", true, false)
			for surface in meshes:
				surface.material_overlay = glow
				highlighted.append(surface)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			picked.emit(pick(event.position))
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance + (-0.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.2), 2.0, 5.0)
			update_camera()
		accept_event()
	elif event is InputEventMouseMotion:
		if dragging and is_instance_valid(model):
			model.rotation.y += event.relative.x * 0.01
			model.rotation.x = clampf(model.rotation.x + event.relative.y * 0.008, -0.6, 0.6)
		var part := pick(event.position)
		mark(part)
		hovered.emit(part)
		accept_event()
