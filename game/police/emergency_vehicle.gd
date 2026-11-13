## Einsatzfahrzeug mit sichtbarer Besatzung, Blaulicht und begrenztem Spaziergang.
## Rettungs-/Kampfaufgaben sind noch nicht implementiert; die Figuren bleiben vor Ort.
extends "res://game/vehicles/traffic_car.gd"
const Beacons = preload("res://game/police/blue_beacons.gd")
var service := "backup"
var crew: Array[Node3D] = []
var blue_lights: Node3D
var crew_exit_started := false
var walk_clock := 0.0
var walk_indices: Array[int] = []


## Ergänzt das gemeinsame Fahrzeug um Einsatzdarstellung, Sitzplätze und Besatzung.
func _ready() -> void:
	super._ready()
	crew.append(driver)
	var count := 4 if service == "fire" else 2
	if service == "fire":
		driver.seat.x = -.55
	for i in range(1, count):
		var colleague := DriverActor.new()
		var rear := service == "fire" and i == 3
		colleague.door = driver_door
		for part in parts:
			if (
				(rear and part.kind == "trunk")
				or (not rear and i == 1 and part.kind == "passenger_door")
			):
				colleague.door = part.pivot
				break
		colleague.seat = Vector3(.55 if i == 1 else 0, driver.seat.y, driver.seat.z)
		if rear:
			colleague.seat = Vector3(0, .05, 1.0)
		colleague.outside = Vector3(2.3 if i == 1 else -2.3, -.08, driver.seat.z + i * .65)
		if rear:
			colleague.outside = Vector3(-2.3, -.08, body_length / 2 + .7)
		add_child(colleague)
		crew.append(colleague)
	for i in range(crew.size()):
		var actor = crew[i]
		actor.transition_duration = .9
		actor.reset()
		walk_indices.append(i)
		var color := (
			"305879" if service == "backup" else ("dc7730" if service == "medical" else "b69c45")
		)
		for region in actor.region_meshes:
			if region != "head":
				actor.region_meshes[region].material_override = material(color)
		if service == "fire":
			actor.block(Vector3(0, .18, 0), Vector3(.32, .09, .30), "e5c350", actor.head)
	blue_lights = Beacons.new()
	add_child(blue_lights)
	blue_lights.position = Vector3(
		0, 2.38 if model_kind == "van" else 1.75, -1 if model_kind == "van" else .1
	)
	var stripe := material({"backup": "315d87", "medical": "ed7e2c", "fire": "e6e7d6"}[service])
	for side in [-1, 1]:
		piece(Vector3(side * .96, 1.05, .2), Vector3(.025, .18, body_length - .4), stripe)
	var label := Label3D.new()
	label.text = {"backup": "POLIZEI", "medical": "RETTUNG", "fire": "FEUERWEHR"}[service]
	label.modulate = Color("193749") if service != "fire" else Color("f2f0df")
	label.font_size = 42
	label.pixel_size = .012
	label.position = Vector3(-.99, 1.45, .5)
	label.rotation.y = -PI / 2
	add_child(label)
	if service == "medical":
		for side in [-1, 1]:
			piece(Vector3(side * .98, 1.7, .5), Vector3(.025, .44, .14), material("d64f2d"))
			piece(Vector3(side * .98, 1.7, .5), Vector3(.025, .14, .44), material("d64f2d"))
		build_stretcher()
	if service == "fire":
		build_ladder()


## Baut eine sichtbare Trage im begehbaren hinteren Ladebereich auf.
func build_stretcher() -> void:
	var stretcher := Node3D.new()
	stretcher.name = "Stretcher"
	add_child(stretcher)
	piece(Vector3(0, 1.05, .65), Vector3(.65, .12, 1.95), material("dfb765"), stretcher)
	for x in [-.35, .35]:
		piece(Vector3(x, 1.08, .65), Vector3(.04, .05, 2.1), material("bfc6c5"), stretcher)
		for z in [-.05, 1.35]:
			piece(Vector3(x, .9, z), Vector3(.05, .28, .05), material("bfc6c5"), stretcher)
			piece(Vector3(x, .76, z), Vector3(.1, .1, .12), material("202a30"), stretcher)


## Kennzeichnet das große Feuerwehrfahrzeug durch Dachleiter und Gerätefächer.
func build_ladder() -> void:
	for x in [-.3, .3]:
		piece(Vector3(x, 2.48, .7), Vector3(.07, .07, 3.8), material("bec7c4"))
	for i in range(10):
		piece(Vector3(0, 2.48, -1 + i * .37), Vector3(.6, .045, .045), material("bec7c4"))
	for side in [-1, 1]:
		for z in [.5, 1.65, 2.7]:
			piece(Vector3(side * .94, 1.25, z), Vector3(.04, .85, .95), material("747e80"))


## Bewegt Besatzungen nach kurzem Aussteigen auf getrennten sicheren Seitenwegen.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state != State.PARKED:
		return
	if not crew_exit_started:
		crew_exit_started = true
		if service == "medical":
			for part in parts:
				if part.kind == "trunk":
					part.opened = true
		for actor in crew:
			if not actor.is_injured():
				actor.request_exit()
	walk_clock += delta
	for i in range(crew.size()):
		var actor = crew[i]
		if actor.is_injured() or actor.arrested or actor.state != actor.State.OUTSIDE:
			continue
		var side := 1.0 if i == 1 else -1.0
		var points: Array[Vector3] = [
			Vector3(side * 2.45, 0, -2.2),
			Vector3(side * 2.8, 0, -.5),
			Vector3(side * 2.4, 0, 1.6),
			Vector3(side * 2.8, 0, 2.6)
		]
		var target := to_global(points[walk_indices[i] % points.size()])
		target.y = 0
		var step: Vector3 = (
			actor.global_position.move_toward(target, delta * 1.25) - actor.global_position
		)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = actor.collider.shape
		query.transform = Transform3D(
			Basis.IDENTITY, actor.global_position + step + Vector3(0, .96, 0)
		)
		query.collision_mask = 1 | 2 | 4
		query.exclude = [actor.body.get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			walk_indices[i] += 1
			continue
		actor.global_position += step
		if step.length_squared() > .00001:
			actor.global_rotation.y = atan2(-step.x, -step.z)
		for leg in range(2):
			actor.limbs[leg].rotation.x = sin(walk_clock * 7 + i + leg * PI) * .3
		if actor.global_position.distance_to(target) < .1:
			walk_indices[i] += 1
