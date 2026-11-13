## Nicht interaktiver Ladeboden als Teil der Fahrzeugkulisse.
## Ersetzt die frühere pauschale Durchsuchung durch einzelne Gegenstandsziele.

extends "res://game/vehicles/vehicle_part.gd"
var floor_mesh: MeshInstance3D


## Initialisiert den Ladeboden und deaktiviert dessen frühere Gesamtinteraktion.
func _ready() -> void:
	super._ready()
	surfaces.clear()
	surfaces.append(floor_mesh)
	collision_layer = 0


## Prüft Entfernung und zustandsabhängige Bedienbarkeit des Interaktionsziels.
func can_use(_origin: Vector3) -> bool:
	return false  # Floor is scenery; only individual cargo items are interactive.


## Lehnt die frühere Gesamtinteraktion mit dem Ladeboden grundsätzlich ab.
func toggle() -> bool:
	return false


## Hält die pauschale Ladeboden-Interaktion dauerhaft deaktiviert.
func _physics_process(_delta: float) -> void:
	collision_layer = 0
