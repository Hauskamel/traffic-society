## Sitzungsweite Einsatzanforderungen mit festen Kontingenten und verzögertem Spawn.
## Einsatzkräfte kommen an und spazieren; fachliche Einsatzziele folgen später.
extends Node
signal changed
const Vehicle = preload("res://game/police/emergency_vehicle.gd")
const RESPONSE_SECONDS := 10.0
const LIMITS := {"fire": 1, "medical": 1, "backup": 2}
var scene: Node3D
var used := {"fire": 0, "medical": 0, "backup": 0}
var pending: Array[Dictionary] = []
var units: Array[Node3D] = []
var next_slot := 0


## Liefert das verbleibende Kontingent einschließlich bereits bestellter Einheiten.
func remaining(service: String) -> int:
	return maxi(0, int(LIMITS.get(service, 0)) - int(used.get(service, 0)))


## Reserviert einen Einsatz sofort, damit schnelle Mehrfachklicks kein Limit umgehen.
func request(service: String) -> bool:
	if not LIMITS.has(service) or remaining(service) <= 0:
		return false
	used[service] += 1
	pending.append({"service": service, "remaining": RESPONSE_SECONDS, "slot": next_slot})
	next_slot += 1
	changed.emit()
	return true


## Zählt Wartezeiten herunter und hält belegte Spawnpunkte bis zur Freigabe zurück.
func _physics_process(delta: float) -> void:
	for order in pending.duplicate():
		order.remaining = maxf(0, order.remaining - delta)
		if order.remaining > 0:
			continue
		if spawn_unit(order):
			pending.erase(order)
			changed.emit()


## Erzeugt ein freies Einsatzfahrzeug samt Besatzung auf der Anfahrspur.
func spawn_unit(order: Dictionary) -> bool:
	var start := Vector3(19, .08, 56)
	for car in scene.traffic.cars:
		if car.global_position.distance_to(start) < (car.body_length + 7) / 2 + 2:
			return false
	var unit := Vehicle.new()
	unit.service = order.service
	unit.is_patrol = true
	unit.driver_name = "Einsatz " + str(order.slot + 1)
	unit.model_name = {"backup": "Verstärkung", "medical": "Krankenwagen", "fire": "Feuerwehr"}[
		order.service
	]
	unit.plate_number = "EINSATZ " + str(order.slot + 1)
	unit.model_kind = "sedan" if order.service == "backup" else "van"
	unit.body_color = {"backup": "e4e8e5", "medical": "efede0", "fire": "ba3430"}[order.service]
	unit.body_length = (
		4.2 if order.service == "backup" else (6.6 if order.service == "fire" else 5.5)
	)
	unit.body_height = 1.65 if order.service == "backup" else 2.55
	scene.traffic.add_child(unit)
	scene.traffic.cars.append(unit)
	unit.global_position = start
	for actor in unit.crew:
		actor.reset()
	unit.state = unit.State.PULLING_OVER
	unit.speed = 7.0
	var z: float = 17 - float(order.slot) * 11
	var route: Array[Vector3] = [
		start, Vector3(19, .08, z + 6), Vector3(14.2, .08, z + 3), Vector3(14.2, .08, z)
	]
	unit.set_route(route)
	units.append(unit)
	return true
