## Wechselndes Blaulicht für Einsatzfahrzeuge ohne teure Lichtschatten.
extends Node3D
var clock := 0.0
var lamps: Array[MeshInstance3D] = []
var lights: Array[OmniLight3D] = []
var enabled := true


## Erzeugt zwei getrennt schaltbare Leuchten auf dem Dach.
func _ready() -> void:
	for side in [-1, 1]:
		var lamp := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(.32, .14, .28)
		lamp.mesh = shape
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lamp.material_override = material
		add_child(lamp)
		lamp.position.x = side * .47
		lamps.append(lamp)
		var light := OmniLight3D.new()
		light.light_color = Color("286fff")
		light.omni_range = 7
		light.shadow_enabled = false
		lamp.add_child(light)
		lights.append(light)
	_process(0)


## Lässt die beiden Dachleuchten abwechselnd sichtbar aufblitzen.
func _process(delta: float) -> void:
	clock += delta
	for i in range(lamps.size()):
		var on := enabled and (int(clock * 7) % 2 == i)
		lamps[i].material_override.albedo_color = Color("438fff") if on else Color("153464")
		lights[i].light_energy = 2.2 if on else 0
