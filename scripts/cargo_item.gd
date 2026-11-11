extends "res://scripts/vehicle_part.gd"
var item: Dictionary
var prop: Node3D
var solid: StaticBody3D

func _ready() -> void:
	super._ready()
	kind = "cargo_item"
	title = item.name
	refresh_surfaces()

func refresh_surfaces() -> void:
	surfaces.clear()
	for mesh in prop.find_children("*", "MeshInstance3D", true, false):
		surfaces.append(mesh)

func can_use(origin: Vector3) -> bool:
	var local := vehicle.to_local(origin)
	return prop.visible and vehicle.state == vehicle.State.PARKED and not vehicle.pickup_reserved and vehicle.cargo_accessible() and origin.distance_to(global_position) < 2.8 and (local.z > vehicle.body_length / 2 - 0.35 or (vehicle.officer_aboard and absf(local.x) < 0.8))

func _physics_process(_delta: float) -> void:
	collision_layer = 8 if prop.visible and vehicle.state == vehicle.State.PARKED and vehicle.cargo_accessible() and not vehicle.pickup_reserved else 0
	solid.collision_layer = 4 if prop.visible else 0
	if collision_layer == 0:
		set_highlight(false)
