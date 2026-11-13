## Detailuntersuchung eines Behälters mit Öffnen, Finden und Entnehmen.
## Änderungen erfolgen direkt am übergebenen Gegenstandszustand.

extends Control
signal changed
const Preview = preload("res://game/inspection/toolbox_preview.gd")
const ItemPreview = preload("res://game/inventory/item_preview.gd")
var item: Dictionary = {}
var player: RefCounted
var preview: Preview
var detail_preview: ItemPreview
var heading: Label
var hint: Label
var detail: Label
var take: Button
var put_back: VBoxContainer
var selected_id := ""


## Erzeugt ein Textlabel und hängt es an den angegebenen UI-Knoten.
func label(value: String, parent: Node, font := 18) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(node)
	return node


## Erzeugt eine Schaltfläche und verbindet ihre Aktion mit dem Callback.
func button(value: String, parent: Node, action: Callable) -> Button:
	var node := Button.new()
	node.text = value
	node.focus_mode = Control.FOCUS_NONE
	node.pressed.connect(action)
	parent.add_child(node)
	return node


## Baut Behältervorschau, Hinweise und Inventaraktionen auf.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("102027")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	heading = label("WERKZEUGKOFFER", layout, 26)
	label(
		"Linksklick: Teil bedienen / Gegenstand ansehen  |  Rechts ziehen: drehen  |  Mausrad: Zoom",
		layout,
		16
	)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	preview = Preview.new()
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.custom_minimum_size = Vector2(560, 300)
	columns.add_child(preview)
	preview.picked.connect(activate)
	preview.hovered.connect(show_hint)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 310
	columns.add_child(sidebar)
	label("GENAUER ANSEHEN", sidebar, 20)
	detail_preview = ItemPreview.new()
	sidebar.add_child(detail_preview)
	label("Links ziehen: drehen | Mausrad: Zoom", sidebar, 13)
	detail = label("Waehle einen sichtbaren Gegenstand im Behaelter.", sidebar)
	take = button("Entnehmen", sidebar, take_selected)
	take.disabled = true
	label("Zurueck in diesen Behaelter", sidebar, 18)
	put_back = VBoxContainer.new()
	sidebar.add_child(put_back)
	hint = label("", layout)
	button("Ansicht zuruecksetzen", layout, preview.reset_view)
	button("Zurueck zum Inventar [Esc]", layout, close_view)
	hide()


## Öffnet die Ansicht mit den übergebenen Zustands- oder Inventardaten.
func open_view(data: Dictionary, inventory: RefCounted) -> void:
	item = data
	player = inventory
	selected_id = ""
	detail.text = "Waehle einen sichtbaren Gegenstand im Behaelter."
	detail_preview.set_item({})
	take.disabled = true
	preview.set_container(item)
	heading.text = item.name
	show_hint("")
	refresh_returns()
	show()


## Schließt die Ansicht und gibt ihre Eingabe-/Darstellungszustände zurück.
func close_view() -> void:
	preview.dragging = false
	preview.clear_highlight()
	hide()
	changed.emit()


## Zeigt den zum hervorgehobenen Behälterteil passenden Bedienhinweis.
func show_hint(part: String) -> void:
	if item.is_empty() or not is_instance_valid(hint):
		return
	if part == "latch":
		hint.text = "[Linksklick] Verschluss " + ("schliessen" if item.unlocked else "oeffnen")
	elif part == "insert":
		hint.text = (
			"[Linksklick] Einsatz "
			+ ("zuruecklegen" if item.get("insert_removed", false) else "herausnehmen")
		)
	elif part == "lid":
		hint.text = (
			"[Linksklick] Deckel " + ("schliessen" if item.opened else "oeffnen")
			if item.unlocked
			else "Zuerst den goldfarbenen Verschluss oeffnen."
		)
	else:
		hint.text = "Untersuche Verschluss, Deckel und sichtbaren Inhalt."
		for inside in item.contents.items:
			if inside.id == part and item.opened:
				hint.text = "[Linksklick] " + inside.name + " ansehen"


## Führt die zulässige Öffnungs-/Untersuchungsaktion am angeklickten Behälterteil aus.
func activate(part: String) -> void:
	if preview.crate.moving:
		return
	if part == "latch":
		if item.opened:
			hint.text = "Zuerst den Deckel schliessen."
			return
		item.unlocked = not item.unlocked
		show_hint(part)
	elif part == "insert" and item.opened:
		item.insert_removed = not item.get("insert_removed", false)
		selected_id = ""
		take.disabled = true
		detail_preview.set_item({})
		show_hint(part)
	elif part == "lid":
		if not item.unlocked:
			show_hint(part)
			return
		item.opened = not item.opened
		if not item.opened:
			selected_id = ""
			take.disabled = true
			detail_preview.set_item({})
			detail.text = "Der Deckel ist geschlossen."
		show_hint(part)
	elif item.opened and preview.crate.contents_root.visible:
		for inside in item.contents.items:
			if inside.id == part:
				selected_id = part
				show_hint(part)
				detail_preview.set_item(inside)
				detail.text = inside.name + "\n\n" + inside.description
				take.disabled = false
				break


## Entnimmt den ausgewählten gefundenen Inhalt bei freiem Spielerinventar.
func take_selected() -> void:
	if (
		not item.opened
		or not preview.crate.contents_root.visible
		or preview.crate.moving
		or selected_id.is_empty()
	):
		return
	if item.contents.transfer_to(selected_id, player):
		selected_id = ""
		take.disabled = true
		detail_preview.set_item({})
		detail.text = "Gegenstand ins Spielerinventar uebernommen."
		preview.rebuild()
		refresh_returns()
		changed.emit()
	else:
		hint.text = "Kein Platz im Spielerinventar. Der Gegenstand bleibt im Behaelter."


## Legt einen geeigneten Spieler-Gegenstand in den untersuchten Behälter zurück.
func return_item(id: String) -> void:
	if not item.opened or not preview.crate.contents_root.visible or preview.crate.moving:
		hint.text = "Zum Zuruecklegen zuerst den Behaelter oeffnen."
		return
	var valid := false
	for held in player.items:
		if held.id == id and held.get("container_id") == item.id:
			valid = true
	if valid and player.transfer_to(id, item.contents):
		preview.rebuild()
		refresh_returns()
		changed.emit()


## Aktualisiert die Liste zulässig zurücklegbarer Gegenstände.
func refresh_returns() -> void:
	for child in put_back.get_children():
		put_back.remove_child(child)
		child.queue_free()
	for held in player.items:
		if held.get("container_id") == item.id:
			button(held.name + " zuruecklegen", put_back, return_item.bind(held.id))
