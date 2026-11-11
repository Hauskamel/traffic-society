extends Node
## Hitscan with vehicle damage and articulated regional NPC injuries.
const CAPACITY := 15
const RELOAD_SECONDS := 1.8
const SHOT_INTERVAL := 0.16
var equipment: Node
var scene: Node3D
var cooldown := 0.0
var reload_clock := 0.0
var reloading := false
var pending_id := ""
var recoil := 0.0
var flash_clock := 0.0
var shots_fired := 0
var last_hit: Dictionary = {}
var flash: MeshInstance3D
var light: OmniLight3D
var reload_hand: Node3D
var sound: AudioStreamPlayer3D
var click: AudioStreamPlayer3D

func _ready() -> void:
	flash = MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.022
	shape.height = 0.08
	flash.mesh = shape
	flash.rotation.x = PI / 2
	flash.position = Vector3(0, 0.023, -0.16)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffe8a0")
	flash.material_override = material
	equipment.hand_guns[0].add_child(flash)
	flash.hide()
	reload_hand = Node3D.new()
	equipment.hand.add_child(reload_hand)
	var visuals = preload("res://scripts/police_visuals.gd")
	visuals.box(reload_hand, Vector3(-0.07, -0.03, 0.08), Vector3(0.065, 0.07, 0.15), "365a78")
	visuals.box(reload_hand, Vector3.ZERO, Vector3(0.06, 0.06, 0.07), "d7b49a")
	visuals.box(reload_hand, Vector3(0.025, 0.01, 0), Vector3(0.03, 0.08, 0.035), "29333b")
	reload_hand.hide()
	light = OmniLight3D.new()
	light.omni_range = 2.0
	light.light_color = Color("ffd290")
	light.light_energy = 1.4
	flash.add_child(light)
	sound = AudioStreamPlayer3D.new()
	sound.stream = preload("res://assets/audio/pistol.wav")
	sound.volume_db = -12
	scene.player.add_child(sound)
	click = AudioStreamPlayer3D.new()
	click.stream = preload("res://assets/audio/weapon_click.wav")
	click.volume_db = -16
	scene.player.add_child(click)

func pistol() -> Dictionary:
	for item in scene.player_inventory.items:
		if item.id == "player:pistol":
			return item
	return {}

func rounds() -> int:
	var item := pistol()
	return int(item.get("loaded_magazine", {}).get("rounds", 0))

func spare_count() -> int:
	var count := 0
	for item in scene.player_inventory.items:
		if item.get("icon") == "magazine":
			count += 1
	return count

func total_rounds() -> int:
	var count := rounds()
	for item in scene.player_inventory.items:
		if item.get("icon") == "magazine":
			count += int(item.rounds)
	return count

func can_use() -> bool:
	return equipment.allowed() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and equipment.selected == 0 and equipment.state == equipment.State.AIMING and equipment.draw >= 0.95 and equipment.available(0)

func message(text: String) -> void:
	scene.feedback = text
	scene.feedback_time = 2.0

func fire() -> bool:
	if not can_use() or reloading or cooldown > 0:
		return false
	cooldown = SHOT_INTERVAL
	if rounds() <= 0:
		click.play()
		message("Magazin leer. [R] Nachladen")
		return false
	var item := pistol()
	item.loaded_magazine.rounds -= 1
	sync_descriptions()
	shots_fired += 1
	recoil = 1.0
	flash_clock = 0.055
	flash.show()
	sound.play()
	cast_shot()
	return true

func exclude_vehicle_motion(node: Node, driver: Node, ignored: Array[RID]) -> void:
	if node == driver or node.is_in_group("shootable_drivers"):
		return
	if node is CollisionObject3D and node.collision_layer != 16:
		ignored.append(node.get_rid())
	for child in node.get_children():
		exclude_vehicle_motion(child, driver, ignored)

