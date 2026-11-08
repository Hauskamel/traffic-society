extends Node
## Owns temporary camera/time state; UI tweens use real time.
const WORLD_SPEED := 0.18
var scene: Node3D
var camera: Camera3D
var active := false
var previous_speed := 1.0
var transition: Tween

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 55
	add_child(camera)

func enter(car: Node3D) -> void:
	if active:
		return
	active = true
	previous_speed = Engine.time_scale
	Engine.time_scale = previous_speed * WORLD_SPEED
	scene.ui_layer.hide()
	scene.player_avatar.show()
	camera.global_transform = scene.eyes.global_transform
	camera.fov = scene.eyes.fov
	camera.make_current()
	var focus := car.global_position + Vector3(-2, 0, 1)
	var destination := Transform3D(Basis.IDENTITY, focus + Vector3(13, 20, 17)).looking_at(focus, Vector3.UP)
	if is_instance_valid(transition):
		transition.kill()
	transition = create_tween().set_ignore_time_scale(true).set_parallel(true)
	transition.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(camera, "global_transform", destination, 0.55)
	transition.tween_property(camera, "fov", 55.0, 0.55)

func leave() -> void:
	if not active:
		return
	Engine.time_scale = previous_speed
	if is_instance_valid(transition):
		transition.kill()
	transition = create_tween().set_ignore_time_scale(true).set_parallel(true)
	transition.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(camera, "global_transform", scene.eyes.global_transform, 0.4)
	transition.tween_property(camera, "fov", scene.eyes.fov, 0.4)
	transition.chain().tween_callback(finish)

func finish() -> void:
	active = false
	scene.player_avatar.visible = scene.aerial
	scene.eyes.make_current()
	scene.ui_layer.show()

func _exit_tree() -> void:
	if active:
		Engine.time_scale = previous_speed
