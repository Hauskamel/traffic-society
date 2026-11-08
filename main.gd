extends Node3D

const SpeedSettings = preload("res://scripts/speed_settings.gd")

var player: CharacterBody3D
var eyes: Camera3D
var overview: Camera3D
var aerial := true
var pitch := 0.0
const TrafficCar = preload("res://scripts/traffic_car.gd")
const TrafficManager = preload("res://scripts/traffic_manager.gd")
var traffic: TrafficManager
var interact_hint: Label
var stop_button: Button
var interaction_open := false
var interaction_index := 0
var interaction_actions: Array[String] = []
var interaction_panel: PanelContainer
var interaction_rows: RichTextLabel
const VehiclePart = preload("res://scripts/vehicle_part.gd")
var hovered_part: VehiclePart
const ItemInventory = preload("res://scripts/item_inventory.gd")
const InventoryView = preload("res://scripts/inventory_view.gd")
var player_inventory: RefCounted = ItemInventory.for_player()
const DocumentView = preload("res://scripts/document_view.gd")
var document_view: DocumentView
const DocumentMode = preload("res://scripts/document_mode.gd")
var document_mode: DocumentMode
var ui_layer: CanvasLayer
const PlayerEquipment = preload("res://scripts/player_equipment.gd")
var equipment: PlayerEquipment
const NpcCompliance = preload("res://scripts/npc_compliance.gd")
var compliance: NpcCompliance
var radio_car: Node3D
var menu_car: Node3D
var inventory_view: InventoryView
var searching_driver: Node3D
var searching_car: Node3D
var cargo_search_car: Node3D
const Timings = preload("res://scripts/interaction_timings.gd")
var crosshair: Label
var search_progress: ProgressBar
var cargo_search_clock := 0.0
const VehicleClimb = preload("res://scripts/vehicle_climb.gd")
var climber: VehicleClimb
const PoliceVisuals = preload("res://scripts/police_visuals.gd")
const PatrolDispatch = preload("res://scripts/patrol_dispatch.gd")
var patrol: PatrolDispatch
var player_avatar: Node3D
var radio_model: Node3D
var radio_panel: PanelContainer
var radio_status: Label
var radio_call_button: Button
var radio_cancel_button: Button
var radio_open := false
var avatar_clock := 0.0
var cargo_start_pitch := 0.0
var feedback := ""
var feedback_time := 0.0

