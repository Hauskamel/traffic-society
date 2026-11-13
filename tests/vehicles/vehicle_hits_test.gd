extends SceneTree
const HitSurface = preload("res://game/vehicles/vehicle_hit_surface.gd")
var failures: Array[String] = []
var scene: Node
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func trace(point: Vector3, direction: Vector3) -> Dictionary:
	return scene.equipment.pistol_action.shot_query(point + direction * 3, point - direction)
func run() -> void:
	scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		car.state = car.State.PARKED
		car.position = Vector3(50, 0.08, 50)
	var gun = scene.equipment.pistol_action
	for car in scene.traffic.cars:
		car.position = Vector3(7.1, 0.08, 5)
		var body_zone: HitSurface
		var glass_zone: HitSurface
		var tire_zone: HitSurface
		var roof_zone: HitSurface
		for zone in car.hit_surfaces.zones:
			check(zone.collision_layer == 16 and zone.collision_mask == 0, "Hit shapes must not interfere with movement")
			if zone.surface.get_parent() == car.driver_door:
				if zone.kind == "glass":
					glass_zone = zone
				elif zone.surface.mesh.size.y > 0.3:
					body_zone = zone
			if zone.kind == "tire" and tire_zone == null:
				tire_zone = zone
			if zone.surface.get_parent() == car and zone.kind == "body" and zone.surface.position.y > 1.5 and zone.surface.mesh.size.x > 1:
				roof_zone = zone
		check(body_zone != null and glass_zone != null and tire_zone != null and roof_zone != null, "All four models have body, glass, tire and roof shot surfaces")
		await physics_frame
		await physics_frame
		for zone in [body_zone, glass_zone, roof_zone, tire_zone]:
			var point: Vector3 = zone.surface.global_position
			var direction := Vector3.UP if zone == roof_zone else Vector3.LEFT
			if zone == tire_zone:
				point.z += 0.23
			var hit := trace(point, direction)
			check(not hit.is_empty() and hit.collider is HitSurface and hit.collider.kind == zone.kind, "Precise shot classification: " + car.model_kind + " / " + zone.kind)
			if hit.is_empty():
				continue
			hit.collider.register_hit(hit.position, hit.normal)
			check(car.hit_surfaces.marks.back().get_parent() == hit.collider.surface, "Mark attaches to actual hit mesh")
		var hit := trace(body_zone.surface.global_position, Vector3.LEFT)
		hit.collider.register_hit(hit.position, hit.normal)
		var mark: MeshInstance3D = car.hit_surfaces.marks.back()
		var local_before := mark.transform
		var global_before := mark.global_position
		car.driver_door.rotation.y = -1.15
		check(mark.transform.is_equal_approx(local_before) and mark.global_position.distance_to(global_before) > 0.1, "Door opening moves the mark without sliding")
		await physics_frame
		await physics_frame
		var opened := trace(body_zone.surface.global_position, body_zone.surface.global_basis * Vector3.LEFT)
		check(not opened.is_empty() and opened.collider is HitSurface and opened.collider.surface.get_parent() == car.driver_door, "Shot geometry follows opened door")
		car.position += Vector3(3, 0, -2)
		check(mark.transform.is_equal_approx(local_before), "Moving car preserves local mark transform")
		car.driver_door.rotation.y = 0
		car.position = Vector3(50, 0.08, 50)
	var car = scene.traffic.cars[0]
	car.position = Vector3(7.1, 0.08, 5)
	scene.aerial = false
	scene.update_camera()
	scene.player.position = Vector3(4.5, 0.1, 5)
	var zone: HitSurface
	for candidate in car.hit_surfaces.zones:
		if candidate.surface.get_parent() == car.driver_door and candidate.kind == "body" and candidate.surface.mesh.size.y > 0.3:
			zone = candidate
	scene.eyes.look_at(zone.surface.global_position)
	scene.equipment.state = scene.equipment.State.AIMING
	scene.equipment.draw = 1
	await physics_frame
	await physics_frame
	var before: int = car.hit_surfaces.marks.size()
	check(gun.fire(), "Actual aimed shot fires")
	check(car.hit_surfaces.marks.size() == before + 1, "Actual pistol creates permanent vehicle mark")
	if DisplayServer.get_name() != "headless":
		# A closer view makes the small surface detail reviewable.
		scene.player.position.x = 5.8
		scene.eyes.look_at(zone.surface.global_position)
		scene.equipment.hand.hide()
		await create_timer(0.4).timeout
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://vehicle-bullet-holes.png")
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.15, 3, 3)
	collision.shape = shape
	wall.add_child(collision)
	scene.add_child(wall)
	wall.position = zone.surface.global_position + Vector3.LEFT
	await physics_frame
	await physics_frame
	var blocked := trace(zone.surface.global_position, Vector3.LEFT)
	check(not blocked.is_empty() and blocked.collider == wall, "World wall blocks vehicle shots")
	for i in range(70):
		zone.register_hit(zone.surface.global_position + Vector3.LEFT * 0.05, Vector3.LEFT)
	check(car.hit_surfaces.marks.size() == 64, "Per-vehicle mark budget bounds resource use")
	gun.sound.stop()
	gun.click.stop()
	await create_timer(0.25).timeout
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: four models, separate body/glass/tire/roof hits, real gun shot, surface-attached marks, moving doors/cars, wall occlusion and bounded marks")
	quit(0 if failures.is_empty() else 1)
