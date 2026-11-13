## Isoliertes Vergleichslabor für stehende und laufende Physikfiguren.
## Region, Impuls und Kraftverlust sind reproduzierbar über die Oberfläche einstellbar.

extends Node3D
const Actor = preload("res://game/actors/physics/active_body.gd")
const Visuals = preload("res://game/police/police_visuals.gd")
const REGIONS := [
	"left_thigh",
	"right_thigh",
	"left_shin",
	"right_shin",
	"left_upper_arm",
	"right_upper_arm",
	"left_forearm",
	"right_forearm",
	"torso",
	"head",
	"pelvis"
]
const NAMES := [
	"Linker Oberschenkel",
	"Rechter Oberschenkel",
	"Linker Unterschenkel + Fuss",
	"Rechter Unterschenkel + Fuss",
	"Linker Oberarm",
	"Rechter Oberarm",
	"Linker Unterarm + Hand",
	"Rechter Unterarm + Hand",
	"Rumpf",
	"Kopf",
	"Becken"
]
var actors: Array[Node3D] = []
var camera: Camera3D
var region: OptionButton
var strength_slider: HSlider
var injury_slider: HSlider
var status: Label
var yaw := .35
var elevation := .36
var distance := 10.0
var orbiting := false
var last_report := "Noch kein Treffer."


## Erzeugt Laborboden, Beleuchtung, Vergleichsfiguren und Bedienelemente.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263b48")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dce3e3")
	settings.ambient_light_energy = .65
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var floor := StaticBody3D.new()
	add_child(floor)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(18, .2, 18)
	collision.shape = box
	collision.position.y = -.1
	floor.add_child(collision)
	Visuals.box(floor, Vector3(0, -.1, 0), box.size, "657876")
	for x in [-2.2, 2.2]:
		Visuals.box(self, Vector3(x, .003, -.7), Vector3(2.3, .006, 5.5), "7d8981")
		var sign := Label3D.new()
		sign.text = "STEHEND" if x < 0 else "IN BEWEGUNG"
		sign.position = Vector3(x, .012, 2.5)
		sign.rotation_degrees.x = -90
		sign.pixel_size = .006
		add_child(sign)
	camera = Camera3D.new()
	camera.fov = 50
	add_child(camera)
	camera.make_current()
	update_camera()
	build_ui()
	reset_actors()


## Erzeugt eine Schaltfläche und verbindet ihre Aktion mit dem Callback.
func button(text: String, parent: Node, action: Callable) -> void:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.pressed.connect(action)
	parent.add_child(node)


## Baut die Bedienelemente des Vergleichslabors auf.
func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = 310
	margin.add_child(stack)
	var title := Label.new()
	title.text = "KOERPERPHYSIK / TESTLABOR"
	stack.add_child(title)
	region = OptionButton.new()
	for name in NAMES:
		region.add_item(name)
	region.focus_mode = Control.FOCUS_NONE
	stack.add_child(region)
	var help := Label.new()
	help.text = "Linksklick auf Koerper: Impulstreffer\nLeertaste: gleiche Region bei beiden\nRechts ziehen: Kamera | Mausrad: Zoom"
	stack.add_child(help)
	var force_label := Label.new()
	force_label.text = "Testimpuls (keine ballistische Simulation)"
	stack.add_child(force_label)
	strength_slider = HSlider.new()
	strength_slider.min_value = .5
	strength_slider.max_value = 5
	strength_slider.step = .5
	strength_slider.value = Actor.DEFAULT_IMPULSE
	force_label.text = "Testimpuls: %.1f N s (keine Ballistik)" % strength_slider.value
	strength_slider.value_changed.connect(
		func(value: float): force_label.text = "Testimpuls: %.1f N s (keine Ballistik)" % value
	)
	stack.add_child(strength_slider)
	var injury_label := Label.new()
	injury_label.text = "Lokaler Kraftverlust: 95 %"
	stack.add_child(injury_label)
	injury_slider = HSlider.new()
	injury_slider.min_value = .1
	injury_slider.max_value = .95
	injury_slider.step = .05
	injury_slider.value = Actor.DEFAULT_STRENGTH_LOSS
	injury_slider.value_changed.connect(
		func(value: float): injury_label.text = "Lokaler Kraftverlust: %.0f %%" % (value * 100)
	)
	stack.add_child(injury_slider)
	button("Vergleichstreffer [Leertaste]", stack, comparison_hit)
	button("Beide zuruecksetzen [R]", stack, reset_actors)
	button("Zum Spiel / neue Sitzung [F9]", stack, return_to_game)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(status)


