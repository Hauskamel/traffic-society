extends StaticBody3D
## Shot-only shape attached to a visible mesh; movement uses existing colliders.
var vehicle: Node3D
var surface: MeshInstance3D
var kind := "body"
var zone_id := ""

func register_hit(point: Vector3, normal: Vector3) -> void:
	vehicle.hit_surfaces.add_mark(self, point, normal)
