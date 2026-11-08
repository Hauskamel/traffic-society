extends RefCounted
## Contextual vault onto a parked pickup/van. No timer UI or world pause.
var scene: Node3D
var car: Node3D
var active := false
var going_up := true
var elapsed := 0.0
var start := Vector3.ZERO
var landing := Vector3.ZERO
var original_height := 1.8
const DURATION := 0.85

func shape() -> CollisionShape3D:
	return scene.player.get_child(0) as CollisionShape3D

func set_height(height: float) -> void:
	shape().shape.height = height
	shape().position.y = height / 2.0
	scene.eyes.position.y = height - 0.1

func target_height(vehicle: Node3D) -> float:
	return 1.2 if vehicle.model_kind == "van" else original_height

func entry_x(vehicle: Node3D) -> float:
	if vehicle.model_kind == "van":
		for part in vehicle.parts:
			if part.kind == "trunk" and absf(part.angle()) > 1.1:
				return -0.43 if part.pivot.position.x < 0 else 0.43
	return 0.0

func entry(vehicle: Node3D) -> Vector3:
	var floor_y := 0.75 if vehicle.model_kind == "van" else 1.07
	return vehicle.to_global(Vector3(entry_x(vehicle), floor_y + 0.03, vehicle.body_length / 2.0 - 0.75))

func clear_at(at: Vector3, height: float) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = height
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3(0, height / 2.0, 0))
	query.collision_mask = 7
	query.exclude = [scene.player.get_rid()]
	return scene.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func available() -> bool:
	if active or scene.aerial or scene.interaction_open or scene.inventory_view.visible or is_instance_valid(scene.searching_driver) or is_instance_valid(scene.cargo_search_car) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false
	var vehicle = scene.traffic.controlled_car
	if not is_instance_valid(vehicle) or vehicle.state != vehicle.State.PARKED or vehicle.model_kind not in ["van", "pickup"] or not vehicle.cargo_accessible():
		return false
	if is_instance_valid(car):
		return clear_at(exit_point(), original_height)
	var local: Vector3 = vehicle.to_local(scene.player.global_position)
	var rear: float = vehicle.body_length / 2.0
	var forward: Vector3 = -scene.eyes.global_basis.z
	forward.y = 0
	if local.z < rear + 0.1 or local.z > rear + 2.0 or absf(local.x) > 1.15 or forward.normalized().dot(-vehicle.global_basis.z) < 0.45:
		return false
	if vehicle.model_kind == "van" and not has_open_van_door(vehicle):
		return false
	return clear_at(entry(vehicle), target_height(vehicle))

func has_open_van_door(vehicle: Node3D) -> bool:
	for part in vehicle.parts:
		if part.kind == "trunk" and absf(part.angle()) > 1.1:
			return true
	return false

func exit_point() -> Vector3:
	return car.to_global(Vector3(entry_x(car), 0.03 - car.position.y, car.body_length / 2.0 + 1.15))

func begin() -> bool:
	if not available():
		return false
	going_up = not is_instance_valid(car)
	if going_up:
		car = scene.traffic.controlled_car
		landing = entry(car)
		set_height(target_height(car))
	else:
		landing = exit_point()
	start = scene.player.global_position
	car.officer_aboard = true
	scene.player.velocity = Vector3.ZERO
	elapsed = 0
	active = true
	return true

func tick(delta: float) -> void:
	if not active:
		if is_instance_valid(car):
			var local: Vector3 = car.to_local(scene.player.global_position)
			if scene.player.position.y < 0.25 or absf(local.x) > 1.45 or local.z > car.body_length / 2.0 + 0.7:
				car.officer_aboard = false
				car = null
				set_height(original_height)
		return
	elapsed = minf(DURATION, elapsed + delta)
	var t := elapsed / DURATION
	var next: Vector3
	if going_up:
		var high := Vector3(landing.x, landing.y + 0.08, start.z)
		next = start.lerp(high, smoothstep(0, 0.45, t)) if t < 0.45 else high.lerp(landing, smoothstep(0.45, 1, t))
	else:
		var edge := Vector3(landing.x, start.y + 0.08, landing.z)
		next = start.lerp(edge, smoothstep(0, 0.6, t)) if t < 0.6 else edge.lerp(landing, smoothstep(0.6, 1, t))
	var hit = scene.player.move_and_collide(next - scene.player.global_position)
	if hit != null and scene.player.global_position.distance_to(next) > 0.025:
		scene.player.global_position = start
		active = false
		if going_up:
			car.officer_aboard = false
			car = null
			set_height(original_height)
		scene.feedback = "Weg blockiert. Bitte direkt vor die offene Ladeflaeche stellen."
		scene.feedback_time = 4
		return
	if t >= 1:
		active = false
		scene.player.velocity = Vector3.ZERO
		if not going_up:
			car.officer_aboard = false
			car = null
			set_height(original_height)
