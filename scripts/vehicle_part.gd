extends Area3D
## A named physical target under the crosshair, with a reversible hinge animation.
var vehicle: Node3D
var pivot: AnimatableBody3D
var title := "Fahrertuer"
var kind := "driver_door"
var axis := Vector3.UP
var open_angle := -1.15
var opened := false
var driver_was_busy := false
var highlighted := false
var surfaces: Array[MeshInstance3D] = []
var highlight_material: StandardMaterial3D

func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1.0, 0.72, 0.18, 0.4)
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for child in pivot.get_children():
		if child is MeshInstance3D:
			surfaces.append(child)

func set_highlight(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	for mesh in surfaces:
		mesh.material_overlay = highlight_material if value else null

func can_use(origin: Vector3) -> bool:
	if vehicle.state != vehicle.State.PARKED or vehicle.driver.is_busy():
		return false
	if origin.distance_to(global_position) > 2.8:
		return false
	var local := vehicle.to_local(origin)
	match kind:
		"driver_door":
			return local.x < -0.95
		"passenger_door":
			return local.x > 0.95
		"trunk":
			return local.z > vehicle.body_length / 2.0 - 0.2
	return false

func toggle() -> bool:
	if vehicle.state != vehicle.State.PARKED or vehicle.driver.is_busy():
		return false
	opened = not opened
	return true

func angle() -> float:
	return pivot.rotation.x if axis == Vector3.RIGHT else pivot.rotation.y

func is_closed() -> bool:
	return absf(angle()) < 0.01 and not opened

func reset() -> void:
	opened = false
	pivot.rotation = Vector3.ZERO
	pivot.collision_layer = 4
	set_highlight(false)

func _physics_process(delta: float) -> void:
	if kind == "driver_door" and vehicle.driver.is_busy():
		driver_was_busy = true
		return
	if driver_was_busy:
		driver_was_busy = false
		opened = absf(angle()) > 0.1
	var target := open_angle if opened else 0.0
	var next := move_toward(angle(), target, delta * 3.5)
	if axis == Vector3.RIGHT:
		pivot.rotation.x = next
	else:
		pivot.rotation.y = next
	# Keep the same forgiving collision behaviour as the driver's exit animation.
	pivot.collision_layer = 0 if absf(next - target) > 0.001 else 4
