extends Node3D

const SpeedSettings = preload("res://scripts/speed_settings.gd")

var player: CharacterBody3D
var eyes: Camera3D
var overview: Camera3D
var aerial := true
var pitch := 0.0
var title: Label
var instructions: Label
const TrafficCar = preload("res://scripts/traffic_car.gd")
const TrafficManager = preload("res://scripts/traffic_manager.gd")
var traffic: TrafficManager
var encounter_status: Label
var interact_hint: Label
var stop_button: Button
var interaction_open := false
var interaction_index := 0
var interaction_actions: Array[String] = []
var interaction_panel: PanelContainer
var interaction_rows: RichTextLabel
const VehiclePart = preload("res://scripts/vehicle_part.gd")
var hovered_part: VehiclePart
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
	player.rotation.y = PI / 2

	overview = Camera3D.new()
	overview.projection = Camera3D.PROJECTION_ORTHOGONAL
	overview.size = 65
	overview.position = Vector3(35, 52, 50)
	add_child(overview)
	overview.look_at(Vector3(2, 0, 12))

	traffic = TrafficManager.new()
	add_child(traffic)

	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	stack.add_child(title)
	instructions = Label.new()
	instructions.add_theme_font_size_override("font_size", 15)
	stack.add_child(instructions)
	encounter_status = Label.new()
	encounter_status.add_theme_color_override("font_color", Color("efd58b"))
	stack.add_child(encounter_status)
	stop_button = Button.new()
	stop_button.text = "Zur Kontrolle anhalten"
	stop_button.focus_mode = Control.FOCUS_NONE
	stop_button.pressed.connect(order_stop)
	stack.add_child(stop_button)
	interact_hint = Label.new()
	stack.add_child(interact_hint)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(5, 12)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
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
	update_camera()
	refresh_encounter_ui()

func update_camera() -> void:
	close_interaction()
	overview.current = aerial
	eyes.current = not aerial
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if aerial else Input.MOUSE_MODE_CAPTURED
	title.text = "KONTROLLPUNKT  /  " + ("UEBERSICHT" if aerial else "EGO-ANSICHT")
	instructions.text = "TAB: Ansicht wechseln | WASD / Pfeile: bewegen\n"
	instructions.text += "Auto auswaehlen, dann Anhalten | Mausrad: Zoom\nR: Spieler zuruecksetzen" if aerial else "Maus: umsehen | Shift: schneller | E: interagieren\nEsc: Maus freigeben | R: Spieler zuruecksetzen"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			aerial = not aerial
			update_camera()
		elif event.keycode == KEY_E:
			update_part_focus()
			if interaction_open:
				confirm_interaction()
			elif is_instance_valid(hovered_part):
				hovered_part.toggle()
			elif can_interact():
				open_interaction()
		elif event.keycode == KEY_ESCAPE:
			if interaction_open:
				close_interaction()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_R:
			close_interaction()
			player.position = Vector3(7.5, 0.2, 8)
			player.velocity = Vector3.ZERO
			player.rotation.y = PI / 2
			pitch = 0
			eyes.rotation.x = 0
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
	if event is InputEventMouseMotion and not aerial and not interaction_open and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotation.y -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.35, 1.35)
		eyes.rotation.x = pitch

func held(a: int, b: int) -> float:
	return 1.0 if Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b) else 0.0

func _physics_process(delta: float) -> void:
	var move := Vector2(
		held(KEY_D, KEY_RIGHT) - held(KEY_A, KEY_LEFT),
		held(KEY_S, KEY_DOWN) - held(KEY_W, KEY_UP)
	).normalized()
	if interaction_open:
		move = Vector2.ZERO
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
		var speed := (SpeedSettings.SPRINT_SPEED_KMH if Input.is_physical_key_pressed(KEY_SHIFT) else SpeedSettings.WALK_SPEED_KMH) / 3.6
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

