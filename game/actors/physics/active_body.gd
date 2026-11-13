## Gegliederter Physikkörper mit regionalem Kraftverlust und prozeduraler Haltung.
## Gemeinsam von Spiel-NPCs und Physiklabor genutzt; Kräfte in N, Impulse in N·s.

extends Node3D
const DEFAULT_IMPULSE := 3.0
const DEFAULT_STRENGTH_LOSS := 0.95
const FOOT_OFFSET := Vector3(0, -.30, -.07)
const HAND_OFFSET := Vector3(0, -.21, 0)
const SPEC := {
	"pelvis": [Vector3(0, 1.02, 0), Vector3(.34, .20, .22), 8.0],
	"torso": [Vector3(0, 1.32, 0), Vector3(.44, .44, .24), 16.0],
	"head": [Vector3(0, 1.68, 0), Vector3(.26, .30, .26), 4.0],
	"left_upper_arm": [Vector3(-.31, 1.27, 0), Vector3(.13, .34, .13), 2.0],
	"left_forearm": [Vector3(-.31, .94, 0), Vector3(.12, .30, .12), 1.2],
	"right_upper_arm": [Vector3(.31, 1.27, 0), Vector3(.13, .34, .13), 2.0],
	"right_forearm": [Vector3(.31, .94, 0), Vector3(.12, .30, .12), 1.2],
	"left_thigh": [Vector3(-.14, .80, 0), Vector3(.16, .40, .17), 5.0],
	"left_shin": [Vector3(-.14, .39, 0), Vector3(.14, .40, .15), 4.0],
	"right_thigh": [Vector3(.14, .80, 0), Vector3(.16, .40, .17), 5.0],
	"right_shin": [Vector3(.14, .39, 0), Vector3(.14, .40, .15), 4.0],
}
var bodies: Dictionary = {}
var strength: Dictionary = {}
var model_scale := 1.0
var posture_enabled := true
var seat_support: Node3D
var dead := false
var collapsed := false
var moving := false
var clock := 0.0
var heading := 0.0
var total_mass := 0.0
var balance := 1.0
var support_memory := 1.0
var motion_velocity := Vector3.ZERO
var last_hit: Dictionary = {}
var spawn := Vector3.ZERO
var flash_time := 0.0
var highlighted_region := ""


## Baut die Körpersegmente, Kollisionen und anatomisch begrenzten Gelenke auf.
func _ready() -> void:
	spawn = global_position
	for region in SPEC:
		var data: Array = SPEC[region]
		var body := RigidBody3D.new()
		body.name = region
		body.mass = data[2]
		body.collision_layer = 4
		body.collision_mask = 1 | 4 | 64
		body.can_sleep = false
		body.linear_damp = 1.0
		body.angular_damp = 3.0
		body.set_meta("actor", self)
		body.set_meta("region", region)
		add_child(body)
		body.position = data[0] * model_scale
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = data[1] * model_scale
		collision.shape = shape
		body.add_child(collision)
		var visual := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = data[1] * model_scale
		visual.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = (
			Color("b59a71") if region.contains("arm") or region == "torso" else Color("425b70")
		)
		if region == "head":
			material.albedo_color = Color("d7b49a")
		visual.material_override = material
		body.add_child(visual)
		if region.ends_with("_shin"):
			compound_piece(body, "Foot", FOOT_OFFSET, Vector3(.19, .15, .30), "202d38")
		elif region.ends_with("_forearm"):
			compound_piece(body, "Hand", HAND_OFFSET, Vector3(.14, .12, .17), "d7b49a")
		bodies[region] = body
		strength[region] = 1.0
		total_mass += body.mass
	for a in bodies.values():
		for b in bodies.values():
			if a != b:
				a.add_collision_exception_with(b)
	connect_parts("pelvis", "torso", Vector3(0, 1.12, 0), .5)
	connect_parts("torso", "head", Vector3(0, 1.53, 0), .6)
	for side in ["left", "right"]:
		var x := -.14 if side == "left" else .14
		connect_parts("pelvis", side + "_thigh", Vector3(x, 1.0, 0), 1.0)
		connect_parts(side + "_thigh", side + "_shin", Vector3(x, .60, 0), 1.5)
		x = -.31 if side == "left" else .31
		connect_parts("torso", side + "_upper_arm", Vector3(x, 1.45, 0), 1.5)
		connect_parts(side + "_upper_arm", side + "_forearm", Vector3(x, 1.10, 0), 1.5)


## Räumt temporäre Sitzstützen auf.
func _exit_tree() -> void:
	if is_instance_valid(seat_support):
		seat_support.queue_free()


