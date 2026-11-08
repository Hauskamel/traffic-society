extends Node3D
## Authored pickup sequence. The 20-second delay precedes spawning the patrol.
const TrafficCar = preload("res://scripts/traffic_car.gd")
const Visuals = preload("res://scripts/police_visuals.gd")
enum Stage { IDLE, WAITING, APPROACHING, EXITING, WALKING, ESCORTING, BOARDING, RETURNING, ENTERING, DEPARTING, COMPLETE }
const RESPONSE_DELAY := 20.0
var scene: Node3D
var stage: Stage = Stage.IDLE
var elapsed := 0.0
var patrol: TrafficCar
var source: TrafficCar
var suspect: Node3D
var officer: Node3D
var waypoints: Array[Vector3] = []
var waypoint := 0
var boarding_time := 0.0
var boarding_start := Vector3.ZERO
var report := "Funk bereit. Fuer eine Abholung zuerst eine Person festnehmen."

func active() -> bool:
	return stage != Stage.IDLE and stage != Stage.COMPLETE

func request_pickup(car: TrafficCar) -> bool:
	if active() or not is_instance_valid(car) or car.state != TrafficCar.State.PARKED or car.officer_aboard or car.cargo_search_active or not car.driver.arrested or car.driver.state != car.driver.State.OUTSIDE:
		return false
	source = car
	source.pickup_reserved = true
	for part in source.parts:
		if part.opened:
			part.toggle()
	suspect = car.driver
	stage = Stage.WAITING
	elapsed = 0
	report = "Abholung bestaetigt: " + car.driver_name
	return true

func cancel_waiting() -> bool:
	if stage != Stage.WAITING:
		return false
	stage = Stage.IDLE
	if is_instance_valid(source):
		source.pickup_reserved = false
	source = null
	suspect = null
	report = "Abholung abgebrochen."
	return true

func display_text() -> String:
	match stage:
		Stage.WAITING:
			return "STREIFE\n%02d SEK" % maxi(0, ceili(RESPONSE_DELAY - elapsed))
		Stage.APPROACHING:
			return "STREIFE\nANFAHRT"
		Stage.DEPARTING:
			return "TRANSPORT\nABFAHRT"
		Stage.COMPLETE:
			return "TRANSPORT\nBEENDET"
		Stage.IDLE:
			return "FUNK\nBEREIT"
	return "STREIFE\nABHOLUNG"

func spawn_patrol() -> bool:
	for car in scene.traffic.cars:
		if source.surrender_stop:
			if absf(car.position.x - 9.05) < 2 and absf(car.position.z - 56) < 8:
				return false
		elif car.position.x < 4 and car.position.z > 40:
			return false
	patrol = TrafficCar.new()
	patrol.is_patrol = true
	patrol.driver_name = "Polizist Weber"
	patrol.plate_number = "POL 211"
	patrol.body_color = "e0e5e4"
	patrol.model_name = "Streifenwagen"
	patrol.start_z = 56
	scene.traffic.add_child(patrol)
	scene.traffic.cars.append(patrol)
	patrol.state = TrafficCar.State.PULLING_OVER
	# Roadside stops can queue traffic back to the normal spawn. Approach along
	# the curb instead, keeping the existing second-space destination.
	if source.surrender_stop:
		patrol.position.x = 9.05
	# Pass the occupied first space on its curb side, away from the driver.
	patrol.set_route([patrol.position, Vector3(2, 0.08, 28), Vector3(4, 0.08, 22), Vector3(9.05, 0.08, 15), Vector3(9.05, 0.08, 0), Vector3(7.1, 0.08, -5)])
	if source.surrender_stop:
		patrol.set_route([patrol.position, Vector3(9.05, 0.08, 30), Vector3(9.05, 0.08, 0), Vector3(7.1, 0.08, -5)])
	for i in range(patrol.route.point_count):
		if patrol.route.get_point_position(i).x > 9:
			patrol.route.set_point_in(i, Vector3(0, 0, 1.2))
			patrol.route.set_point_out(i, Vector3(0, 0, -1.2))
	var blue := patrol.material("315d87")
	for x in [-0.91, 0.91]:
		patrol.piece(Vector3(x, 0.85, 0), Vector3(0.025, 0.17, 3.6), blue)
	patrol.piece(Vector3(0, 1.75, 0.1), Vector3(1.25, 0.12, 0.35), patrol.material("25457b"))
	patrol.piece(Vector3(-0.4, 1.84, 0.1), Vector3(0.3, 0.12, 0.25), patrol.material("719bdf"))
	patrol.piece(Vector3(0.4, 1.84, 0.1), Vector3(0.3, 0.12, 0.25), patrol.material("719bdf"))
	officer = patrol.driver
	officer.torso.material_override = patrol.material("365a78")
	for i in [2, 3]:
		officer.limbs[i].get_child(0).material_override = patrol.material("365a78")
	Visuals.box(officer.rig, Vector3(0, 1.81, -0.01), Vector3(0.34, 0.08, 0.37), "d9e0df")
	stage = Stage.APPROACHING
	report = "Streife unterwegs zu Stellplatz 2."
	return true

