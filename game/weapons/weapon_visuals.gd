extends RefCounted
## Low-poly G19 silhouette, sized in metres; no external assets required.
const Visuals = preload("res://game/police/police_visuals.gd")
static func build(parent: Node3D, kind: String) -> Node3D:
	var gun := Node3D.new()
	parent.add_child(gun)
	var taser := kind == "taser"
	var frame := "d5b438" if taser else "252a2d"
	Visuals.box(gun, Vector3(0, 0.025, -0.035), Vector3(0.031, 0.032, 0.185 if not taser else 0.16), "353c41")
	Visuals.box(gun, Vector3(0, -0.001, -0.025), Vector3(0.032, 0.025, 0.15), frame)
	var grip := Visuals.box(gun, Vector3(0, -0.055, 0.027), Vector3(0.031, 0.085, 0.039), frame)
	grip.rotation.x = -0.23
	Visuals.box(gun, Vector3(0, -0.1, 0.018), Vector3(0.035, 0.009, 0.043), "171d21")
	# Open rectangular trigger guard with a separate trigger.
	Visuals.box(gun, Vector3(0, -0.035, -0.024), Vector3(0.012, 0.035, 0.007), frame)
	Visuals.box(gun, Vector3(0, -0.05, -0.003), Vector3(0.014, 0.007, 0.047), frame)
	Visuals.box(gun, Vector3(0, -0.025, 0.001), Vector3(0.007, 0.023, 0.007), "12191e")
	Visuals.box(gun, Vector3(0, 0.046, 0.039), Vector3(0.024, 0.008, 0.012), "11181b")
	Visuals.box(gun, Vector3(0, 0.046, -0.109), Vector3(0.005, 0.008, 0.009), "c4cbc6")
	Visuals.box(gun, Vector3(0, 0.023, -0.129), Vector3(0.013, 0.013, 0.003), "080e12")
	for i in range(5):
		for x in [-0.016, 0.016]:
			Visuals.box(gun, Vector3(x, 0.025, 0.012 + i * 0.006), Vector3(0.002, 0.027, 0.002), "151d23")
	if taser:
		Visuals.box(gun, Vector3(0, 0.015, -0.105), Vector3(0.045, 0.055, 0.045), "d5b438")
		for x in [-0.012, 0.012]:
			Visuals.box(gun, Vector3(x, 0.015, -0.13), Vector3(0.01, 0.012, 0.003), "171d21")
	return gun
