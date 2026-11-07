extends Node3D

var player: CharacterBody3D
var eyes: Camera3D
var overview: Camera3D
var aerial := true
var pitch := 0.0
var title: Label
var instructions: Label
const TrafficCar = preload("res://scripts/traffic_car.gd")
var car: TrafficCar
var encounter_status: Label
var interact_hint: Label
var stop_button: Button
var new_drive_button: Button

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
	player.collision_mask = 3
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

	car = TrafficCar.new()
	add_child(car)

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
	new_drive_button = Button.new()
	new_drive_button.text = "Neue Testfahrt [N]"
	new_drive_button.focus_mode = Control.FOCUS_NONE
	new_drive_button.pressed.connect(new_test_drive)
	stack.add_child(new_drive_button)
	interact_hint = Label.new()
	stack.add_child(interact_hint)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(5, 12)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
	update_camera()
	refresh_encounter_ui()

func update_camera() -> void:
	overview.current = aerial
	eyes.current = not aerial
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if aerial else Input.MOUSE_MODE_CAPTURED
	title.text = "KONTROLLPUNKT  /  " + ("UEBERSICHT" if aerial else "EGO-ANSICHT")
	instructions.text = "TAB: Ansicht wechseln | WASD / Pfeile: bewegen\n"
	instructions.text += "Auto anklicken: anhalten | Mausrad: Zoom\nR: Spieler zuruecksetzen" if aerial else "Maus: umsehen | Shift: schneller | E: interagieren\nEsc: Maus freigeben | R: Spieler zuruecksetzen"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			aerial = not aerial
			update_camera()
		elif event.keycode == KEY_E and can_release():
			car.release()
		elif event.keycode == KEY_N:
			new_test_drive()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_R:
			player.position = Vector3(7.5, 0.2, 8)
			player.velocity = Vector3.ZERO
			player.rotation.y = PI / 2
			pitch = 0
			eyes.rotation.x = 0
	if event is InputEventMouseButton and event.pressed:
		if aerial:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var origin := overview.project_ray_origin(event.position)
				var end := origin + overview.project_ray_normal(event.position) * 250.0
				var query := PhysicsRayQueryParameters3D.create(origin, end, 2)
				var result := get_world_3d().direct_space_state.intersect_ray(query)
				if result.get("collider") == car:
					order_stop()
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				overview.size = maxf(20, overview.size - 3)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				overview.size = minf(85, overview.size + 3)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and not aerial and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
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
		var speed := 6.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 3.5
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
		car.request_stop()

func new_test_drive() -> void:
	if car.state == TrafficCar.State.FINISHED:
		car.new_test_drive()

func can_release() -> bool:
	if aerial or car.state != TrafficCar.State.PARKED:
		return false
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false
	var target := car.window_point.global_position
	var difference := target - eyes.global_position
	var facing := -eyes.global_basis.z
	return difference.length() < 2.2 and facing.dot(difference.normalized()) > 0.72 and car.to_local(player.global_position).x < -0.9

func refresh_encounter_ui() -> void:
	stop_button.visible = aerial and car.state == TrafficCar.State.DRIVING
	stop_button.disabled = not car.can_stop()
	new_drive_button.visible = car.state == TrafficCar.State.FINISHED
	var heading := "Bobby Mayer  |  TS BM 104\n"
	match car.state:
		TrafficCar.State.DRIVING:
			encounter_status.text = heading + ("Fahrzeug unterwegs: zur Kontrolle auswaehlen." if car.can_stop() else "Einfahrt passiert. Nach der Abfahrt neue Testfahrt starten.")
		TrafficCar.State.PULLING_OVER:
			encounter_status.text = heading + "Kontrolle angefordert. Fahrzeug faehrt in die Parkbucht."
		TrafficCar.State.PARKED:
			encounter_status.text = heading + ("Fahrzeug steht. Mit TAB vor Ort gehen und zum linken Fahrerfenster laufen." if aerial else "Fahrzeug steht. Zum linken Fahrerfenster gehen und hineinschauen.")
		TrafficCar.State.LEAVING:
			encounter_status.text = heading + "Kontrolle beendet. Fahrzeug faehrt zurueck auf die Strasse."
		TrafficCar.State.FINISHED:
			encounter_status.text = "Testfahrt beendet. Neue Testfahrt mit N starten."
	interact_hint.text = "[E] Bobby Mayer weiterfahren lassen" if can_release() else ""
