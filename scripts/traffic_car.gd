extends AnimatableBody3D
## Authored encounter: +Z to -Z on the right-hand lane, then through the bay.
signal state_changed

enum State { DRIVING, PULLING_OVER, PARKED, LEAVING, FINISHED }
const VehicleHitSurfaces = preload("res://scripts/vehicle_hit_surfaces.gd")
var hit_surfaces: VehicleHitSurfaces
var is_patrol := false
var surrender_stop := false
var pickup_reserved := false
var depart_after_entry := false
var inventory: RefCounted
var cargo_inventory: RefCounted
var cargo_search_active := false
var officer_aboard := false
var cargo_props: Node3D
const CargoItem = preload("res://scripts/cargo_item.gd")
const CargoZone = preload("res://scripts/cargo_zone.gd")
var cargo_zone: CargoZone
var driver_name := "Bobby Mayer"
var plate_number := "TS BM 104"
var model_name := "Limousine"
var body_color := "477e89"
var model_kind := "sedan"
var body_length := 4.2
var body_height := 1.65
var speed_limit := ROAD_SPEED
var start_z := 52.0
const SpeedSettings = preload("res://scripts/speed_settings.gd")
const ROAD_SPEED := SpeedSettings.TRAFFIC_SPEED_KMH / 3.6
const BAY_SPEED := SpeedSettings.PARKING_SPEED_KMH / 3.6
const EXIT_SPEED := SpeedSettings.EXIT_SPEED_KMH / 3.6
var state: State = State.DRIVING
var speed := ROAD_SPEED
var route: Curve3D
var distance := 0.0
var wheels: Array[Node3D] = []
var brake_material: StandardMaterial3D
var marker: MeshInstance3D
var window_point: Marker3D
var front_wheels: Array[Node3D] = []
const DriverActor = preload("res://scripts/driver_actor.gd")
var driver: DriverActor
var driver_door: AnimatableBody3D
const VehiclePart = preload("res://scripts/vehicle_part.gd")
var parts: Array[VehiclePart] = []

