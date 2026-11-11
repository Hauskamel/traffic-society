extends SceneTree
var failures: Array[String] = []
var lab: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://body-lab-"+name+".png")
func run() -> void:
	lab = load("res://scenes/body_lab/body_lab.tscn").instantiate()
	root.add_child(lab)
	check(lab.actors.size() == 2, "Lab creates standing and moving actors")
	for actor in lab.actors:
		check(actor.bodies.size() == 11, "Each actor has 11 simulated regions")
		check(actor.find_children("*","Generic6DOFJoint3D",true,false).size() == 10, "Regions are connected by ten physical joints")
		check(actor.find_children("*","AnimationPlayer",true,false).is_empty(), "No prerecorded animation drives the ragdoll")
	check(is_equal_approx(lab.strength_slider.value,3.0) and is_equal_approx(lab.injury_slider.value,.95), "Default impulse is 3 N s and regional strength loss is 95 percent")
	for actor in lab.actors:
		for side in ["left","right"]:
			check(not actor.bodies.has(side+"_foot") and actor.bodies[side+"_shin"].has_node("FootCollision"), "Foot belongs to lower-leg rigid body")
			check(actor.bodies[side+"_forearm"].has_node("HandCollision"), "Hand belongs to forearm rigid body")
	await frames(180)
	var standing = lab.actors[0]
	var running = lab.actors[1]
	check(standing.bodies.pelvis.global_position.y > .8 and standing.bodies.pelvis.linear_velocity.length() < .15, "Uninjured standing actor stabilizes")
	check(running.bodies.pelvis.global_position.y > .7 and absf(running.bodies.pelvis.global_position.z) > .5, "Moving actor actually travels while upright")
	for side in ["left","right"]:
		var direction := Vector3.LEFT if side == "left" else Vector3.RIGHT
		for suffix in ["shin", "forearm"]:
			var body: RigidBody3D = standing.bodies[side+"_"+suffix]
			var point: Vector3 = body.get_node("FootVisual" if suffix == "shin" else "HandVisual").global_position
			var query := PhysicsRayQueryParameters3D.create(point+direction,point-direction*.05,4)
			var hit: Dictionary = lab.get_world_3d().direct_space_state.intersect_ray(query)
			check(not hit.is_empty() and hit.collider == body and hit.collider.get_meta("region") == side+"_"+suffix, "Foot/hand collision selects owning compound region")
	await capture("before")
	var at: Vector3 = standing.bodies.left_thigh.global_position
	lab.comparison_hit()
	check(standing.bodies.left_thigh.global_position.is_equal_approx(at), "Hit applies impulse rather than teleporting pose")
	check(is_equal_approx(standing.muscle("left_thigh"),.05) and is_equal_approx(standing.muscle("left_shin"),.05), "Thigh injury weakens affected leg chain")
	check(standing.muscle("right_thigh") == 1 and standing.muscle("left_upper_arm") == 1, "Other regions retain their own strength")
	check(running.last_hit.pelvis_velocity.length() > standing.last_hit.pelvis_velocity.length()+.3, "Same hit starts with different measured movement context")
	await frames(60)
	await capture("reaction")
	await frames(180)
	check(standing.bodies.pelvis.global_position.y > .7, "Standing actor can compensate with healthy support leg")
	check(running.bodies.pelvis.global_position.y < standing.bodies.pelvis.global_position.y-.25, "Motion and reduced support produce different physical outcome")
	await capture("after")
	for actor in lab.actors:
		for body in actor.bodies.values():
			check(body.global_position.is_finite() and body.linear_velocity.is_finite() and body.global_position.length() < 15, "Simulation remains bounded and finite")
	lab.reset_actors()
	await frames(150)
	standing = lab.actors[0]
	standing.receive_hit("left_upper_arm",standing.bodies.left_upper_arm.global_position,Vector3(0,0,-3))
	await frames(120)
	check(standing.muscle("left_forearm") < .3 and standing.muscle("left_thigh") == 1, "Arm injury affects arm chain rather than leg")
	check(standing.bodies.pelvis.global_position.y > .75, "Arm injury retains standing leg support")
	lab.reset_actors()
	await frames(600)
	check(lab.actors[0].bodies.pelvis.global_position.y > .8 and lab.actors[1].bodies.pelvis.global_position.y > .7, "Uninjured rigs remain upright through repeated direction changes")
	lab.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: articulated rigid bodies, stable rest/locomotion, regional strength propagation, context-sensitive thigh response, arm isolation, reset and bounded physics")
	quit(0 if failures.is_empty() else 1)