func can_interact() -> bool:
	var car := traffic.controlled_car
	if aerial or not is_instance_valid(car) or car.state != TrafficCar.State.PARKED:
		return false
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or car.driver.is_busy():
		return false
	var outside: bool = car.driver.state == car.driver.State.OUTSIDE
	var target := car.driver.interaction_point() if outside else car.window_point.global_position
	var difference := target - eyes.global_position
	var facing := -eyes.global_basis.z
	return difference.length() < 2.2 and facing.dot(difference.normalized()) > 0.72 and (outside or car.to_local(player.global_position).x < -0.9)

func refresh_encounter_ui() -> void:
	update_part_focus()
	var selected := traffic.selected_car
	var controlled := traffic.controlled_car
	stop_button.visible = aerial and is_instance_valid(selected)
	stop_button.disabled = is_instance_valid(controlled) or not is_instance_valid(selected) or not selected.can_stop()
	var text := "VERKEHR  |  %d Fahrzeuge\n" % traffic.cars.size()
	if is_instance_valid(controlled):
		text += "Kontrolle: %s | %s\n" % [controlled.driver_name, controlled.model_name]
		match controlled.state:
			TrafficCar.State.PULLING_OVER:
				text += "Faehrt in die Parkbucht. Weitere Fahrzeuge fahren vorbei."
			TrafficCar.State.PARKED:
				text += "TAB: vor Ort gehen. Mit E am Fenster oder Fahrer interagieren." if aerial else "Am Fahrerfenster oder beim Fahrer mit E interagieren."
			TrafficCar.State.LEAVING:
				text += "Fahrzeug faehrt ab. Sobald der Stellplatz frei ist, ist die naechste Kontrolle moeglich."
	else:
		text += "Bucht frei. Kein Fahrzeug haelt ohne deinen Anhalteauftrag."
	if is_instance_valid(selected):
		text += "\nAuswahl: %s | %s | %s\n" % [selected.driver_name, selected.model_name, selected.plate_number]
		text += "Bucht belegt: erst die laufende Kontrolle abschliessen." if is_instance_valid(controlled) else ("Jetzt 'Zur Kontrolle anhalten' waehlen." if selected.can_stop() else "Einfahrt bereits passiert. Ein anderes Fahrzeug auswaehlen.")
	elif not is_instance_valid(controlled) and aerial:
		text += "\nIn der Uebersicht ein vorbeifahrendes Fahrzeug anklicken."
	if is_instance_valid(controlled) and controlled.driver.is_busy():
		text += "\nFahrer steigt aus ..." if controlled.driver.state == controlled.driver.State.EXITING else "\nFahrer steigt ein ..."
	if feedback_time > 0:
		text += "\n" + feedback
	encounter_status.text = text
	interact_hint.text = "[E] Mit %s sprechen" % controlled.driver_name if can_interact() and not interaction_open else ""
	if is_instance_valid(hovered_part):
		interact_hint.text = "[E] %s %s" % [hovered_part.title, "schliessen" if hovered_part.opened else "oeffnen"]


func open_interaction() -> void:
	if not can_interact():
		return
	var driver := traffic.controlled_car.driver
	interaction_actions.assign(["Einsteigen lassen", "Gespraech beenden"] if driver.state == driver.State.OUTSIDE else ["Aussteigen lassen", "Weiterfahren lassen"])
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
	var car := traffic.controlled_car
	var action := interaction_actions[interaction_index]
	var succeeded := true
	match action:
		"Aussteigen lassen":
			succeeded = car.driver.request_exit()
		"Einsteigen lassen":
			succeeded = car.driver.request_enter()
		"Weiterfahren lassen":
			succeeded = car.release()
	if not succeeded:
		feedback = "Bitte zuerst alle Tueren und Klappen schliessen." if not car.all_parts_closed() else "Aktion momentan nicht moeglich."
		feedback_time = 6.0
	close_interaction()


func update_part_focus() -> void:
	var target: VehiclePart
	var car := traffic.controlled_car
	if not aerial and not interaction_open and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_instance_valid(car) and car.state == TrafficCar.State.PARKED and not car.driver.is_busy():
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