## Ergänzt Mesh und Kollisionsform am bestehenden Starrkörper ohne neues Gelenk.
func compound_piece(
	body: RigidBody3D, label: String, at: Vector3, size: Vector3, color: String
) -> void:
	var collision := CollisionShape3D.new()
	collision.name = label + "Collision"
	var shape := BoxShape3D.new()
	shape.size = size * model_scale
	collision.shape = shape
	collision.position = at * model_scale
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	visual.name = label + "Visual"
	var box := BoxMesh.new()
	box.size = size * model_scale
	visual.mesh = box
	visual.position = at * model_scale
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	visual.material_override = material
	body.add_child(visual)


## Verbindet zwei Körpersegmente mit gesperrter Verschiebung und begrenzten Winkeln.
func connect_parts(a: String, b: String, at: Vector3, limit: float) -> void:
	var joint := Generic6DOFJoint3D.new()
	add_child(joint)
	joint.name = a + "_to_" + b
	joint.position = at * model_scale
	joint.node_a = bodies[a].get_path()
	joint.node_b = bodies[b].get_path()
	joint.exclude_nodes_from_collision = true
	for axis in range(3):
		joint.call(
			"set_flag_" + ["x", "y", "z"][axis], Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true
		)
		joint.call(
			"set_param_" + ["x", "y", "z"][axis], Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0
		)
		joint.call(
			"set_param_" + ["x", "y", "z"][axis], Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0
		)
		joint.call(
			"set_flag_" + ["x", "y", "z"][axis], Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true
		)
		joint.call(
			"set_param_" + ["x", "y", "z"][axis],
			Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,
			-limit if axis == 0 else -.4
		)
		joint.call(
			"set_param_" + ["x", "y", "z"][axis],
			Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT,
			limit if axis == 0 else .4
		)

	if b.ends_with("_upper_arm"):
		# Raised surrender poses must remain free to fall after loss of tone.
		joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -2.6)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 2.6)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -1.2)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 1.2)
		joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -3.0)
		joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 3.0)

	# Knees and elbows flex around one axis; prevent sideways folding and
	# backwards hyperextension. Limits remain active on the passive ragdoll.
	if b.ends_with("_shin") or b.ends_with("_forearm"):
		joint.set_param_x(
			Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -2.3 if b.ends_with("_shin") else -.05
		)
		joint.set_param_x(
			Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, .05 if b.ends_with("_shin") else 2.3
		)
		for axis in ["y", "z"]:
			joint.call("set_param_" + axis, Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -.05)
			joint.call("set_param_" + axis, Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, .05)


## Berechnet die verbleibende Kraft einschließlich geschwächter proximaler Gliedmaßen.
func muscle(region: String) -> float:
	var value: float = strength[region]
	for side in ["left", "right"]:
		if region == side + "_shin":
			value = minf(value, strength[side + "_thigh"])
		if region == side + "_forearm":
			value = minf(value, strength[side + "_upper_arm"])
	return value


## Verringert die regionale Kraft und wendet den Impuls am Welt-Treffpunkt an.
## Schwere Kerntreffer deaktivieren die Haltung; schwere Kopftreffer setzen den Todesstatus.
func receive_hit(
	region: String, point: Vector3, impulse: Vector3, severity := DEFAULT_STRENGTH_LOSS
) -> void:
	if not bodies.has(region):
		return
	var body: RigidBody3D = bodies[region]
	last_hit = {
		"region": region,
		"velocity": body.linear_velocity,
		"pelvis_velocity": bodies.pelvis.linear_velocity,
		"point": point
	}
	strength[region] = maxf(0.0, strength[region] - clampf(severity, 0.0, 1.0))
	# Prototype injury rules: severe head injury is fatal; severe core injury
	# removes whole-body postural control, including previously healthy legs.
	if region == "head" and strength.head <= .1:
		dead = true
	if region in ["head", "torso", "pelvis"] and strength[region] <= .25:
		collapsed = true
	body.apply_impulse(impulse, point - body.global_position)
	flash_time = .35
	highlighted_region = region


## Wendet begrenzte Feder-/Dämpfungskräfte für die Zielposition und Orientierung an.
func drive(region: String, at: Vector3, rotation_target: Basis, gain: float, delta: float) -> void:
	var body: RigidBody3D = bodies[region]
	var error: Quaternion = (
		rotation_target.get_rotation_quaternion()
		* body.global_basis.get_rotation_quaternion().inverse()
	)
	if error.w < 0:
		error = -error
	var angle := error.get_angle()
	var dimensions: Vector3 = SPEC[region][1]
	var inertia := body.mass * dimensions.length_squared() / 18.0
	var torque := (error.get_axis() * angle * 70.0 - body.angular_velocity * 14.0) * inertia * gain
	body.apply_torque(torque.limit_length(inertia * 150))
	if region != "pelvis":
		var force: Vector3 = (
			((at - body.global_position) * 65.0 - (body.linear_velocity - motion_velocity) * 12.0)
			* body.mass
			* gain
		)
		body.apply_central_force(force.limit_length(body.mass * 65))
	if body.angular_velocity.length() > 18:
		body.angular_velocity = body.angular_velocity.limit_length(18)
	for mesh in body.get_children():
		if mesh is MeshInstance3D:
			mesh.material_override.emission_enabled = (
				region == highlighted_region and flash_time > 0
			)
			mesh.material_override.emission = Color("dba64a")
			if strength[region] < .5:
				mesh.material_override.albedo_color = mesh.material_override.albedo_color.lerp(
					Color("8b6854"), delta * .15
				)


