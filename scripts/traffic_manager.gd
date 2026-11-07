extends Node3D
## Small deterministic roster and one control bay; no generated NPCs.
const TrafficCar = preload("res://scripts/traffic_car.gd")
const SPAWN_INTERVAL := 11.0
const ROSTER := [
	{"driver": "Bobby Mayer", "plate": "TS BM 104", "model": "Limousine", "kind": "sedan", "color": "477e89", "length": 4.2, "height": 1.65},
	{"driver": "Nora Beck", "plate": "TS NB 217", "model": "Kleinwagen", "kind": "hatch", "color": "c9a452", "length": 3.5, "height": 1.65},
	{"driver": "Erik Sommer", "plate": "TS ES 308", "model": "Transporter", "kind": "van", "color": "d8d1bc", "length": 5.0, "height": 2.35},
	{"driver": "Mara Wolf", "plate": "TS MW 412", "model": "Pickup", "kind": "pickup", "color": "a55f51", "length": 4.8, "height": 1.9},
]
var cars: Array[TrafficCar] = []
var controlled_car: TrafficCar
var selected_car: TrafficCar
var spawn_clock := 0.0
var roster_index := 0

func _ready() -> void:
	# Manager computes speed limits before vehicle physics.
	process_physics_priority = -10
	for z in [52.0, 19.0, -14.0, -47.0]:
		spawn_next(z)

func spawn_next(z := 52.0) -> bool:
	for existing in cars:
		if existing.state != TrafficCar.State.FINISHED and absf(existing.position.z - z) < 12.0 and existing.position.x < 4.0:
			return false
	for offset in range(ROSTER.size()):
		var index := (roster_index + offset) % ROSTER.size()
		var data: Dictionary = ROSTER[index]
		var present := false
		for existing in cars:
			if existing.driver_name == data.driver and existing.state != TrafficCar.State.FINISHED:
				present = true
		if present:
			continue
		var car := TrafficCar.new()
		car.driver_name = data.driver
		car.plate_number = data.plate
		car.model_name = data.model
		car.model_kind = data.kind
		car.body_color = data.color
		car.body_length = data.length
		car.body_height = data.height
		car.start_z = z
		add_child(car)
		cars.append(car)
		roster_index = (index + 1) % ROSTER.size()
		return true
	return false

func select_car(car: TrafficCar) -> void:
	if not cars.has(car) or car.state != TrafficCar.State.DRIVING:
		return
	selected_car = car
	refresh_markers()

func request_control() -> bool:
	if is_instance_valid(controlled_car) or not is_instance_valid(selected_car):
		return false
	if not selected_car.request_stop():
		return false
	controlled_car = selected_car
	selected_car = null
	refresh_markers()
	return true

func refresh_markers() -> void:
	for car in cars:
		car.marker.visible = car == selected_car or car == controlled_car

func _physics_process(delta: float) -> void:
	for i in range(cars.size() - 1, -1, -1):
		var car := cars[i]
		if car.state == TrafficCar.State.FINISHED:
			if car == selected_car:
				selected_car = null
			if car == controlled_car:
				controlled_car = null
			cars.remove_at(i)
			car.queue_free()
	spawn_clock += delta
	if spawn_clock >= SPAWN_INTERVAL:
		if spawn_next():
			spawn_clock = 0.0
	update_spacing()

func update_spacing() -> void:
	for car in cars:
		car.speed_limit = TrafficCar.ROAD_SPEED
		if car.state == TrafficCar.State.PARKED:
			continue
		for other in cars:
			if other == car or other.state == TrafficCar.State.FINISHED:
				continue
			var ahead := car.position.z - other.position.z
			var clearance := (car.body_length + other.body_length) / 2.0 + 3.0
			if ahead > 0 and absf(car.position.x - other.position.x) < 2.5:
				car.speed_limit = minf(car.speed_limit, maxf(0, (ahead - clearance) * 0.7))
			# Joining vehicles yield before crossing back onto the road.
			if car.state == TrafficCar.State.LEAVING and car.position.z < -15 and car.position.x > 4.2:
				if other.state == TrafficCar.State.DRIVING and other.position.z < -12 and other.position.z > -36:
					car.speed_limit = 0.0