func shot_query(start: Vector3, end: Vector3) -> Dictionary:
	var ignored: Array[RID] = [scene.player.get_rid()]
	for car in scene.traffic.cars:
		exclude_vehicle_motion(car, car.driver, ignored)
	for driver in scene.get_tree().get_nodes_in_group("shootable_drivers"):
		ignored.append(driver.body.get_rid())
	var query := PhysicsRayQueryParameters3D.create(start, end, 1 | 4 | 16 | 32, ignored)
	return scene.get_world_3d().direct_space_state.intersect_ray(query)

func cast_shot() -> void:
	var start: Vector3 = scene.eyes.global_position
	var end: Vector3 = start - scene.eyes.global_basis.z * 120.0
	last_hit = shot_query(start, end)
	if not last_hit.is_empty():
		end = last_hit.position
		var actor = last_hit.collider.get_meta("actor") if last_hit.collider.has_meta("actor") else null
		if is_instance_valid(actor) and actor.has_method("receive_hit"):
			actor.receive_hit(last_hit.collider.get_meta("region", "torso"), last_hit.position, (end-start).normalized()*preload("res://scripts/active_body.gd").DEFAULT_IMPULSE)
		if last_hit.collider.has_method("register_hit"):
			last_hit.collider.register_hit(last_hit.position, last_hit.normal)
		var mark := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		mark.mesh = sphere
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("e2d4ae")
		mark.material_override = material
		scene.add_child(mark)
		mark.global_position = end + last_hit.normal * 0.025
		var fade := mark.create_tween()
		fade.tween_property(mark, "scale", Vector3.ZERO, 0.35)
		fade.tween_callback(mark.queue_free)
	var line := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("e8d4a1")
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	mesh.surface_add_vertex(flash.global_position)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	line.mesh = mesh
	scene.add_child(line)
	var life := line.create_tween()
	life.tween_interval(0.055)
	life.tween_callback(line.queue_free)

func start_reload() -> bool:
	if not can_use() or reloading or rounds() >= CAPACITY:
		return false
	var best: Dictionary = {}
	for item in scene.player_inventory.items:
		if item.get("icon") == "magazine" and int(item.rounds) > rounds() and (best.is_empty() or int(item.rounds) > int(best.rounds)):
			best = item
	if best.is_empty():
		message("Kein Ersatzmagazin mit mehr Munition vorhanden.")
		click.play()
		return false
	pending_id = best.id
	reloading = true
	reload_clock = 0
	click.play()
	return true

func cancel_reload() -> void:
	reloading = false
	reload_clock = 0
	pending_id = ""
	if is_instance_valid(reload_hand):
		reload_hand.hide()

func finish_reload() -> void:
	var item := pistol()
	if item.is_empty():
		cancel_reload()
		return
	for i in range(scene.player_inventory.items.size()):
		var spare: Dictionary = scene.player_inventory.items[i]
		if spare.id == pending_id:
			var old: Dictionary = item.loaded_magazine
			item.loaded_magazine = spare
			scene.player_inventory.items[i] = old
			sync_descriptions()
			click.play()
			break
	cancel_reload()

func sync_descriptions() -> void:
	var item := pistol()
	if not item.is_empty():
		item.description = "Dienstpistole Glock 19.\nGeladen: %d / %d Patronen.\nLinksklick beim Zielen: Einzelschuss. R: Magazin wechseln." % [rounds(), CAPACITY]
	for magazine in scene.player_inventory.items:
		if magazine.get("icon") == "magazine":
			magazine.name = "G19-Magazin (%d/15)" % int(magazine.rounds)
			magazine.description = "Ersatzmagazin fuer die Glock 19.\nEnthaelt %d von 15 Patronen. Teilvolle und leere Magazine bleiben erhalten." % int(magazine.rounds)

func tick(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	recoil = move_toward(recoil, 0, delta * 7)
	flash_clock = maxf(0, flash_clock - delta)
	flash.visible = flash_clock > 0 and can_use()
	reload_hand.visible = reloading
	if reloading:
		reload_hand.position = Vector3(-0.08, -0.21 + sin(clampf(reload_clock / RELOAD_SECONDS, 0, 1) * PI) * 0.13, 0.02)
		if not can_use():
			cancel_reload()
		else:
			reload_clock += delta
			if reload_clock >= RELOAD_SECONDS:
				finish_reload()