func mat(hex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 1.0
	return m

func block(pos: Vector3, size: Vector3, material: Material, solid := false) -> void:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var hit := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		hit.shape = shape
		body.add_child(hit)
		mesh.add_child(body)

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("7c9aaa")
	sky_material.sky_horizon_color = Color("dedbc4")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c9d6dd")
	environment.ambient_light_energy = 0.35
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -35, 0)
	sun.light_energy = 0.9
	sun.light_color = Color("ffe7c7")
	sun.shadow_enabled = true
	add_child(sun)

	var grass := mat("78836a")
	var asphalt := mat("303a40")
	var white := mat("e1e1ce")
	var yellow := mat("d3b765")
	var curb := mat("a5aa9f")

	block(Vector3(0, -0.25, 0), Vector3(180, 0.5, 180), grass, true)
	block(Vector3(0, 0.02, 0), Vector3(9.5, 0.04, 120), mat("a1a38a"))
	block(Vector3(0, 0.05, 0), Vector3(8, 0.06, 120), asphalt)

	# Parkbucht mit schraeger Ein- und Ausfahrt.
	var vertices := [
		Vector3(4, 0.09, -23), Vector3(10, 0.09, -15),
		Vector3(10, 0.09, 15), Vector3(4, 0.09, -23),
		Vector3(10, 0.09, 15), Vector3(4, 0.09, 23)
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices:
		surface.set_normal(Vector3.UP)
		surface.add_vertex(vertex)
	var bay := MeshInstance3D.new()
	bay.mesh = surface.commit()
	var bay_material := mat("303a40")
	bay_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bay.material_override = bay_material
	bay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bay)

	block(Vector3(-3.65, 0.09, 0), Vector3(0.12, 0.01, 120), white)
	for z in range(-57, 60, 6):
		block(Vector3(0, 0.09, z), Vector3(0.12, 0.01, 3), white)
	for z in [-42, 42]:
		block(Vector3(3.65, 0.09, z), Vector3(0.12, 0.01, 36), white)
	for z in range(-20, 22, 4):
		block(Vector3(3.65, 0.105, z), Vector3(0.12, 0.01, 2), white)
	block(Vector3(10.2, 0.15, 0), Vector3(0.35, 0.3, 30), curb, true)
	for z in [-10, 0, 10]:
		block(Vector3(7.1, 0.11, z), Vector3(4.7, 0.01, 0.12), yellow)
	block(Vector3(9.4, 0.11, 0), Vector3(0.12, 0.01, 20), yellow)

	# Leitpfosten und Parkschild.
	for z in range(-55, 60, 10):
		for x in [-4.7, 4.7]:
			if x > 0 and abs(z) < 25:
				continue
			block(Vector3(x, 0.45, z), Vector3(0.15, 0.9, 0.15), white, true)
			block(Vector3(x, 0.65, z), Vector3(0.16, 0.2, 0.16), asphalt)
	block(Vector3(10.8, 1.3, -12), Vector3(0.08, 2.6, 0.08), curb, true)
	block(Vector3(10.8, 2.5, -12), Vector3(0.8, 0.9, 0.1), mat("315c78"))
	var parking := Label3D.new()
	parking.text = "P"
	parking.font_size = 100
	parking.pixel_size = 0.006
	parking.position = Vector3(10.8, 2.5, -11.94)
	add_child(parking)

	# Einfache, fest platzierte Low-Poly-Kulisse.
	var foliage := mat("4a6555")
	for i in range(26):
		var x := -17.0 - (i % 4) * 4.0 if i % 2 == 0 else 21.0 + (i % 4) * 4.0
		var z := -60.0 + i * 4.8
		block(Vector3(x, 1.5, z), Vector3(0.4, 3, 0.4), mat("625b49"), true)
		var tree := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0
		cone.bottom_radius = 2.5
		cone.height = 6
		cone.radial_segments = 6
		tree.mesh = cone
		tree.material_override = foliage
		tree.position = Vector3(x, 5, z)
		add_child(tree)

	climber = VehicleClimb.new()
	climber.scene = self
	player = CharacterBody3D.new()
	player.collision_mask = 7
	player.position = Vector3(7.5, 0.2, 8)
	var hit := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	hit.shape = capsule
	hit.position.y = 0.9
	player.add_child(hit)
	add_child(player)
	eyes = Camera3D.new()
	eyes.position.y = 1.7
	eyes.fov = 76
	player.add_child(eyes)
	player_avatar = PoliceVisuals.avatar(player)
	radio_model = PoliceVisuals.radio(eyes)
	radio_model.position = Vector3(0.34, -0.25, -0.6)
	radio_model.visible = false
	player.rotation.y = PI / 2

	overview = Camera3D.new()
	overview.projection = Camera3D.PROJECTION_ORTHOGONAL
	overview.size = 65
	overview.position = Vector3(35, 52, 50)
	add_child(overview)
	overview.look_at(Vector3(2, 0, 12))

	traffic = TrafficManager.new()
	add_child(traffic)
	patrol = PatrolDispatch.new()
	patrol.scene = self
	add_child(patrol)

	var layer := CanvasLayer.new()
	ui_layer = layer
	add_child(layer)
	stop_button = Button.new()
	stop_button.text = "Zur Kontrolle anhalten"
	stop_button.focus_mode = Control.FOCUS_NONE
	stop_button.pressed.connect(order_stop)
	stop_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	stop_button.offset_left = -110
	stop_button.offset_right = 110
	stop_button.offset_top = -100
	stop_button.offset_bottom = -60
	stop_button.custom_minimum_size = Vector2(220, 40)
	layer.add_child(stop_button)
	interact_hint = Label.new()
	interact_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	interact_hint.offset_top = -116
	interact_hint.offset_bottom = -76
	interact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(interact_hint)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(5, 12)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
	search_progress = ProgressBar.new()
	search_progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	search_progress.position -= Vector2(60, 4)
	search_progress.custom_minimum_size = Vector2(120, 8)
	search_progress.show_percentage = false
	search_progress.add_theme_font_size_override("font_size", 1)
	for style_name in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("263943") if style_name == "background" else Color("efd58b")
		style.set_corner_radius_all(3)
		style.set_content_margin_all(0)
		search_progress.add_theme_stylebox_override(style_name, style)
	search_progress.size = Vector2(120, 8)
	search_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	search_progress.visible = false
	layer.add_child(search_progress)
	interaction_panel = PanelContainer.new()
	interaction_panel.position = Vector2(760, 280)
	interaction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(interaction_panel)
	var menu_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		menu_margin.add_theme_constant_override("margin_" + side, 20)
	interaction_panel.add_child(menu_margin)
	interaction_rows = RichTextLabel.new()
	interaction_rows.bbcode_enabled = true
	interaction_rows.fit_content = true
	interaction_rows.scroll_active = false
	interaction_rows.custom_minimum_size.x = 350
	interaction_rows.add_theme_font_size_override("normal_font_size", 20)
	menu_margin.add_child(interaction_rows)
	interaction_panel.visible = false
	radio_panel = PanelContainer.new()
	radio_panel.position = Vector2(30, 340)
	layer.add_child(radio_panel)
	var radio_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		radio_margin.add_theme_constant_override("margin_" + side, 18)
	radio_panel.add_child(radio_margin)
	var radio_stack := VBoxContainer.new()
	radio_stack.add_theme_constant_override("separation", 12)
	radio_margin.add_child(radio_stack)
	var radio_title := Label.new()
	radio_title.text = "FUNKGERAET / STREIFE 21-1"
	radio_stack.add_child(radio_title)
	radio_status = Label.new()
	radio_stack.add_child(radio_status)
	radio_call_button = Button.new()
	radio_call_button.text = "Streife zur Abholung anfordern"
	radio_call_button.focus_mode = Control.FOCUS_NONE
	radio_call_button.pressed.connect(call_patrol)
	radio_stack.add_child(radio_call_button)
	radio_cancel_button = Button.new()
	radio_cancel_button.text = "Anforderung abbrechen"
	radio_cancel_button.focus_mode = Control.FOCUS_NONE
	radio_cancel_button.pressed.connect(patrol.cancel_waiting)
	radio_stack.add_child(radio_cancel_button)
	var close_radio := Button.new()
	close_radio.text = "Funk schliessen [T / Esc]"
	close_radio.focus_mode = Control.FOCUS_NONE
	close_radio.pressed.connect(set_radio_open.bind(false))
	radio_stack.add_child(close_radio)
	radio_panel.visible = false
	inventory_view = InventoryView.new()
	layer.add_child(inventory_view)
	inventory_view.closed.connect(finish_search)
	inventory_view.contents_changed.connect(refresh_cargo_visuals)
	document_mode = DocumentMode.new()
	document_mode.scene = self
	add_child(document_mode)
	var document_layer := CanvasLayer.new()
	document_layer.layer = 2
	add_child(document_layer)
	document_view = DocumentView.new()
	document_layer.add_child(document_view)
	document_view.opened.connect(document_mode.enter)
	document_view.closed.connect(document_mode.leave)
	equipment = PlayerEquipment.new()
	equipment.scene = self
	add_child(equipment)
	compliance = NpcCompliance.new()
	compliance.scene = self
	add_child(compliance)
	update_camera()
	refresh_encounter_ui()