func set_walk(points: Array[Vector3]) -> void:
	waypoints = points
	waypoint = 0

func walk(actor: Node3D, delta: float, speed := 1.6) -> bool:
	if waypoint >= waypoints.size():
		for i in [0, 1]:
			actor.limbs[i].rotation.x = 0
		return true
	var destination := waypoints[waypoint]
	var diff := destination - actor.global_position
	if diff.length() < 0.05:
		waypoint += 1
		return false
	actor.global_position = actor.global_position.move_toward(destination, speed * delta)
	actor.rotation.y = atan2(-diff.x, -diff.z)
	for i in [0, 1]:
		actor.limbs[i].rotation.x = sin(elapsed * 8 + i * PI) * 0.35
	return false

func _physics_process(delta: float) -> void:
	elapsed += delta
	if not active():
		return
	if not is_instance_valid(source) or not is_instance_valid(suspect):
		report = "Abholung beendet: Ziel nicht mehr verfuegbar."
		stage = Stage.COMPLETE
		return
	match stage:
		Stage.WAITING:
			if elapsed >= RESPONSE_DELAY:
				spawn_patrol()
		Stage.APPROACHING:
			if patrol.state == TrafficCar.State.PARKED:
				officer.request_exit()
				stage = Stage.EXITING
		Stage.EXITING:
			if officer.state == officer.State.OUTSIDE:
				set_walk(approach_suspect())
				stage = Stage.WALKING
		Stage.WALKING:
			if walk(officer, delta):
				suspect.reparent(scene, true)
				suspect.collider.disabled = true
				set_walk(escort_suspect())
				stage = Stage.ESCORTING
		Stage.ESCORTING:
			var done := walk(suspect, delta, 1.35)
			var follow := suspect.global_position + Vector3(0, 0, 0.85)
			officer.global_position = officer.global_position.move_toward(follow, delta * 1.8)
			officer.rotation.y = suspect.rotation.y
			for i in [0, 1]:
				officer.limbs[i].rotation.x = sin(elapsed * 8 + i * PI) * 0.35
			if done:
				for part in patrol.parts:
					if part.kind == "passenger_door":
						part.toggle()
				boarding_time = 0
				boarding_start = suspect.global_position
				stage = Stage.BOARDING
		Stage.BOARDING:
			boarding_time = minf(1, boarding_time + delta / 2.0)
			suspect.global_position = boarding_start.lerp(patrol.to_global(Vector3(0.43, 0.12, 0.65)), smoothstep(0, 1, boarding_time))
			suspect.rig.scale = Vector3.ONE * lerpf(1, 0.78, boarding_time)
			if boarding_time >= 1:
				suspect.reparent(patrol, true)
				suspect.state = suspect.State.IN_CUSTODY
				suspect.rotation = Vector3.ZERO
				for i in [0, 1]:
					suspect.limbs[i].rotation.x = 0.95
				for part in patrol.parts:
					if part.kind == "passenger_door" and part.opened:
						part.toggle()
				set_walk([Vector3(8.6, 0, -1), Vector3(5, 0, -1), patrol.to_global(officer.outside)])
				stage = Stage.RETURNING
		Stage.RETURNING:
			if walk(officer, delta):
				officer.request_enter()
				stage = Stage.ENTERING
		Stage.ENTERING:
			if officer.can_drive() and patrol.all_parts_closed():
				patrol.release()
				stage = Stage.DEPARTING
				report = "Person uebernommen. Streife faehrt ab."
		Stage.DEPARTING:
			if not is_instance_valid(patrol) or patrol.state == TrafficCar.State.FINISHED:
				scene.traffic.in_custody[source.driver_name] = true
				# Prototype cleanup: impound the empty source car without a tow truck.
				source.state = TrafficCar.State.FINISHED
				source.visible = false
				stage = Stage.COMPLETE
				report = "Transport abgeschlossen. Fahrzeug vorlaeufig verwahrt."
				if scene.traffic.controlled_car == source:
					scene.traffic.controlled_car = null

func approach_suspect() -> Array[Vector3]:
	var at: Vector3 = suspect.global_position
	var points: Array[Vector3] = [Vector3(5, 0, -1)]
	if absf(at.x - 5) > 0.5:
		var rear_z: float = source.global_position.z + source.body_length / 2 + 2
		points.append(Vector3(5, 0, rear_z))
		points.append(Vector3(at.x, 0, rear_z))
	points.append(Vector3(at.x, 0, at.z))
	return points

func escort_suspect() -> Array[Vector3]:
	var at: Vector3 = suspect.global_position
	var points: Array[Vector3] = []
	if absf(at.x - 5) > 0.5:
		var rear_z: float = source.global_position.z + source.body_length / 2 + 2
		points.append(Vector3(at.x, 0, rear_z))
		points.append(Vector3(5, 0, rear_z))
	points.append_array([Vector3(5, 0, -1), Vector3(8.6, 0, -1), Vector3(8.6, 0, -5)])
	return points