## Ersetzt beide Laborfiguren durch unverletzte Körper im definierten Ausgangszustand.
func reset_actors() -> void:
	for actor in actors:
		remove_child(actor)
		actor.queue_free()
	actors.clear()
	for i in range(2):
		var actor := Actor.new()
		actor.position = Vector3(-2.2 if i == 0 else 2.2, 0, 0)
		actor.moving = i == 1
		add_child(actor)
		actors.append(actor)
	last_report = "Gleiche Koerper, unterschiedliche Bewegung."


## Gibt beiden Laborfiguren denselben Treffer an der ausgewählten Körperregion.
func comparison_hit() -> void:
	var target: String = REGIONS[region.selected]
	var speeds: Array[float] = []
	for actor in actors:
		var body: RigidBody3D = actor.bodies[target]
		speeds.append(body.linear_velocity.length())
		actor.receive_hit(
			target, body.global_position, Vector3(0, 0, -strength_slider.value), injury_slider.value
		)
	last_report = (
		"%s\nSegmenttempo beim Treffer: %.2f / %.2f m/s"
		% [NAMES[region.selected], speeds[0], speeds[1]]
	)


## Übernimmt die aktuellen Kamera- und Perspektivparameter.
func update_camera() -> void:
	camera.position = (
		Vector3(sin(yaw) * cos(elevation), sin(elevation), cos(yaw) * cos(elevation)) * distance
		+ Vector3(0, .8, -.8)
	)
	camera.look_at(Vector3(0, .85, -.8))


## Verarbeitet nicht von UI-Elementen verbrauchte Tastatur- und Mausaktionen dieser Szene.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				comparison_hit()
			KEY_R:
				reset_actors()
			KEY_F9:
				return_to_game()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(
				distance + (-.7 if event.button_index == MOUSE_BUTTON_WHEEL_UP else .7), 4, 17
			)
			update_camera()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var start := camera.project_ray_origin(event.position)
			var query := PhysicsRayQueryParameters3D.create(
				start, start + camera.project_ray_normal(event.position) * 40, 4
			)
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and hit.collider.has_meta("actor"):
				var actor = hit.collider.get_meta("actor")
				var target: String = hit.collider.get_meta("region")
				actor.receive_hit(
					target,
					hit.position,
					camera.project_ray_normal(event.position) * strength_slider.value,
					injury_slider.value
				)
				var index := REGIONS.find(target)
				last_report = "Angeklickter Treffer: " + (NAMES[index] if index >= 0 else target)
	if event is InputEventMouseMotion and orbiting:
		yaw -= event.relative.x * .006
		elevation = clampf(elevation + event.relative.y * .004, .12, 1.0)
		update_camera()


## Aktualisiert die gemessenen Körper- und Verletzungszustände der Laboranzeige.
func _process(_delta: float) -> void:
	if actors.size() == 2:
		status.text = (
			last_report
			+ (
				"\nBeckenhoehe: %.2f / %.2f m\nBalancehilfe: %.0f / %.0f %%"
				% [
					actors[0].bodies.pelvis.global_position.y,
					actors[1].bodies.pelvis.global_position.y,
					actors[0].balance * 100,
					actors[1].balance * 100
				]
			)
		)

		var states: Array[String] = []
		for actor in actors:
			states.append(
				"Tot" if actor.dead else ("Zusammengebrochen" if actor.collapsed else "Aktiv")
			)
		status.text += "\nZustand: " + " / ".join(states)


## Verlässt das Labor und startet eine neue Hauptspiel-Sitzung.
func return_to_game() -> void:
	get_tree().change_scene_to_file("res://game/world/main.tscn")
