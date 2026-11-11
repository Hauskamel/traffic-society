extends "res://main.gd"
## Isolated first-person scenario; main gameplay keeps R for reload.
const Health = preload("res://scripts/player_health.gd")
const Gunfight = preload("res://scripts/npc_gunfight.gd")
const SLOW_SPEED := .22
const REACTION_SECONDS := 2.0
var health: Node
var combat: Node
var test_car: Node3D
var reaction_remaining := 0.0
var previous_speed := 1.0
var slowing := false
var health_bar: ProgressBar
var test_status: Label
var damage_overlay: ColorRect
var slow_filter: ColorRect
func _ready() -> void:
	super._ready()
	traffic.set_physics_process(false)
	test_car = traffic.cars[0]
	for i in range(traffic.cars.size()-1,0,-1):
		var other = traffic.cars.pop_back()
		other.free()
	test_car.driver_name = "Testfahrer"
	test_car.position = Vector3(7.1,.08,5)
	test_car.state = test_car.State.PARKED
	test_car.speed = 0
	test_car.driver.reset()
	traffic.controlled_car = test_car
	traffic.selected_car = null
	aerial = false
	player.position = Vector3(4.4,.05,7.0)
	var target: Vector3 = test_car.window_point.global_position
	var offset: Vector3 = target-eyes.global_position
	player.rotation.y = atan2(-offset.x,-offset.z)
	pitch = atan2(offset.y,Vector2(offset.x,offset.z).length())
	eyes.rotation.x = pitch
	update_camera()
	health = Health.new()
	add_child(health)
	health.died.connect(on_player_died)
	combat = Gunfight.new()
	combat.scene = self
	combat.driver = test_car.driver
	test_car.driver.combat = combat
	test_car.driver.add_child(combat)
	build_test_ui()
	equipment.tick(0)
	refresh_encounter_ui()
	_process(0)
func build_test_ui() -> void:
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(24,24)
	health_bar.size = Vector2(210,26)
	health_bar.value = 100
	ui_layer.add_child(health_bar)
	test_status = Label.new()
	test_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	test_status.offset_top = 62
	test_status.offset_bottom = 120
	test_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(test_status)
	damage_overlay = ColorRect.new()
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.color = Color(1,.06,.03,0)
	ui_layer.add_child(damage_overlay)
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	slow_filter = ColorRect.new()
	slow_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slow_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, filter_linear; void fragment(){ vec4 c=texture(screen_texture,SCREEN_UV); float g=dot(c.rgb,vec3(.299,.587,.114)); COLOR=vec4(mix(c.rgb,vec3(g)*vec3(.94,.98,1.04),.65),1.0); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	slow_filter.material = material
	layer.add_child(slow_filter)
	slow_filter.hide()
func begin_reaction_window() -> void:
	if slowing or health.dead: return
	previous_speed = Engine.time_scale
	slowing = true
	reaction_remaining = REACTION_SECONDS
	Engine.time_scale = previous_speed*SLOW_SPEED
	slow_filter.show()
func end_reaction_window() -> void:
	if not slowing: return
	Engine.time_scale = previous_speed
	slowing = false
	reaction_remaining = 0
	if is_instance_valid(slow_filter): slow_filter.hide()
func advance_reaction(real_delta: float) -> void:
	if slowing:
		reaction_remaining -= real_delta
		if reaction_remaining <= 0: end_reaction_window()
func _process(delta: float) -> void:
	if not is_instance_valid(health): return
	advance_reaction(delta/maxf(Engine.time_scale,.001))
	health_bar.value = health.value
	damage_overlay.color.a = .18 if health.dead else health.hit_feedback*.18
	test_status.text = ("Du bist kampfunfaehig." if health.dead else combat.report)+"\n[R] Ganze Szene neu starten   [F] Nachladen   [F10] Zum Spiel"
func _physics_process(delta: float) -> void:
	if not is_instance_valid(health): return
	if health.dead:
		player.velocity = Vector3.ZERO
		return
	# Drawing/reloading the player's weapon remains responsive in real time.
	if slowing: equipment.tick(delta*(1.0/maxf(Engine.time_scale,.001)-1.0))
	super._physics_process(delta)
func on_player_died() -> void:
	end_reaction_window()
	equipment.cancel()
	equipment.tick(0)
	equipment.hand.hide()
	crosshair.hide()
	close_interaction()
	player.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func reset_scenario() -> void:
	end_reaction_window()
	get_tree().reload_current_scene()
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			reset_scenario()
		elif event.keycode == KEY_F10:
			get_viewport().set_input_as_handled()
			end_reaction_window()
			get_tree().change_scene_to_file("res://main.tscn")
func _unhandled_input(event: InputEvent) -> void:
	if health.dead: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_TAB,KEY_T,KEY_I,KEY_SPACE,KEY_F9]: return
		if event.keycode == KEY_F:
			equipment.pistol_action.start_reload()
			return
		if event.keycode == KEY_E and test_car.driver.state == test_car.driver.State.SEATED:
			if eyes.global_position.distance_to(test_car.window_point.global_position)<3:
				test_car.driver.request_exit()
			return
		if event.keycode == KEY_E:
			if combat.phase == combat.Phase.SURRENDERED:
				var target: Vector3 = test_car.driver.physical_actor.bodies.pelvis.global_position if test_car.driver.is_injured() else test_car.driver.global_position
				if player.global_position.distance_to(target)<2.3:
					equipment.cancel()
					if test_car.driver.is_injured():
						test_car.driver.arrested = true
					else:
						test_car.driver.set_arrested(true)
					combat.report = "Person entwaffnet und gesichert."
			return
	super._unhandled_input(event)
func _exit_tree() -> void:
	end_reaction_window()

func update_part_focus() -> void:
	# The isolated encounter has only exit/cuff interactions.
	if is_instance_valid(hovered_part): hovered_part.set_highlight(false)
	hovered_part = null

func refresh_encounter_ui() -> void:
	super.refresh_encounter_ui()
	if not is_instance_valid(combat): return
	interact_hint.text = "[E] Fahrer aussteigen lassen" if combat.phase == combat.Phase.SEATED else ""
	if combat.phase == combat.Phase.SURRENDERED and not test_car.driver.arrested:
		interact_hint.text = "[E] Handschellen anlegen (nahe herangehen)"
