## Geometrienahe Projektilfläche eines Fahrzeugteils.
## Leitet Treffer an die zentrale Fahrzeugschadensverwaltung weiter.

extends StaticBody3D
var vehicle: Node3D
var surface: MeshInstance3D
var kind := "body"
var zone_id := ""
var damage_state := 0


## Leitet einen Projektiltreffer mit Weltpunkt und Normalen an die Fahrzeugschäden weiter.
func register_hit(point: Vector3, normal: Vector3) -> void:
	vehicle.hit_surfaces.register_damage(self, point, normal)
