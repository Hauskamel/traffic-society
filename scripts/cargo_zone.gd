extends "res://scripts/vehicle_part.gd"
## Interior target, separate from the movable hatch/doors. Never rotates the car.
var floor_mesh: MeshInstance3D

func _ready() -> void:
	super._ready()
	surfaces.clear()
	surfaces.append(floor_mesh)
	collision_layer = 0

func can_use(origin: Vector3) -> bool:
	return vehicle.state == vehicle.State.PARKED and not vehicle.pickup_reserved and vehicle.cargo_accessible() and origin.distance_to(global_position) <= 2.8 and (vehicle.to_local(origin).z > vehicle.body_length / 2.0 - 0.2 or (vehicle.officer_aboard and absf(vehicle.to_local(origin).x) < 0.85))

func toggle() -> bool:
	return false

func _physics_process(_delta: float) -> void:
	collision_layer = 8 if vehicle.state == vehicle.State.PARKED and not vehicle.pickup_reserved and vehicle.cargo_accessible() else 0
	if collision_layer == 0:
		set_highlight(false)
