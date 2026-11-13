extends RefCounted
## Glass transmits a shot with reduced energy. Queries used for aim/UI stay raw.
const Surface = preload("res://game/vehicles/vehicle_hit_surface.gd")
const GLASS_RETENTION := .80
const MAX_GLASS_LAYERS := 16
static func trace(world: World3D, start: Vector3, end: Vector3, mask: int, excluded: Array[RID]) -> Dictionary:
	var ignored: Array[RID] = excluded.duplicate()
	var retention := 1.0
	var panes := 0
	var hit: Dictionary = {}
	for i in range(MAX_GLASS_LAYERS+1):
		var query := PhysicsRayQueryParameters3D.create(start,end,mask,ignored)
		hit = world.direct_space_state.intersect_ray(query)
		if hit.is_empty(): break
		var surface = hit.collider
		if not surface is Surface or surface.kind != "glass" or panes >= MAX_GLASS_LAYERS: break
		surface.register_hit(hit.position,hit.normal)
		ignored.append(surface.get_rid())
		retention *= GLASS_RETENTION
		panes += 1
	return {"hit":hit,"retention":retention,"panes":panes}
