extends Control
signal closed
signal opened(car: Node)
const Data = preload("res://game/documents/document_data.gd")
var documents: Dictionary = {}
var cards: Array[PanelContainer] = []
var workspace: Control
var dragging: PanelContainer
var drag_offset := Vector2.ZERO

func text(value: String, size: int, parent: Node, color := Color("263b42")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	var filter_material := ShaderMaterial.new()
	filter_material.shader = preload("res://shaders/document_world.gdshader")
	background.material = filter_material
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 28
	layout.offset_top = 24
	layout.offset_right = -28
	layout.offset_bottom = -24
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	text("DOKUMENTENKONTROLLE", 28, layout, Color("e9e5d6"))
	text("Dokumente an der Titelleiste ziehen und nebeneinander ansehen. Welt in Zeitlupe / 18 %.", 16, layout, Color("c3ceca"))
	workspace = Control.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(workspace)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	layout.add_child(footer)
	var reset := Button.new()
	reset.text = "Dokumente anordnen"
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(arrange)
	footer.add_child(reset)
	var close := Button.new()
	close.text = "Dokumente zurueckgeben [Esc]"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_view)
	footer.add_child(close)
	workspace.resized.connect(arrange)
	visible = false

func card(title: String, fields: Dictionary, tint: Color, portrait: bool) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 510)
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	workspace.add_child(panel)
	cards.append(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	panel.add_child(stack)
	var handle := Label.new()
	handle.text = title + "     ::"
	handle.add_theme_font_size_override("font_size", 23)
	handle.add_theme_color_override("font_color", Color("263b42"))
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	handle.gui_input.connect(handle_input.bind(panel))
	stack.add_child(handle)
	text("VERKEHRSAMT TRAFFIC SOCIETY / MUSTER", 12, stack)
	stack.add_child(HSeparator.new())
	if portrait:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		stack.add_child(row)
		# Placeholder portrait matches the current shared low-poly driver appearance.
		var photo := Control.new()
		photo.custom_minimum_size = Vector2(85, 96)
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(photo)
		for shape in [[Rect2(0, 0, 85, 96), "a4b7b7"], [Rect2(10, 65, 65, 31), "b79b69"], [Rect2(23, 15, 39, 50), "d7b49a"], [Rect2(23, 10, 39, 12), "514638"], [Rect2(31, 34, 5, 5), "24323b"], [Rect2(50, 34, 5, 5), "24323b"]]:
			var patch := ColorRect.new()
			patch.position = shape[0].position
			patch.size = shape[0].size
			patch.color = Color(shape[1])
			patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			photo.add_child(patch)
		text("LICHTBILD\nPrototyp", 13, row)
	for key in fields:
		var field := VBoxContainer.new()
		field.add_theme_constant_override("separation", 0)
		stack.add_child(field)
		text(key.to_upper(), 12, field, Color("56696b"))
		text(str(fields[key]), 20, field)

func handle_input(event: InputEvent, panel: PanelContainer) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = panel
			drag_offset = get_global_mouse_position() - panel.global_position
			workspace.move_child(panel, -1)
		else:
			dragging = null

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = null
	if event is InputEventMouseMotion and is_instance_valid(dragging):
		move_card(dragging, get_global_mouse_position() - workspace.global_position - drag_offset)
		get_viewport().set_input_as_handled()

func move_card(panel: PanelContainer, at: Vector2) -> void:
	panel.position = at.clamp(Vector2.ZERO, (workspace.size - panel.size * panel.scale).max(Vector2.ZERO))

func arrange() -> void:
	dragging = null
	var factor := minf(1.0, minf((workspace.size.x - 24) / 924.0, workspace.size.y / 600.0))
	factor = maxf(factor, 0.1)
	for i in range(cards.size()):
		cards[i].scale = Vector2.ONE * factor
		move_card(cards[i], Vector2((workspace.size.x - 924 * factor) * 0.5 + i * 474 * factor, 8))

func open_view(car: Node) -> bool:
	documents = Data.for_car(car)
	if documents.is_empty():
		return false
	for panel in cards:
		workspace.remove_child(panel)
		panel.queue_free()
	cards.clear()
	card("FUEHRERSCHEIN", documents.license, Color("dbd3cc"), true)
	card("FAHRZEUGPAPIER", documents.registration, Color("d6dfcc"), false)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	arrange.call_deferred()
	opened.emit(car)
	return true

func close_view() -> void:
	dragging = null
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()