func update_camera() -> void:
	close_interaction()
	set_radio_open(false)
	player_avatar.visible = aerial
	overview.current = aerial
	eyes.current = not aerial
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if aerial else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if climber.active:
		return
	if document_view.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			document_view.close_view()
		return
	if document_mode.active:
		return
	if radio_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_T, KEY_ESCAPE]:
			set_radio_open(false)
		return
	if inventory_view.visible or is_instance_valid(searching_driver) or is_instance_valid(cargo_search_car):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if inventory_view.visible:
				inventory_view.back()
			else:
				finish_search()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E and compliance.handcuff():
		return
	if equipment.handle(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			aerial = not aerial
			update_camera()
		elif event.keycode == KEY_T and not aerial:
			set_radio_open(true)
		elif event.keycode == KEY_SPACE:
			climber.begin()
		elif event.keycode == KEY_E:
			update_part_focus()
			if interaction_open:
				confirm_interaction()
			elif is_instance_valid(hovered_part):
				if hovered_part.kind == "cargo":
					begin_cargo_search(hovered_part.vehicle)
				else:
					if not hovered_part.toggle() and hovered_part.vehicle.officer_aboard:
						feedback = "Bitte zuerst die Ladeflaeche verlassen."
						feedback_time = 4
			elif can_interact():
				open_interaction()
		elif event.keycode == KEY_ESCAPE:
			if interaction_open:
				close_interaction()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_I and not aerial:
			close_interaction()
			inventory_view.open_view(player_inventory)
	if event is InputEventMouseButton and event.pressed:
		if interaction_open:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				interaction_index = posmod(interaction_index - 1, interaction_actions.size())
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				interaction_index = posmod(interaction_index + 1, interaction_actions.size())
			refresh_interaction()
			return
		if aerial:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var origin := overview.project_ray_origin(event.position)
				var end := origin + overview.project_ray_normal(event.position) * 250.0
				var query := PhysicsRayQueryParameters3D.create(origin, end, 2)
				var result := get_world_3d().direct_space_state.intersect_ray(query)
				if result.get("collider") is TrafficCar:
					traffic.select_car(result.collider)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				overview.size = maxf(20, overview.size - 3)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				overview.size = minf(85, overview.size + 3)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and not aerial and not interaction_open and not inventory_view.visible and not is_instance_valid(searching_driver) and not is_instance_valid(cargo_search_car) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotation.y -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.35, 1.35)
		eyes.rotation.x = pitch

