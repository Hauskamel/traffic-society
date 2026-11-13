## Interaktiver 3D-Viewport für Werkzeugkasten und andere Behälter.
## Löst Mauspositionen in Modellteile auf und verwaltet deren Hervorhebung.

extends "res://game/inventory/item_preview.gd"
signal picked(part: String)
signal hovered(part: String)
const CargoModel = preload("res://game/inspection/cargo_container_model.gd")
const ToolboxModel = preload("res://game/inspection/toolbox_model.gd")
var crate: ToolboxModel
var current_part := ""
var highlighted: Array[MeshInstance3D] = []


## Richtet Modell-Viewport, Kamera und Mausinteraktion der Behälteransicht ein.
func _ready() -> void:
	super._ready()
	mouse_exited.connect(end_hover)


## Entfernt Modellhervorhebung und zugehörigen Hinweis beim Verlassen der Vorschau.
func end_hover() -> void:
	dragging = false
	clear_highlight()
	hovered.emit("")


## Übernimmt einen Behälterzustand und baut dessen Vorschau neu auf.
func set_container(item: Dictionary) -> void:
	clear_highlight()
	if is_instance_valid(model):
		world.remove_child(model)
		model.queue_free()
	model = Node3D.new()
	world.add_child(model)
	crate = ToolboxModel.new() if item.container_type == "toolbox" else CargoModel.new()
	model.add_child(crate)
	crate.configure(item, true)
	reset_view()


## Ersetzt das Behältermodell anhand seines aktuellen gespeicherten Zustands.
func rebuild() -> void:
	clear_highlight()
	var data: Dictionary = crate.item
	model.remove_child(crate)
	crate.queue_free()
	crate = ToolboxModel.new() if data.container_type == "toolbox" else CargoModel.new()
	model.add_child(crate)
	crate.configure(data, true)


## Stellt Kameradistanz und Modellorientierung der Vorschau zurück.
func reset_view() -> void:
	distance = (
		4.1 if is_instance_valid(crate) and crate.item.get("container_type") != "toolbox" else 3.5
	)
	if is_instance_valid(model):
		model.rotation = Vector3.ZERO
	update_camera()


## Übernimmt die aktuellen Kamera- und Perspektivparameter.
func update_camera() -> void:
	if is_instance_valid(camera):
		var elevation := 0.65
		if is_instance_valid(crate):
			match crate.item.get("container_type"):
				"paint_bucket":
					elevation = 1.4
				"water_barrel":
					elevation = 2.0
				"cooler":
					elevation = 1.05
		camera.position = Vector3(0.35, elevation, 1).normalized() * distance
		camera.look_at(
			(
				Vector3(0.2, 0.3, 0)
				if is_instance_valid(crate) and crate.item.get("container_type") != "toolbox"
				else Vector3(0, 0.25, 0)
			)
		)


## Übersetzt eine Mausposition per 3D-Strahlabfrage in einen benannten Modellteil.
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
	if token not in ["latch", "lid", "body", "insert"] and (not crate.item.opened or crate.moving):
		return ""
	if token not in ["latch", "lid", "body", "insert"] and not crate.contents_root.visible:
		return ""
	return token


## Entfernt sämtliche temporären Materialüberlagerungen der Vorschau.
func clear_highlight() -> void:
	for mesh in highlighted:
		if is_instance_valid(mesh):
			mesh.material_overlay = null
	highlighted.clear()
	current_part = ""


## Hebt ausschließlich die zum gewählten Modellteil gehörenden Meshes hervor.
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
			var meshes: Array[Node] = []
			if mesh is MeshInstance3D:
				meshes.append(mesh)
			else:
				meshes.assign(mesh.find_children("*", "MeshInstance3D", true, false))
			for surface in meshes:
				surface.material_overlay = glow
				highlighted.append(surface)


## Verarbeitet Drehen, Zoomen und gegebenenfalls Auswahl innerhalb der 3D-Vorschau.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			picked.emit(pick(event.position))
		elif (
			event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
		):
			distance = clampf(
				distance + (-0.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.2), 2.0, 5.0
			)
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
