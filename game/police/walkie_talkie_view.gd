## Nahansicht des Funkgeräts mit monochromem LCD und vier Einsatz-Platzhaltern.
## Die Einsatzknöpfe sind bewusst ohne Signale; nur Schließen ist bereits bedienbar.

extends PanelContainer
signal closed
const INK := Color("172d10")
const LCD := Color("9ccf45")
const SERVICES := [
	["police", "Polizei"],
	["fire", "Feuerwehr"],
	["medical", "Sanitäter"],
	["backup", "Verstärkung"],
]
var service_buttons: Array[Button] = []
var lcd_panel: PanelContainer


## Erstellt einen abgerundeten Rahmen mit einheitlicher Innenkante.
func style(fill: Color, edge: Color, radius: int, border: int = 2) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = edge
	result.set_border_width_all(border)
	result.set_corner_radius_all(radius)
	result.set_content_margin_all(12)
	return result


## Erzeugt eine LCD-Zeile in der gemeinsamen monochromen Schrift.
func lcd_text(value: String, size: int, parent: Node) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


## Baut Gehäuse, Statuszeile, LCD-Raster und Lautsprecher auf.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -410
	offset_right = -40
	offset_top = -265
	offset_bottom = 265
	add_theme_stylebox_override("panel", style(Color("20282c"), Color("465057"), 26, 4))
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["DejaVu Sans Mono", "Consolas", "monospace"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 16
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	add_child(body)
	var hardware := Label.new()
	hardware.text = "▮▮    TRAFFIC / PORTABLE    ●"
	hardware.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hardware.add_theme_font_size_override("font_size", 15)
	hardware.add_theme_color_override("font_color", Color("aab1a9"))
	body.add_child(hardware)
	lcd_panel = PanelContainer.new()
	lcd_panel.add_theme_stylebox_override("panel", style(LCD, Color("354b21"), 14, 5))
	body.add_child(lcd_panel)
	var screen := VBoxContainer.new()
	screen.add_theme_constant_override("separation", 9)
	lcd_panel.add_child(screen)
	lcd_text("▂▄▆█  21-1       ▰▰▰", 16, screen)
	var title := lcd_text("EINSATZWAHL", 23, screen)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	screen.add_child(grid)
	for entry in SERVICES:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		button.icon = load("res://assets/radio/" + entry[0] + ".svg")
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 32)
		button.add_theme_constant_override("h_separation", 6)
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size = Vector2(148, 87)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override("font_color", INK)
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = "Einsatzfunktion folgt in Schritt 2."
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(
				state, style(Color("8dbd3f") if state == "normal" else Color("b2de61"), INK, 2, 2)
			)
			button.add_theme_color_override("font_" + state + "_color", INK)
		grid.add_child(button)
		service_buttons.append(button)
	var hint := lcd_text("AUSWAHL BEREIT", 13, screen)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var slots := Label.new()
	slots.text = "━━━━━━━━━━━━━━━━━━━━\n━━━━━━━━━━━━━━━━━━━━\n━━━━━━━━━━━━━━━━━━━━"
	slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots.add_theme_font_size_override("font_size", 19)
	slots.add_theme_color_override("font_color", Color("0e1518"))
	body.add_child(slots)
	var close := Button.new()
	close.text = "SCHLIESSEN  [T / ESC]"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 14)
	close.add_theme_stylebox_override("normal", style(Color("303b40"), Color("52615d"), 7))
	close.pressed.connect(func(): closed.emit())
	body.add_child(close)
	# Transparent scan lines add LCD texture without filtering the world or UI input.
	var scanlines := ColorRect.new()
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){float a=mod(FRAGCOORD.y,3.0)<1.0?.065:0.0; COLOR=vec4(.12,.25,.04,a);}"
	var material := ShaderMaterial.new()
	material.shader = shader
	scanlines.material = material
	lcd_panel.add_child(scanlines)


## Zeichnet Antenne und Drehknopf außerhalb der Gehäusekante.
func _draw() -> void:
	draw_style_box(style(Color("182124"), Color("465057"), 7, 2), Rect2(25, -94, 18, 100))
	draw_style_box(style(Color("303c3e"), Color("52615d"), 4, 2), Rect2(68, -12, 38, 17))