func held(a: int, b: int) -> float:
	return 1.0 if Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b) else 0.0

func _physics_process(delta: float) -> void:
	equipment.tick(delta)
	compliance.tick(delta)
	avatar_clock += delta
	var walking := Vector2(player.velocity.x, player.velocity.z).length() > 0.1
	for i in range(2):
		player_avatar.get_node("Leg" + str(i)).rotation.x = sin(avatar_clock * 8 + i * PI) * 0.35 if walking else 0.0
	player_avatar.scale.y = climber.shape().shape.height / 1.8
	update_radio()
	climber.tick(delta)
	if climber.active:
		refresh_encounter_ui()
		return
	var move := Vector2(
		held(KEY_D, KEY_RIGHT) - held(KEY_A, KEY_LEFT),
		held(KEY_S, KEY_DOWN) - held(KEY_W, KEY_UP)
	).normalized()
	if document_mode.active or document_view.visible or radio_open or interaction_open or inventory_view.visible or is_instance_valid(searching_driver) or is_instance_valid(cargo_search_car):
		move = Vector2.ZERO
	if is_instance_valid(searching_driver) and searching_driver.search_ready and not inventory_view.visible:
		inventory_view.open_view(player_inventory, searching_car.inventory, searching_car.driver_name)
	if is_instance_valid(cargo_search_car) and not inventory_view.visible:
		cargo_search_clock = minf(Timings.VEHICLE_SEARCH, cargo_search_clock + delta)
		eyes.rotation.x = cargo_start_pitch + sin(cargo_search_clock / Timings.VEHICLE_SEARCH * PI) * 0.055
		if cargo_search_clock >= Timings.VEHICLE_SEARCH:
			eyes.rotation.x = cargo_start_pitch
			inventory_view.open_view(player_inventory, cargo_search_car.cargo_inventory, "Fahrzeug " + cargo_search_car.plate_number, "Fahrzeug " + cargo_search_car.plate_number, true)
	feedback_time = maxf(0, feedback_time - delta)
	if interaction_open and not can_interact():
		close_interaction()
	if aerial:
		var forward := -overview.global_basis.z
		forward.y = 0
		overview.position += (overview.global_basis.x * move.x - forward.normalized() * move.y) * delta * 20
		overview.position.x = clampf(overview.position.x, -10, 65)
		overview.position.z = clampf(overview.position.z, -15, 85)
		player.velocity.x = 0
		player.velocity.z = 0
	else:
		var direction := player.basis * Vector3(move.x, 0, move.y)
		var speed := (SpeedSettings.SPRINT_SPEED_KMH if Input.is_physical_key_pressed(KEY_CTRL) and equipment.state == equipment.State.HOLSTERED else SpeedSettings.WALK_SPEED_KMH) / 3.6
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
	if not player.is_on_floor():
		player.velocity.y -= 20 * delta
	else:
		player.velocity.y = 0
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -80, 80)
	player.position.z = clampf(player.position.z, -80, 80)
	refresh_encounter_ui()

func order_stop() -> void:
	if aerial:
		traffic.request_control()

func interaction_car() -> Node3D:
	# While a menu is open, retain its original subject.
	if interaction_open and is_instance_valid(menu_car):
		return menu_car
	var nearby := compliance.nearby_car()
	return nearby if is_instance_valid(nearby) else traffic.controlled_car

