## Prozeduraler Werkzeugkasten mit Deckel, Verschluss und sichtbarem Inhalt.
## Wird von Weltgegenständen und der Detailansicht gemeinsam verwendet.

extends Node3D
const Visuals = preload("res://game/police/police_visuals.gd")
var item: Dictionary
var lid: Node3D
var latch: Node3D
var contents_root: Node3D
var interactive := false
var moving := false


## Erzeugt einen benannten Modellbaustein an der übergebenen Position.
func piece(
	parent: Node3D, at: Vector3, size: Vector3, color: String, token := "body"
) -> MeshInstance3D:
	var mesh := Visuals.box(parent, at, size, color)
	if interactive:
		var body := StaticBody3D.new()
		body.set_meta("part", token)
		var hit := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		hit.shape = shape
		body.add_child(hit)
		mesh.add_child(body)
	return mesh


## Baut das Modell anhand des Behälterzustands und der gewünschten Interaktivität auf.
func configure(data: Dictionary, enable_input := false) -> void:
	item = data
	interactive = enable_input
	piece(self, Vector3(0, -0.25, 0), Vector3(1.5, 0.06, 0.9), "354a54")
	for x in [-0.72, 0.72]:
		piece(self, Vector3(x, -0.08, 0), Vector3(0.06, 0.3, 0.9), "617b83")
	for z in [-0.42, 0.42]:
		piece(self, Vector3(0, -0.08, z), Vector3(1.4, 0.3, 0.06), "617b83")
	lid = Node3D.new()
	lid.position = Vector3(0, 0.09, -0.45)
	add_child(lid)
	piece(lid, Vector3(0, 0, 0.45), Vector3(1.52, 0.08, 0.92), "718e95", "lid")
	for x in [-0.2, 0.2]:
		piece(lid, Vector3(x, 0.11, 0.45), Vector3(0.06, 0.18, 0.07), "c4b384", "lid")
	piece(lid, Vector3(0, 0.21, 0.45), Vector3(0.46, 0.06, 0.07), "c4b384", "lid")
	latch = Node3D.new()
	latch.position = Vector3(0, 0.08, 0.485)
	add_child(latch)
	piece(latch, Vector3(0, -0.05, 0), Vector3(0.22, 0.17, 0.045), "d3b86f", "latch")
	contents_root = Node3D.new()
	add_child(contents_root)
	for inside in item.contents.items:
		var tool := Node3D.new()
		tool.name = inside.icon
		contents_root.add_child(tool)
		tool.position = Vector3(-0.33 if inside.icon == "hammer" else 0.25, -0.15, 0)
		build_tool(tool, inside.icon)
		if interactive:
			var body := StaticBody3D.new()
			body.set_meta("part", inside.id)
			tool.add_child(body)
			var hit := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = (
				Vector3(0.40, 0.12, 0.65) if inside.icon == "hammer" else Vector3(0.7, 0.1, 0.17)
			)
			hit.shape = shape
			body.add_child(hit)
	lid.rotation.x = -1.95 if item.opened else 0.0
	latch.rotation.x = -1.2 if item.unlocked else 0.0
	contents_root.visible = item.opened


## Erzeugt das vereinfachte Werkzeug- oder Fundmodell im Behälter.
static func build_tool(parent: Node3D, kind: String) -> void:
	if kind == "hammer":
		Visuals.box(parent, Vector3(0, 0, 0.04), Vector3(0.065, 0.065, 0.54), "a27b4e")
		Visuals.box(parent, Vector3(0, 0.02, -0.23), Vector3(0.34, 0.09, 0.12), "87979c")
		Visuals.box(parent, Vector3(0, 0, 0.28), Vector3(0.08, 0.08, 0.09), "644c36")
	else:
		Visuals.box(parent, Vector3(-0.22, 0, 0), Vector3(0.26, 0.065, 0.085), "343b40")
		Visuals.box(parent, Vector3(0.06, 0, 0), Vector3(0.32, 0.03, 0.09), "bbc7c9")
		var tip := MeshInstance3D.new()
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var top := [
			Vector3(0.22, 0.015, -0.045), Vector3(0.42, 0.015, 0), Vector3(0.22, 0.015, 0.045)
		]
		var bottom := [
			Vector3(0.22, -0.015, -0.045), Vector3(0.42, -0.015, 0), Vector3(0.22, -0.015, 0.045)
		]
		for vertex in [top[0], top[2], top[1], bottom[0], bottom[1], bottom[2]]:
			surface.add_vertex(vertex)
		for i in range(3):
			var next := (i + 1) % 3
			for vertex in [top[i], top[next], bottom[i], bottom[i], top[next], bottom[next]]:
				surface.add_vertex(vertex)
		surface.generate_normals()
		tip.mesh = surface.commit()
		var steel := StandardMaterial3D.new()
		steel.albedo_color = Color("bbc7c9")
		tip.material_override = steel
		parent.add_child(tip)
		Visuals.box(parent, Vector3(-0.08, 0, 0), Vector3(0.025, 0.09, 0.14), "87979c")
		for at in [
			Vector3(0.04, 0.018, 0), Vector3(0.16, 0.018, 0.02), Vector3(0.25, 0.018, -0.01)
		]:
			Visuals.box(parent, at, Vector3(0.055, 0.007, 0.045), "782c2a")
		for x in [-0.3, -0.16]:
			Visuals.box(parent, Vector3(x, 0.036, 0), Vector3(0.018, 0.008, 0.018), "aeb7b5")


## Animiert den Deckel passend zum gespeicherten Öffnungszustand.
func _process(delta: float) -> void:
	if not is_instance_valid(lid):
		return
	lid.rotation.x = move_toward(lid.rotation.x, -1.95 if item.opened else 0.0, delta * 2.8)
	latch.rotation.x = move_toward(latch.rotation.x, -1.2 if item.unlocked else 0.0, delta * 5)
	moving = absf(lid.rotation.x - (-1.95 if item.opened else 0.0)) > 0.01
	contents_root.visible = lid.rotation.x < -0.5