## Berechnet Stützkraft, Balance und regionale Muskelziele für den gegliederten Körper.
func _physics_process(delta: float) -> void:
	clock += delta
	flash_time = maxf(0, flash_time - delta)
	var pelvis: RigidBody3D = bodies.pelvis
	var left := muscle("left_shin")
	var right := muscle("right_shin")
	var asymmetry := absf(left - right)
	var velocity := Vector2(pelvis.linear_velocity.x, pelvis.linear_velocity.z).length()
	var core := (
		0.0
		if collapsed or dead or not posture_enabled
		else minf(strength.pelvis, minf(strength.torso, strength.head))
	)
	balance = clampf(1.0 - asymmetry * velocity * .75, .05, 1.0) * core
	var near_ground := false
	for side in ["left", "right"]:
		var lower_leg: RigidBody3D = bodies[side + "_shin"]
		if lower_leg.to_global(FOOT_OFFSET).y < .26 and muscle(side + "_shin") > .25:
			near_ground = true
	var upright: float = bodies.torso.global_basis.y.dot(Vector3.UP)
	var capable := pelvis.global_position.y > .48 and upright > -.1
	support_memory = move_toward(support_memory, 1.0 if near_ground else 0.0, delta * 4)
	var support := balance * support_memory if capable else 0.0
	balance = support
	var anchor := spawn
	var desired_velocity := Vector3.ZERO
	if moving:
		anchor.z -= sin(clock * .7) * 2.0
		desired_velocity.z = -cos(clock * .7) * 1.4 * ((left + right) / 2)
		var goal_heading := 0.0 if desired_velocity.z < 0 else PI
		heading = lerp_angle(heading, goal_heading, delta * 2.0)
	anchor.x += (right - left) * .12
	var target_y := spawn.y + 1.02 - asymmetry * .07
	var lift := (
		total_mass
		* (9.8 + (target_y - pelvis.global_position.y) * 65 - pelvis.linear_velocity.y * 9)
	)
	pelvis.apply_central_force(Vector3.UP * clampf(lift, 0, total_mass * 24) * support)
	var horizontal := (
		(anchor - pelvis.global_position) * 20 + (desired_velocity - pelvis.linear_velocity) * 12
	)
	horizontal.y = 0
	pelvis.apply_central_force(
		(
			horizontal.limit_length(8)
			* total_mass
			* .65
			* core
			* maxf(left, right)
			* (1.0 if capable else .03)
		)
	)
	motion_velocity = desired_velocity
	var basis := Basis(Vector3.UP, heading)
	var phase := clock * 7.0
	var stride := clampf(velocity / 1.4, 0, 1) if moving else 0.0
	var passive := core * (1.0 if capable else .04)
	var root := pelvis.global_position
	root.x = anchor.x
	root.z = anchor.z
	for region in ["pelvis", "torso", "head"]:
		var offset: Vector3 = SPEC[region][0] - SPEC.pelvis[0]
		drive(region, root + basis * offset, basis, muscle(region) * core * passive, delta)
	for side in ["left", "right"]:
		var x := -.14 if side == "left" else .14
		var wave := sin(phase + (0 if side == "left" else PI))
		var hip := basis * Basis(Vector3.RIGHT, wave * .40 * stride)
		var shin := hip * Basis(Vector3.RIGHT, -maxf(0, -wave) * .65 * stride)
		var hip_at := root + basis * Vector3(x, -.02, 0)
		var knee_at := hip_at + hip * Vector3(0, -.40, 0)
		drive(
			side + "_thigh",
			hip_at + hip * Vector3(0, -.20, 0),
			hip,
			muscle(side + "_thigh") * passive,
			delta
		)
		drive(
			side + "_shin",
			knee_at + shin * Vector3(0, -.21, 0),
			shin,
			muscle(side + "_shin") * passive,
			delta
		)
		var arm := basis * Basis(Vector3.RIGHT, -wave * .22 * stride)
		var shoulder := root + basis * Vector3(-.31 if side == "left" else .31, .43, 0)
		drive(
			side + "_upper_arm",
			shoulder + arm * Vector3(0, -.18, 0),
			arm,
			muscle(side + "_upper_arm") * passive,
			delta
		)
		drive(
			side + "_forearm",
			shoulder + arm * Vector3(0, -.51, 0),
			arm,
			muscle(side + "_forearm") * passive,
			delta
		)