func can_interact() -> bool:
	var car := interaction_car()
	if equipment.state != equipment.State.HOLSTERED or document_mode.active or document_view.visible or radio_open or inventory_view.visible or is_instance_valid(searching_driver) or is_instance_valid(cargo_search_car) or aerial or not is_instance_valid(car) or car.state != TrafficCar.State.PARKED:
		return false
	if car.pickup_reserved and patrol.stage != PatrolDispatch.Stage.WAITING:
		return false
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or car.driver.is_busy():
		return false
	var outside: bool = car.driver.state == car.driver.State.OUTSIDE
	var target: Vector3 = car.driver.interaction_point() if outside else car.window_point.global_position
	var difference: Vector3 = target - eyes.global_position
	var facing := -eyes.global_basis.z
	return difference.length() < 2.2 and facing.dot(difference.normalized()) > 0.72 and (outside or car.to_local(player.global_position).x < -0.9)

func refresh_encounter_ui() -> void:
	update_part_focus()
	var searching := (is_instance_valid(searching_driver) or is_instance_valid(cargo_search_car)) and not inventory_view.visible
	search_progress.visible = searching
	search_progress.size = Vector2(120, 8)
	crosshair.visible = not searching and not inventory_view.visible and not radio_open and not document_view.visible and not aerial
	if searching:
		search_progress.value = (searching_driver.search_clock / searching_driver.SEARCH_DURATION if is_instance_valid(searching_driver) else cargo_search_clock / Timings.VEHICLE_SEARCH) * 100.0
	var selected := traffic.selected_car
	var controlled := traffic.controlled_car
	stop_button.visible = aerial and is_instance_valid(selected)
	stop_button.disabled = is_instance_valid(controlled) or not is_instance_valid(selected) or not selected.can_stop()
	interact_hint.text = "[E] Mit %s sprechen" % interaction_car().driver_name if can_interact() and not interaction_open else ""
	if is_instance_valid(hovered_part):
		interact_hint.text = "[E] Laderaum durchsuchen" if hovered_part.kind == "cargo" else "[E] %s %s" % [hovered_part.title, "schliessen" if hovered_part.opened else "oeffnen"]
	if climber.available():
		interact_hint.text += "\n[Leertaste] " + ("Heruntersteigen" if is_instance_valid(climber.car) else "Auf Ladeflaeche klettern")

	if is_instance_valid(compliance.nearby_car(true)):
		interact_hint.text = "[E] Handschellen anlegen"
	if feedback_time > 0:
		interact_hint.text += ("\n" if not interact_hint.text.is_empty() else "") + feedback


func open_interaction() -> void:
	if not can_interact():
		return
	menu_car = interaction_car()
	var driver = menu_car.driver
	if driver.arrested:
		interaction_actions.assign(["Gespraech beenden"] if menu_car.pickup_reserved else ["Person durchsuchen", "Festnahme aufheben", "Gespraech beenden", "Streife anfordern"])
	else:
		interaction_actions.assign(["Person durchsuchen", "Einsteigen lassen", "Gespraech beenden", "Weiterfahren lassen", "Festnehmen"] if driver.state == driver.State.OUTSIDE else ["Aussteigen lassen", "Weiterfahren lassen"])
	if driver.surrendered:
		interaction_actions.assign(["Handschellen anlegen", "Person durchsuchen", "Gespraech beenden"])
	if not menu_car.pickup_reserved:
		interaction_actions.append("Dokumente anfordern")
	interaction_index = 0
	interaction_open = true
	interaction_panel.visible = true
	refresh_interaction()

func close_interaction() -> void:
	interaction_open = false
	if is_instance_valid(interaction_panel):
		interaction_panel.visible = false

func refresh_interaction() -> void:
	var text := "AKTION WAEHLEN\n\n"
	for i in range(interaction_actions.size()):
		text += ("[color=#efd58b]>  " + interaction_actions[i] + "[/color]" if i == interaction_index else "    " + interaction_actions[i]) + "\n"
	text += "\nMausrad: Auswahl\nE: Bestaetigen  |  Esc: Zurueck"
	interaction_rows.text = text