func material(color: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.8
	return m

func piece(at: Vector3, size: Vector3, m: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = m
	parent.add_child(mesh)
	mesh.position = at
	return mesh

func _ready() -> void:
	name = driver_name.replace(" ", "")
	sync_to_physics = false
	collision_layer = 2
	collision_mask = 0
	var hit := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(1.95, body_height - 0.15, body_length + 0.1)
	if model_kind == "van":
		bounds.size.z = 1.6
		hit.position.z = -1.7
	elif model_kind == "pickup":
		bounds.size.z = 1.8
		hit.position.z = -0.75
	hit.shape = bounds
	hit.position.y = (body_height + 0.15) / 2.0
	add_child(hit)
	if model_kind == "van":
		physical_box(Vector3(0, 0.7, 0.75), Vector3(1.72, 0.1, 3.4))
		physical_box(Vector3(0, 2.23, 0.75), Vector3(1.9, 0.12, 3.5))
		physical_box(Vector3(0, 1.45, -0.9), Vector3(1.8, 1.5, 0.1))
		for x in [-0.87, 0.87]:
			physical_box(Vector3(x, 1.45, 0.75), Vector3(0.12, 1.5, 3.4))
	elif model_kind == "pickup":
		physical_box(Vector3(0, 0.65, -2.0), Vector3(1.8, 0.7, 0.8))
		physical_box(Vector3(0, 1.04, 1.3), Vector3(1.55, 0.06, 2.1))
		for x in [-0.84, 0.84]:
			physical_box(Vector3(x, 1.22, 1.3), Vector3(0.13, 0.4, 2.1))
	var paint := material(body_color)
	var trim := material("24323b")
	var glass := material("a5c2cc")
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	glass.albedo_color.a = 0.28
	piece(Vector3(0, 0.55, 0), Vector3(1.8, 0.18, body_length), paint)
	if model_kind == "pickup":
		piece(Vector3(0, 0.79, 0), Vector3(1.55, 0.45, body_length), paint)
	var cabin_z := 0.15
	var cabin_length := 2.15
	var roof_y := 1.6
	if model_kind == "hatch":
		cabin_z = 0.35
		cabin_length = 2.25
	elif model_kind == "van":
		cabin_z = -1.25
		cabin_length = 1.45
		roof_y = 2.25
		# Hollow cargo volume: floor, sides, bulkhead and roof, no solid rear wall.
		piece(Vector3(0, 0.79, -1.7), Vector3(1.55, 0.45, 1.6), paint)
		piece(Vector3(0, 0.7, 0.75), Vector3(1.72, 0.1, 3.4), trim)
		for x in [-0.87, 0.87]:
			piece(Vector3(x, 1.45, 0.75), Vector3(0.12, 1.5, 3.4), paint)
		piece(Vector3(0, 1.45, -0.9), Vector3(1.8, 1.5, 0.1), paint)
		piece(Vector3(0, 2.23, 0.75), Vector3(1.9, 0.12, 3.5), trim)
		for side in [-1.0, 1.0]:
			var rear := panel_hinge(Vector3(side * 0.9, 0, body_length / 2.0), Vector3(0.87, 1.5, 0.1), Vector3(-side * 0.435, 1.45, 0), paint, "CargoDoor")
			piece(Vector3(-side * 0.76, 1.35, 0.065), Vector3(0.05, 0.25, 0.04), trim, rear)
			add_part(rear, "Linke Ladetuer" if side < 0 else "Rechte Ladetuer", "trunk", Vector3(-side * 0.435, 1.45, 0), Vector3(0.9, 1.5, 0.24), Vector3.UP, side * 1.5)
	elif model_kind == "pickup":
		cabin_z = -0.75
		cabin_length = 1.6
		roof_y = 1.8
		# Open cargo bed with separate rails and visible floor.
		piece(Vector3(0, 1.04, 1.3), Vector3(1.55, 0.06, 2.1), trim)
		for x in [-0.84, 0.84]:
			piece(Vector3(x, 1.22, 1.3), Vector3(0.13, 0.4, 2.1), paint)
		var tailgate := panel_hinge(Vector3(0, 1.02, body_length / 2.0 - 0.05), Vector3(1.8, 0.4, 0.12), Vector3(0, 0.2, 0), paint, "Tailgate")
		add_part(tailgate, "Ladeflaechenklappe", "trunk", Vector3(0, 0.2, 0), Vector3(1.8, 0.45, 0.24), Vector3.RIGHT, 1.5)
	if model_kind == "sedan":
		var rear_start := cabin_z + cabin_length / 2.0
		var main_length := rear_start + body_length / 2.0
		piece(Vector3(0, 0.79, -body_length / 2.0 + main_length / 2.0), Vector3(1.55, 0.45, main_length), paint)
		var trunk_length := body_length / 2.0 - rear_start
		var trunk_center := rear_start + trunk_length / 2.0
		piece(Vector3(0, 0.66, trunk_center), Vector3(1.65, 0.08, trunk_length), trim)
		for x in [-0.84, 0.84]:
			piece(Vector3(x, 0.81, trunk_center), Vector3(0.12, 0.34, trunk_length), paint)
		piece(Vector3(0, 0.81, body_length / 2.0), Vector3(1.8, 0.34, 0.1), paint)
		var lid := AnimatableBody3D.new()
		lid.name = "TrunkLid"
		lid.sync_to_physics = false
		lid.collision_layer = 4
		lid.collision_mask = 0
		add_child(lid)
		lid.position = Vector3(0, 1.04, rear_start)
		piece(Vector3(0, 0, trunk_length / 2.0), Vector3(1.8, 0.08, trunk_length), paint, lid)
		var hit_lid := CollisionShape3D.new()
		var shape_lid := BoxShape3D.new()
		shape_lid.size = Vector3(1.8, 0.08, trunk_length)
		hit_lid.shape = shape_lid
		hit_lid.position.z = trunk_length / 2.0
		lid.add_child(hit_lid)
		add_part(lid, "Kofferraum", "trunk", Vector3(0, 0, trunk_length / 2.0), Vector3(1.85, 0.24, trunk_length), Vector3.RIGHT, -1.2)
	if model_kind == "hatch":
		piece(Vector3(0, 0.79, -0.48), Vector3(1.55, 0.45, 2.55), paint)
		piece(Vector3(0, 0.66, 1.24), Vector3(1.65, 0.08, 1.0), trim)
		for x in [-0.84, 0.84]:
			piece(Vector3(x, 0.82, 1.24), Vector3(0.12, 0.36, 1.0), paint)
		var hatch := panel_hinge(Vector3(0, roof_y + 0.02, body_length / 2.0), Vector3(1.8, 0.6, 0.1), Vector3(0, -0.7, 0), paint, "RearHatch")
		piece(Vector3(0, -0.22, 0), Vector3(1.65, 0.38, 0.04), glass, hatch)
		add_part(hatch, "Heckklappe", "trunk", Vector3(0, -0.5, 0), Vector3(1.8, 1.0, 0.24), Vector3.RIGHT, -1.85)
	var cabin_y := (1.04 + roof_y) / 2.0
	var door_length := minf(1.25, cabin_length * 0.65)
	var front_z := cabin_z - cabin_length / 2.0
	# Separate front, rear and passenger windows leave a real opening on the left.
	var window_ends: Array[float] = [front_z]
	if model_kind != "hatch":
		window_ends.append(cabin_z + cabin_length / 2.0)
	for z in window_ends:
		piece(Vector3(0, cabin_y, z), Vector3(1.6, roof_y - 1.0, 0.035), glass)
	piece(Vector3(0.8, cabin_y, front_z + door_length + (cabin_length - door_length) / 2.0), Vector3(0.035, roof_y - 1.0, cabin_length - door_length), glass)
	piece(Vector3(-0.8, cabin_y, front_z + door_length + (cabin_length - door_length) / 2.0), Vector3(0.035, roof_y - 1.0, cabin_length - door_length), glass)
	piece(Vector3(0, roof_y, cabin_z), Vector3(1.7, 0.12, cabin_length + 0.1), paint)
	piece(Vector3(0, cabin_y, front_z + door_length), Vector3(1.65, roof_y - 0.95, 0.08), paint)
	driver_door = AnimatableBody3D.new()
	driver_door.name = "DriverDoor"
	driver_door.sync_to_physics = false
	driver_door.collision_layer = 4
	driver_door.collision_mask = 0
	add_child(driver_door)
	driver_door.position = Vector3(-0.91, 0, front_z)
	piece(Vector3(0, 0.82, door_length / 2.0), Vector3(0.10, 0.48, door_length), paint, driver_door)
	piece(Vector3(0, cabin_y, door_length / 2.0), Vector3(0.035, roof_y - 1.0, door_length), glass, driver_door)
	piece(Vector3(0, roof_y - 0.02, door_length / 2.0), Vector3(0.07, 0.06, door_length), paint, driver_door)
	piece(Vector3(-0.065, 0.98, door_length * 0.8), Vector3(0.04, 0.04, 0.16), trim, driver_door)
	var door_hit := CollisionShape3D.new()
	var door_box := BoxShape3D.new()
	door_box.size = Vector3(0.12, roof_y - 0.5, door_length)
	door_hit.shape = door_box
	door_hit.position = Vector3(0, (roof_y + 0.5) / 2.0, door_length / 2.0)
	driver_door.add_child(door_hit)
	var passenger := driver_door.duplicate() as AnimatableBody3D
	passenger.name = "PassengerDoor"
	add_child(passenger)
	passenger.position.x = 0.91
	add_part(passenger, "Beifahrertuer", "passenger_door", Vector3(0, 0.82, door_length / 2.0), Vector3(0.24, 0.5, door_length), Vector3.UP, 1.15)
	add_part(driver_door, "Fahrertuer", "driver_door", Vector3(0, 0.82, door_length / 2.0), Vector3(0.24, 0.5, door_length), Vector3.UP, -1.15)
	for z in [-body_length / 2.0, body_length / 2.0]:
		piece(Vector3(0, 0.52, z), Vector3(1.82, 0.14, 0.14), trim)
	for x in [-0.96, 0.96]:
		piece(Vector3(x, cabin_y, cabin_z - cabin_length * 0.3), Vector3(0.2, 0.18, 0.3), paint)
	brake_material = material("862c2b")
	for x in [-0.61, 0.61]:
		piece(Vector3(x, 0.82, -body_length / 2.0 - 0.01), Vector3(0.42, 0.2, 0.04), material("fff0c7"))
		piece(Vector3(signf(x) * 0.86 if model_kind in ["van", "hatch"] else x, 0.82, body_length / 2.0 + 0.01), Vector3(0.14 if model_kind in ["van", "hatch"] else 0.42, 0.2, 0.04), brake_material)
	for x in [-0.92, 0.92]:
		for z in [-body_length * 0.32, body_length * 0.32]:
			var steer := Node3D.new()
			add_child(steer)
			steer.position = Vector3(x, 0.35, z)
			if z < 0:
				front_wheels.append(steer)
			var spin := Node3D.new()
			steer.add_child(spin)
			wheels.append(spin)
			var tire := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.35
			cylinder.bottom_radius = 0.35
			cylinder.height = 0.22
			cylinder.radial_segments = 12
			tire.mesh = cylinder
			tire.material_override = trim
			tire.rotation.z = PI / 2
			spin.add_child(tire)
			piece(Vector3(0, 0, 0), Vector3(0.235, 0.17, 0.17), material("a8b2ae"), spin)
	driver = DriverActor.new()
	driver.door = driver_door
	driver.seat = Vector3(-0.43, roof_y - 1.48, cabin_z - 0.2)
	driver.outside = Vector3(-2.1, -0.08, cabin_z - 0.2)
	add_child(driver)
	var plate := Label3D.new()
	plate.text = plate_number
	plate.font_size = 32
	plate.pixel_size = 0.008
	plate.position = Vector3(0, 0.59, -body_length / 2.0 - 0.1)
	plate.rotation.y = PI
	add_child(plate)
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 2.1
	ring.outer_radius = 2.17
	marker.mesh = ring
	marker.material_override = material("efd58b")
	marker.position.y = 0.06
	marker.visible = false
	add_child(marker)
	window_point = Marker3D.new()
	window_point.name = "DriverWindow"
	window_point.position = Vector3(-1.2, cabin_y, cabin_z - 0.25)
	add_child(window_point)
	build_cargo()
	new_test_drive()
	hit_surfaces = VehicleHitSurfaces.new()
	hit_surfaces.vehicle = self
	add_child(hit_surfaces)
	hit_surfaces.build(self)

func set_route(points: Array[Vector3]) -> void:
	route = Curve3D.new()
	route.bake_interval = 0.08
	for i in range(points.size()):
		var tangent := Vector3.ZERO
		if i > 0 and i < points.size() - 1:
			tangent = (points[i + 1] - points[i - 1]) * 0.12
		route.add_point(points[i], -tangent, tangent)
	distance = 0.0

func new_test_drive() -> void:
	for part in parts:
		part.reset()
	driver.reset()
	visible = true
	position = Vector3(2, 0.08, start_z)
	rotation = Vector3.ZERO
	speed = ROAD_SPEED
	state = State.DRIVING
	marker.visible = false
	for wheel in front_wheels:
		wheel.rotation.y = 0
	set_route([position, Vector3(2, 0.08, -64)])
	state_changed.emit()

func can_stop() -> bool:
	return not driver.surrendered and state == State.DRIVING and position.z > 28.0

func request_stop() -> bool:
	if not can_stop():
		return false
	state = State.PULLING_OVER
	marker.visible = true
	set_route([position, Vector3(2, 0.08, 28), Vector3(4, 0.08, 22),
		Vector3(6.8, 0.08, 17), Vector3(7.1, 0.08, 12), Vector3(7.1, 0.08, 5)])
	state_changed.emit()
	return true

func release() -> bool:
	if state != State.PARKED or not driver.can_drive() or not all_parts_closed() or cargo_search_active or officer_aboard or driver.arrested:
		return false
	state = State.LEAVING
	if surrender_stop:
		set_route([position, position + Vector3(0, 0, -6), Vector3(2, 0.08, minf(position.z - 14, -40)), Vector3(2, 0.08, minf(position.z - 24, -64))])
		surrender_stop = false
		state_changed.emit()
		return true
	set_route([position, Vector3(7.1, 0.08, -12), Vector3(6.8, 0.08, -17),
		Vector3(4, 0.08, -22), Vector3(2, 0.08, -28), Vector3(2, 0.08, -64)])
	state_changed.emit()
	return true

func _physics_process(delta: float) -> void:
	if driver.surrendered and state == State.PARKED and driver.state == driver.State.SEATED:
		driver.request_exit()
	if depart_after_entry and driver.can_drive() and all_parts_closed():
		depart_after_entry = false
		release()
	if state == State.PARKED or state == State.FINISHED:
		return
	var remaining := route.get_baked_length() - distance
	var target := ROAD_SPEED
	if state == State.PULLING_OVER:
		target = minf(BAY_SPEED, sqrt(maxf(0.0, 2.0 * 1.6 * remaining)))
	elif state == State.LEAVING and position.z > -26:
		target = EXIT_SPEED
	target = minf(target, speed_limit)
	if is_instance_valid(hit_surfaces):
		target = minf(target, hit_surfaces.speed_cap())
	if driver.surrendered:
		target = 0
	speed = move_toward(speed, target, (4.0 if driver.surrendered else 1.6) * delta)
	if driver.surrendered and speed <= 0.05:
		speed = 0
		state = State.PARKED
		driver.request_exit()
		state_changed.emit()
		return
	var travel := minf(speed * delta, remaining)
	distance += travel
	var next := route.sample_baked(distance, true)
	var ahead := route.sample_baked(minf(distance + 0.3, route.get_baked_length()), true)
	var direction := ahead - next
	var old_yaw := rotation.y
	position = next
	if direction.length_squared() > 0.00001:
		rotation.y = atan2(-direction.x, -direction.z)
	for wheel in wheels:
		wheel.rotation.x -= travel / 0.35
	for wheel in front_wheels:
		wheel.rotation.y = clampf(angle_difference(old_yaw, rotation.y) * 15.0, -0.35, 0.35)
	brake_material.albedo_color = Color("ff5646") if driver.surrendered or state == State.PULLING_OVER or speed > target + 0.05 else Color("862c2b")
	if remaining <= 0.025:
		position = route.sample_baked(route.get_baked_length())
		speed = 0
		if state == State.PULLING_OVER or driver.surrendered:
			state = State.PARKED
			rotation.y = 0
			for wheel in front_wheels:
				wheel.rotation.y = 0
		else:
			state = State.FINISHED
			visible = false
		state_changed.emit()


func add_part(hinge: AnimatableBody3D, label: String, kind: String, at: Vector3, size: Vector3, axis: Vector3, opening: float) -> void:
	var part := VehiclePart.new()
	part.vehicle = self
	part.pivot = hinge
	part.title = label
	part.kind = kind
	part.axis = axis
	part.open_angle = opening
	var hit := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	hit.shape = shape
	part.add_child(hit)
	hinge.add_child(part)
	part.position = at
	parts.append(part)

func all_parts_closed() -> bool:
	for part in parts:
		if not part.is_closed():
			return false
	return true


func panel_hinge(at: Vector3, size: Vector3, center: Vector3, mat: Material, label: String) -> AnimatableBody3D:
	var hinge := AnimatableBody3D.new()
	hinge.name = label
	hinge.sync_to_physics = false
	hinge.collision_layer = 4
	hinge.collision_mask = 0
	add_child(hinge)
	hinge.position = at
	piece(center, size, mat, hinge)
	var hit := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	hit.shape = shape
	hit.position = center
	hinge.add_child(hit)
	return hinge


func cargo_accessible() -> bool:
	for part in parts:
		if part.kind == "trunk" and absf(part.angle()) > 0.5:
			return true
	return false

func build_cargo() -> void:
	var rear := body_length / 2.0
	var floor_y := 0.72
	var center_y := 0.98
	var depth := 0.6
	var height := 0.45
	if model_kind == "hatch":
		depth = 0.85
	elif model_kind == "van":
		floor_y = 0.76
		center_y = 1.25
		depth = 2.1
		height = 0.95
	elif model_kind == "pickup":
		floor_y = 1.09
		center_y = 1.3
		depth = 1.7
	cargo_zone = CargoZone.new()
	cargo_zone.vehicle = self
	cargo_zone.pivot = self
	cargo_zone.title = "Laderaum"
	cargo_zone.kind = "cargo"
	var hit := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.45, height, depth)
	hit.shape = shape
	hit.position.z = -depth / 2.0 + 0.1
	cargo_zone.add_child(hit)
	var floor := MeshInstance3D.new()
	var pad := BoxMesh.new()
	pad.size = Vector3(1.4, 0.018, depth)
	floor.mesh = pad
	floor.material_override = material("35434a")
	cargo_zone.add_child(floor)
	floor.position = Vector3(0, floor_y - center_y, -depth / 2.0 + 0.1)
	cargo_zone.floor_mesh = floor
	add_child(cargo_zone)
	cargo_zone.position = Vector3(0, center_y, rear - 0.3)
	cargo_props = Node3D.new()
	cargo_props.name = "CargoItems"
	add_child(cargo_props)
	if model_kind == "van":
		var rack := Node3D.new()
		rack.name = "Shelf"
		add_child(rack)
		for z in [0.25, 1.8]:
			for x in [-0.79, -0.24]:
				piece(Vector3(x, 1.35, z), Vector3(0.035, 1.15, 0.035), material("7c8d92"), rack)
		for y in [0.78, 1.38]:
			piece(Vector3(-0.52, y, 1.025), Vector3(0.58, 0.045, 1.6), material("829597"), rack)
			var solid := StaticBody3D.new()
			rack.add_child(solid)
			var cargo_hit := CollisionShape3D.new()
			var size := BoxShape3D.new()
			size.size = Vector3(0.58, 0.045, 1.6)
			cargo_hit.shape = size
			cargo_hit.position = Vector3(-0.52, y, 1.025)
			solid.add_child(cargo_hit)
	if cargo_inventory != null:
		var catalog = preload("res://scripts/item_inventory.gd").for_vehicle(driver_name, plate_number)
		for i in range(catalog.items.size()):
			var item: Dictionary = catalog.items[i]
			for actual in cargo_inventory.items:
				if actual.id == item.id:
					item = actual
			var prop := Node3D.new()
			prop.set_meta("item_id", item.id)
			prop.set_meta("data", item)
			cargo_props.add_child(prop)
			prop.scale = Vector3.ONE * 0.45
			prop.position = Vector3(-0.43 if i == 0 else 0.43 if i == 1 else 0.0, floor_y + 0.13, rear - (0.35 if i < 2 else 0.68))
			if model_kind == "van":
				if i < 3:
					prop.scale = Vector3.ONE * 0.48
					prop.position = Vector3(-0.52, (1.40 if i == 1 else 0.81) + 0.13, 0.65 if i == 2 else 1.48)
				else:
					prop.position = Vector3(0.48, floor_y + 0.13, 0.65)
			elif model_kind == "pickup":
				prop.position = Vector3(-0.45 if i == 0 else 0.4, floor_y + 0.13, 0.85 if i == 0 else 0.7)
				if item.icon == "ladder":
					prop.scale = Vector3.ONE
					prop.position = Vector3(0.38, floor_y + 0.1, 1.25)
			build_item_model(prop, item)
			if item.icon == "ladder":
				continue
			var target = preload("res://scripts/cargo_item.gd").new()
			target.vehicle = self
			target.pivot = self
			target.prop = prop
			target.item = item
			var box := BoxShape3D.new()
			box.size = Vector3(1.6, 0.75, 1.0) if item.get("container_type") in ["toolbox", "cooler"] else Vector3(1.0, 1.3 if item.icon == "water_barrel" else 1.05, 1.0)
			var item_center_y := 0.05 if item.get("container_type") in ["toolbox", "cooler"] else 0.3 if item.icon == "water_barrel" else 0.15
			var cargo_hit := CollisionShape3D.new()
			cargo_hit.shape = box
			cargo_hit.position.y = item_center_y
			target.add_child(cargo_hit)
			var solid := StaticBody3D.new()
			solid.collision_layer = 4
			prop.add_child(solid)
			var body_hit := CollisionShape3D.new()
			body_hit.shape = box
			body_hit.position.y = item_center_y
			solid.add_child(body_hit)
			target.solid = solid
			prop.add_child(target)
	refresh_cargo_props()

func build_item_model(prop: Node3D, item: Dictionary) -> void:
	var previous := prop.get_node_or_null("Model")
	if previous != null:
		prop.remove_child(previous)
		previous.queue_free()
	var model: Node3D
	if item.get("container_type") == "toolbox":
		model = preload("res://scripts/toolbox_model.gd").new()
	elif item.has("container_type"):
		model = preload("res://scripts/cargo_container_model.gd").new()
	else:
		model = Node3D.new()
	model.name = "Model"
	prop.add_child(model)
	if item.has("container_type"):
		model.configure(item)
	elif item.icon == "ladder":
		for x in [-0.19, 0.19]:
			piece(Vector3(x, 0, 0), Vector3(0.055, 0.06, 1.8), material("acb5b5"), model)
		for i in range(6):
			piece(Vector3(0, 0, -0.75 + i * 0.3), Vector3(0.38, 0.045, 0.06), material("acb5b5"), model)
	elif item.icon == "receipt":
		piece(Vector3(0, -0.27, 0), Vector3(0.4, 0.02, 0.55), material("e1ddbf"), model)
	else:
		piece(Vector3(0, -0.1, 0), Vector3(0.7, 0.3, 0.65), material("a78a64"), model)
	for node in prop.get_children():
		if node is CargoItem:
			node.set_highlight(false)
			node.refresh_surfaces()

func refresh_cargo_props() -> void:
	if cargo_props == null or cargo_inventory == null:
		return
	for prop in cargo_props.get_children():
		prop.visible = false
		for item in cargo_inventory.items:
			if prop.get_meta("item_id") == item.id:
				prop.visible = true
				prop.set_meta("data", item)
				for target in prop.get_children():
					if target is CargoItem:
						target.item = item
				build_item_model(prop, item)


func physical_box(at: Vector3, size: Vector3) -> void:
	var hit := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	hit.shape = shape
	hit.position = at
	add_child(hit)


func request_departure() -> bool:
	if state != State.PARKED or driver.arrested or officer_aboard or cargo_search_active:
		return false
	for part in parts:
		if part.kind != "driver_door" and not part.is_closed():
			return false
	if driver.state == driver.State.SEATED:
		return release()
	if driver.request_enter():
		depart_after_entry = true
		return true
	return false

func request_surrender() -> bool:
	if is_patrol or state == State.FINISHED or not driver.request_surrender():
		return false
	depart_after_entry = false
	if state != State.PARKED:
		surrender_stop = true
	return true
