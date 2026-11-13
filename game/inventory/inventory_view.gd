extends Control
signal closed
signal contents_changed
var source_owner := ""
var vehicle_mode := false
var focused_item_id := ""
var placement_vehicle: Node3D
var vehicle_return_button: Button
var heading: Label
var instructions: Label
var player_inventory: RefCounted
var npc_inventory: RefCounted
var npc_name := ""
var selected_id := ""
var selected_source := ""
var left_grid: GridContainer
var right_grid: GridContainer
var left_title: Label
var right_title: Label
var detail_name: Label
var detail: RichTextLabel
const ItemPreview = preload("res://game/inventory/item_preview.gd")
var preview: ItemPreview
var take_button: Button
var return_button: Button
const ToolboxInspection = preload("res://game/inspection/toolbox_inspection.gd")
var inspection: ToolboxInspection
var inspect_button: Button
var status: Label

func label(text: String, size: int, parent: Node) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	parent.add_child(node)
	return node

func button(text: String, parent: Node, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.025, 0.045, 0.055, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	heading = label("DURCHSUCHUNG / INVENTAR", 26, layout)
	instructions = label("Gegenstand anklicken: ansehen  |  Uebernehmen und Zurueckgeben sind eigene Aktionen", 15, layout)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var containers: Array[VBoxContainer] = []
	for i in range(3):
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.add_child(panel)
		var padding := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			padding.add_theme_constant_override("margin_" + side, 14)
		panel.add_child(padding)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 12)
		padding.add_child(column)
		containers.append(column)
	left_title = label("PERSON", 20, containers[0])
	left_grid = GridContainer.new()
	left_grid.columns = 3
	containers[0].add_child(left_grid)
	containers[1].add_theme_constant_override("separation", 6)
	detail_name = label("GEGENSTAND", 20, containers[1])
	preview = ItemPreview.new()
	containers[1].add_child(preview)
	label("Ziehen: drehen  |  Mausrad: Zoom", 13, containers[1])
	button("Ansicht zuruecksetzen", containers[1], preview.reset_view)
	detail = RichTextLabel.new()
	detail.custom_minimum_size = Vector2(0, 75)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("normal_font_size", 17)
	containers[1].add_child(detail)
	inspect_button = button("Genauer untersuchen", containers[1], inspect_selected)
	take_button = button("Uebernehmen", containers[1], transfer_selected.bind("npc"))
	return_button = button("Zurueckgeben", containers[1], transfer_selected.bind("player"))
	vehicle_return_button = button("Zurueck ins Fahrzeug legen", containers[1], return_to_vehicle)
	vehicle_return_button.hide()
	right_title = label("SPIELER", 20, containers[2])
	right_grid = GridContainer.new()
	right_grid.columns = 3
	containers[2].add_child(right_grid)
	status = label("", 16, layout)
	button("Durchsuchung beenden / Schliessen [Esc]", layout, close_view)
	inspection = ToolboxInspection.new()
	add_child(inspection)
	inspection.changed.connect(container_changed)
	hide()

func open_view(player: RefCounted, npc: RefCounted = null, person := "", owner_id := "", cargo := false) -> void:
	if inspection.visible:
		inspection.close_view()
	focused_item_id = ""
	placement_vehicle = null
	player_inventory = player
	npc_inventory = npc
	npc_name = person
	source_owner = owner_id if not owner_id.is_empty() else person
	vehicle_mode = cargo
	heading.text = "FAHRZEUGDURCHSUCHUNG" if cargo else "DURCHSUCHUNG / INVENTAR"
	instructions.text = "Gegenstand anklicken: ansehen  |  Entnehmen und Zuruecklegen sind eigene Aktionen" if cargo else "Gegenstand anklicken: ansehen  |  Uebernehmen und Zurueckgeben sind eigene Aktionen"
	take_button.text = "Entnehmen" if cargo else "Uebernehmen"
	return_button.text = "Zuruecklegen" if cargo else "Zurueckgeben"
	selected_id = ""
	selected_source = ""
	status.text = "Die Welt laeuft weiter. Blick und Bewegung sind waehrend der Ansicht gesperrt."
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh()

func close_view() -> void:
	if not visible:
		return
	if inspection.visible:
		inspection.close_view()
	hide()
	npc_inventory = null
	closed.emit()

func icon(name: String) -> Texture2D:
	return load("res://assets/items/" + name + ".svg")

func fill_grid(grid: GridContainer, inventory: RefCounted, source: String) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	if inventory == null:
		return
	var shown: Array[Dictionary] = []
	for item in inventory.items:
		if source != "npc" or focused_item_id.is_empty() or item.id == focused_item_id:
			shown.append(item)
	for i in range(1 if source == "npc" and not focused_item_id.is_empty() else inventory.capacity):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(102, 92)
		slot.focus_mode = Control.FOCUS_NONE
		grid.add_child(slot)
		if i >= shown.size():
			slot.text = "Leer"
			slot.disabled = true
			continue
		var item: Dictionary = shown[i]
		slot.icon = icon(item.icon)
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		slot.text = item.name
		slot.add_theme_font_size_override("font_size", 12)
		slot.tooltip_text = item.name
		slot.modulate = Color("efd58b") if selected_id == item.id else Color.WHITE
		slot.pressed.connect(select_item.bind(item.id, source))

