extends Node
const Models = preload("res://game/weapons/weapon_visuals.gd")
const Visuals = preload("res://game/police/police_visuals.gd")
enum State { HOLSTERED, REACHING, AIMING }
const IDS := ["player:pistol", "player:taser"]
const KINDS := ["pistol", "taser"]
const NAMES := ["Glock 19", "Taser"]
var scene: Node3D
var selected := 0
var state: State = State.HOLSTERED
var shift_held := false
var aim_held := false
var reach := 0.0
var draw := 0.0
var hand: Node3D
var hand_guns: Array[Node3D] = []
var belt_guns: Array[Node3D] = []
var buttons: Array[Button] = []
var bar: HBoxContainer
const PistolAction = preload("res://game/weapons/pistol_action.gd")
var pistol_action: PistolAction
var busy := false

func _ready() -> void:
	for i in range(2):
		var holster := Node3D.new()
		scene.player_avatar.add_child(holster)
		holster.position = Vector3(0.30 if i == 0 else -0.30, 0.84, 0.04)
		Visuals.box(holster, Vector3(0, -0.035, 0), Vector3(0.07, 0.13, 0.09), "18232b")
		var gun: Node3D = Models.build(holster, KINDS[i])
		gun.position.y = 0.08
		gun.rotation.x = -PI / 2
		belt_guns.append(gun)
	hand = Node3D.new()
	scene.eyes.add_child(hand)
	var sleeve := Visuals.box(hand, Vector3(0.035, -0.10, 0.15), Vector3(0.085, 0.09, 0.27), "365a78")
	sleeve.rotation.x = -0.15
	Visuals.box(hand, Vector3(0, -0.04, 0.045), Vector3(0.055, 0.075, 0.07), "d7b49a")
	for kind in KINDS:
		hand_guns.append(Models.build(hand, kind))
	bar = HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -154
	bar.offset_right = 154
	bar.offset_top = -68
	bar.offset_bottom = -14
	bar.add_theme_constant_override("separation", 8)
	scene.ui_layer.add_child(bar)
	for i in range(2):
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 54)
		button.focus_mode = Control.FOCUS_NONE
		button.icon = load("res://assets/items/" + KINDS[i] + ".svg")
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 45)
		button.pressed.connect(select.bind(i))
		bar.add_child(button)
		buttons.append(button)
	pistol_action = PistolAction.new()
	pistol_action.scene = scene
	pistol_action.equipment = self
	add_child(pistol_action)
	pistol_action.sync_descriptions()
	tick(0)

func available(index: int) -> bool:
	for item in scene.player_inventory.items:
		if item.id == IDS[index]:
			return true
	return false

func allowed() -> bool:
	return not scene.aerial and not scene.interaction_open and not scene.radio_open and not scene.inventory_view.visible and not scene.document_mode.active and not scene.document_view.visible and not is_instance_valid(scene.searching_driver) and not is_instance_valid(scene.cargo_search_car) and not scene.climber.active and not is_instance_valid(scene.climber.car)

func cancel() -> void:
	if is_instance_valid(pistol_action):
		pistol_action.cancel_reload()
	state = State.HOLSTERED
	shift_held = false
	aim_held = false
	reach = 0
	draw = 0

func select(index: int) -> void:
	if index < 0 or index >= 2 or not available(index):
		return
	cancel()
	selected = index

func handle(event: InputEvent) -> bool:
	if not allowed():
		cancel()
		return false
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT:
			shift_held = event.pressed
			if shift_held and state == State.HOLSTERED and available(selected) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				state = State.REACHING
			elif not shift_held and state == State.REACHING:
				cancel()
			return true
		if event.pressed and not event.echo:
			if event.keycode in [KEY_1, KEY_2]:
				select(0 if event.keycode == KEY_1 else 1)
				return true
			if event.keycode == KEY_R:
				pistol_action.start_reload()
				return true
			if event.keycode == KEY_E and state != State.HOLSTERED:
				return true
			if event.keycode in [KEY_TAB, KEY_T, KEY_I, KEY_SPACE, KEY_ESCAPE]:
				cancel()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and state == State.REACHING and shift_held:
				aim_held = true
				if reach >= 0.9:
					state = State.AIMING
			elif not event.pressed:
				if state == State.AIMING:
					state = State.REACHING if shift_held else State.HOLSTERED
				aim_held = false
			return true
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			select(1 - selected)
			return true
		if event.button_index == MOUSE_BUTTON_LEFT and state != State.HOLSTERED:
			if event.pressed:
				pistol_action.fire()
			return true
	return false

func tick(delta: float) -> void:
	if not allowed() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or not available(selected):
		cancel()
	reach = move_toward(reach, 1.0 if state != State.HOLSTERED else 0.0, delta * 5)
	if state == State.REACHING and reach >= 0.9 and aim_held and shift_held:
		state = State.AIMING
	draw = move_toward(draw, 1.0 if state == State.AIMING else 0.0, delta * 4)
	pistol_action.tick(delta)
	hand.visible = allowed() and (reach > 0.01 or draw > 0.01)
	hand.position = Vector3(0.31, -0.31, -0.46).lerp(Vector3(0, -0.05, -0.48), draw)
	hand.rotation.x = lerpf(-0.65, 0.0, draw) + pistol_action.recoil * 0.1
	hand.position.z += pistol_action.recoil * 0.035
	if pistol_action.reloading:
		var dip := sin(clampf(pistol_action.reload_clock / pistol_action.RELOAD_SECONDS, 0, 1) * PI)
		hand.position.y -= dip * 0.18
		hand.rotation.z = dip * -0.5
	else:
		hand.rotation.z = 0
	for i in range(2):
		hand_guns[i].visible = i == selected and draw > 0.01
		belt_guns[i].visible = available(i) and not (i == selected and draw > 0.01)
		var arm: Node3D = scene.player_avatar.get_node("Arm" + str(i))
		arm.rotation.x = -1.3 * draw - 0.22 * reach if i == 1 else -0.6 * draw
		arm.rotation.z = -0.30 * reach if i == 1 and selected == 1 else 0.0
		buttons[i].text = str(i + 1) + "  " + NAMES[i] + ("\nZielen" if i == selected and state == State.AIMING else "\nGriff" if i == selected and state == State.REACHING else "\nHolster")
		if i == 0:
			buttons[i].text = "1  Glock 19\n" + ("Nachladen ..." if pistol_action.reloading else "%d/15 | %d Mag." % [pistol_action.rounds(), pistol_action.spare_count()])
		buttons[i].modulate = Color("efd58b") if i == selected else Color("b5c0c5")
		buttons[i].disabled = not available(i)
	bar.visible = not scene.aerial and not scene.inventory_view.visible and not scene.radio_open and not scene.interaction_open and not scene.document_mode.active
	busy = state != State.HOLSTERED

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel()