func confirm_interaction() -> void:
	if not interaction_open or not can_interact():
		close_interaction()
		return
	var car := interaction_car()
	var action := interaction_actions[interaction_index]
	var succeeded := true
	match action:
		"Dokumente anfordern":
			succeeded = document_view.open_view(car)
		"Aussteigen lassen":
			succeeded = car.driver.request_exit()
		"Einsteigen lassen":
			car.depart_after_entry = false
			succeeded = car.driver.request_enter()
		"Weiterfahren lassen":
			succeeded = car.request_departure()
		"Handschellen anlegen":
			succeeded = car.driver.set_arrested(true)
		"Festnehmen":
			succeeded = car.driver.set_arrested(true)
			car.depart_after_entry = false
		"Festnahme aufheben":
			succeeded = not car.pickup_reserved and car.driver.set_arrested(false)
		"Streife anfordern":
			set_radio_open(true)
		"Person durchsuchen":
			succeeded = car.driver.begin_search()
			if succeeded:
				searching_driver = car.driver
				searching_car = car
	if not succeeded:
		feedback = "Bitte zuerst die Ladeflaeche verlassen." if car.officer_aboard else ("Bitte zuerst alle Tueren und Klappen schliessen." if not car.all_parts_closed() else "Aktion momentan nicht moeglich.")
		feedback_time = 6.0
	close_interaction()


func update_part_focus() -> void:
	var target: VehiclePart
	var car := traffic.controlled_car
	if equipment.state == equipment.State.HOLSTERED and not aerial and not interaction_open and not inventory_view.visible and not is_instance_valid(searching_driver) and not is_instance_valid(cargo_search_car) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_instance_valid(car) and car.state == TrafficCar.State.PARKED and not car.driver.is_busy():
		var origin := eyes.global_position
		var end := origin - eyes.global_basis.z * 2.8
		var query := PhysicsRayQueryParameters3D.create(origin, end, 8)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var part = hit.get("collider")
		if part is VehiclePart and part.vehicle == car and part.can_use(origin):
			# The coarse car body encloses empty cabin/trunk space. Exclude it,
			# use side checks above, and still respect other world obstacles.
			var blocked := PhysicsRayQueryParameters3D.create(origin, hit.position, 7)
			var ignored: Array[RID] = [car.get_rid(), player.get_rid()]
			for section in car.parts:
				ignored.append(section.pivot.get_rid())
			blocked.exclude = ignored
			if get_world_3d().direct_space_state.intersect_ray(blocked).is_empty():
				target = part
	if hovered_part != target:
		if is_instance_valid(hovered_part):
			hovered_part.set_highlight(false)
		hovered_part = target
		if is_instance_valid(hovered_part):
			hovered_part.set_highlight(true)


func finish_search() -> void:
	if is_instance_valid(cargo_search_car):
		cargo_search_car.cargo_search_active = false
		eyes.rotation.x = cargo_start_pitch
	cargo_search_car = null
	cargo_search_clock = 0
	if is_instance_valid(searching_driver):
		searching_driver.end_search()
	searching_driver = null
	searching_car = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if aerial else Input.MOUSE_MODE_CAPTURED


func begin_cargo_search(car: Node3D) -> bool:
	if aerial or inventory_view.visible or car != traffic.controlled_car or car.state != TrafficCar.State.PARKED or not car.cargo_accessible() or car.driver.is_busy() or not car.cargo_zone.can_use(eyes.global_position) or is_instance_valid(searching_driver) or is_instance_valid(cargo_search_car):
		return false
	close_interaction()
	cargo_search_car = car
	cargo_search_clock = 0
	cargo_start_pitch = eyes.rotation.x
	car.cargo_search_active = true
	return true

func refresh_cargo_visuals() -> void:
	for car in traffic.cars:
		car.refresh_cargo_props()


func set_radio_open(value: bool) -> void:
	if value:
		radio_car = interaction_car()
	radio_open = value
	if is_instance_valid(radio_panel):
		radio_panel.visible = value
	if is_instance_valid(radio_model):
		radio_model.visible = value and not aerial
	if value:
		close_interaction()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value or aerial else Input.MOUSE_MODE_CAPTURED

func update_radio() -> void:
	if not is_instance_valid(radio_status):
		return
	radio_status.text = patrol.report + "\n" + patrol.display_text().replace("\n", " / ")
	radio_model.get_meta("screen").text = patrol.display_text()
	var car := radio_car if radio_open and is_instance_valid(radio_car) else interaction_car()
	radio_call_button.disabled = patrol.active() or not is_instance_valid(car) or not car.driver.arrested or car.driver.state != car.driver.State.OUTSIDE or car.officer_aboard or car.cargo_search_active
	radio_cancel_button.visible = patrol.stage == PatrolDispatch.Stage.WAITING

func call_patrol() -> void:
	patrol.request_pickup(radio_car if is_instance_valid(radio_car) else interaction_car())
	update_radio()
