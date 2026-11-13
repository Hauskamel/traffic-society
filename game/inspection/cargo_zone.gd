extends "res://game/vehicles/vehicle_part.gd"
## Interior target, separate from the movable hatch/doors. Never rotates the car.
var floor_mesh: MeshInstance3D

func _ready() -> void:
	super._ready()
	surfaces.clear()
	surfaces.append(floor_mesh)
	collision_layer = 0

func can_use(_origin: Vector3) -> bool:
	return false # Floor is scenery; only individual cargo items are interactive.

func toggle() -> bool:
	return false

func _physics_process(_delta: float) -> void:
	collision_layer = 0
