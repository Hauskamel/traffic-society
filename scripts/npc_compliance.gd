extends Node
## Deterministic compliance: no damage, flee chance or combat AI.
const AIM_RANGE := 25.0
const AIM_TIME := 0.25
var scene: Node3D
var candidate: Node3D
var aim_clock := 0.0

func ignored_bodies(node: Node, result: Array[RID]) -> void:
	if node is CollisionObject3D:
		result.append(node.get_rid())
	for child in node.get_children():
		ignored_bodies(child, result)

func visible_point(car: Node3D, point: Vector3) -> bool:
	var ignored: Array[RID] = [scene.player.get_rid()]
	# Vehicle colliders currently include the transparent cabin. Ignore only the
	# target vehicle; walls, terrain and all other vehicles still block the ray.
	ignored_bodies(car, ignored)
	var query := PhysicsRayQueryParameters3D.create(scene.eyes.global_position, point, 7, ignored)
	return scene.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func aimed_car() -> Node3D:
	var gear = scene.equipment
	if not gear.allowed() or gear.selected != 0 or gear.state != gear.State.AIMING or gear.draw < 0.95 or gear.pistol_action.reloading or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return null
	var origin: Vector3 = scene.eyes.global_position
	var forward: Vector3 = -scene.eyes.global_basis.z
	var best: Node3D
	var nearest := AIM_RANGE
	for car in scene.traffic.cars:
		var driver = car.driver
		if car.is_patrol or car.state == car.State.FINISHED or driver.arrested or driver.is_injured() or car.pickup_reserved or driver.state in [driver.State.SEARCHING, driver.State.IN_CUSTODY]:
			continue
		for point in [driver.head.global_position, driver.torso.global_position]:
			var offset: Vector3 = point - origin
			var along := offset.dot(forward)
			if along <= 0 or along > nearest or (offset - forward * along).length() > 0.32:
				continue
			if visible_point(car, point):
				nearest = along
				best = car
	return best

func tick(delta: float) -> void:
	var target := aimed_car()
	if target != candidate:
		candidate = target
		aim_clock = 0
	if not is_instance_valid(candidate):
		return
	aim_clock += delta
	if aim_clock >= AIM_TIME:
		candidate.request_surrender()

func nearby_car(only_surrendered := false) -> Node3D:
	if scene.aerial or scene.document_mode.active or scene.inventory_view.visible or scene.radio_open or scene.interaction_open or scene.climber.active or is_instance_valid(scene.climber.car) or is_instance_valid(scene.searching_driver) or is_instance_valid(scene.cargo_search_car) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return null
	var best: Node3D
	var nearest := 2.3
	for car in scene.traffic.cars:
		var driver = car.driver
		if car.is_patrol or car.pickup_reserved or car.state != car.State.PARKED or driver.state != driver.State.OUTSIDE:
			continue
		if only_surrendered and (not driver.surrendered or driver.arrested):
			continue
		if not only_surrendered and not (driver.surrendered or driver.arrested or car.surrender_stop):
			continue
		var target: Vector3 = driver.interaction_point()
		var difference: Vector3 = target - scene.eyes.global_position
		if difference.length() >= nearest or (-scene.eyes.global_basis.z).dot(difference.normalized()) < 0.8:
			continue
		if visible_point(car, target):
			best = car
			nearest = difference.length()
	return best

func handcuff() -> bool:
	var car := nearby_car(true)
	if not is_instance_valid(car):
		return false
	if not car.driver.set_arrested(true):
		return false
	scene.equipment.cancel()
	scene.feedback = "Handschellen angelegt: " + car.driver_name
	scene.feedback_time = 3.0
	return true