func select_item(id: String, source: String) -> void:
	if source == "npc" and not focused_item_id.is_empty() and id != focused_item_id:
		return
	selected_id = id
	selected_source = source
	refresh()

func selected_item() -> Dictionary:
	var inventory: RefCounted = npc_inventory if selected_source == "npc" else player_inventory
	if inventory != null:
		for item in inventory.items:
			if item.id == selected_id:
				return item
	return {}

func refresh() -> void:
	left_title.text = (npc_name + "\n%d / %d Plaetze" % [npc_inventory.items.size(), npc_inventory.capacity]) if npc_inventory != null else "KEINE PERSON\nEigenes Inventar"
	if not focused_item_id.is_empty():
		left_title.text = "AUSGEWAEHLTER GEGENSTAND\n" + npc_name
	right_title.text = "SPIELER\n%d / %d Plaetze" % [player_inventory.items.size(), player_inventory.capacity]
	fill_grid(left_grid, npc_inventory, "npc")
	fill_grid(right_grid, player_inventory, "player")
	var item := selected_item()
	detail_name.text = item.get("name", "GEGENSTAND")
	preview.set_item(item)
	detail.text = item.description if not item.is_empty() else "Waehle einen Gegenstand, um ihn genauer anzusehen."
	vehicle_return_button.visible = can_return_to_vehicle(item)
	inspect_button.visible = item.get("container_type") in ["toolbox", "paint_bucket", "water_barrel", "cooler"]
	take_button.disabled = item.is_empty() or selected_source != "npc"
	return_button.disabled = item.is_empty() or selected_source != "player" or npc_inventory == null or item.get("owner") != source_owner or item.has("container_id") or (not focused_item_id.is_empty() and item.get("id") != focused_item_id)

func transfer_selected(source: String) -> void:
	var item := selected_item()
	if item.is_empty() or selected_source != source or npc_inventory == null:
		return
	if source == "player" and (item.owner != source_owner or item.has("container_id") or (not focused_item_id.is_empty() and item.id != focused_item_id)):
		status.text = "Dieser Gegenstand gehoert nicht zu diesem Inventar."
		return
	var origin: RefCounted = npc_inventory if source == "npc" else player_inventory
	var destination: RefCounted = player_inventory if source == "npc" else npc_inventory
	if origin.transfer_to(selected_id, destination):
		status.text = item.name + ((" entnommen." if vehicle_mode else " uebernommen.") if source == "npc" else (" zurueckgelegt." if vehicle_mode else " zurueckgegeben."))
		selected_source = "player" if source == "npc" else "npc"
		contents_changed.emit()
	else:
		status.text = "Kein Platz im Zielinventar. Der Gegenstand bleibt an seinem Ort."
	refresh()

func inspect_selected() -> void:
	var item := selected_item()
	if item.get("container_type") in ["toolbox", "paint_bucket", "water_barrel", "cooler"]:
		inspection.open_view(item, player_inventory)

func container_changed() -> void:
	# Rebuild the small preview so opening/removing is visible after returning.
	preview.selected_id = ""
	refresh()
	contents_changed.emit()

func back() -> void:
	if inspection.visible:
		inspection.close_view()
	else:
		close_view()

func open_world_item(player: RefCounted, cargo: RefCounted, item: Dictionary, title: String) -> void:
	open_view(player, cargo, title, item.owner, true)
	focused_item_id = item.id
	select_item(item.id, "npc")
	inspect_selected()

func open_player_view(player: RefCounted, car: Node3D, origin: Vector3) -> void:
	open_view(player)
	if not is_instance_valid(car) or car.state != car.State.PARKED or not car.cargo_accessible() or car.pickup_reserved:
		return
	var local := car.to_local(origin)
	if origin.distance_to(car.to_global(Vector3(0, 1, car.body_length / 2))) < 2.8 and (local.z > car.body_length / 2 - 0.35 or car.officer_aboard):
		placement_vehicle = car
	refresh()

func can_return_to_vehicle(item: Dictionary) -> bool:
	return is_instance_valid(placement_vehicle) and placement_vehicle.state == placement_vehicle.State.PARKED and placement_vehicle.cargo_accessible() and not placement_vehicle.pickup_reserved and selected_source == "player" and item.get("owner") == "Fahrzeug " + placement_vehicle.plate_number and not item.has("container_id")

func return_to_vehicle() -> void:
	var item := selected_item()
	if not can_return_to_vehicle(item):
		return
	if player_inventory.transfer_to(item.id, placement_vehicle.cargo_inventory):
		status.text = "Gegenstand ins urspruengliche Fahrzeug zurueckgelegt."
		selected_id = ""
		contents_changed.emit()
	else:
		status.text = "Kein Platz im Fahrzeug."
	refresh()
