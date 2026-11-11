extends Node
## Reusable player damage state; presentation is owned by the scene.
signal changed(value: float)
signal died
const MAX_HEALTH := 100.0
var value := MAX_HEALTH
var dead := false
var hit_feedback := 0.0
func receive_hit(amount: float, _point := Vector3.ZERO) -> void:
	if dead or amount <= 0: return
	value = maxf(0.0,value-amount)
	hit_feedback = 1.0
	changed.emit(value)
	if value == 0:
		dead = true
		died.emit()
func _process(delta: float) -> void:
	hit_feedback = move_toward(hit_feedback,0,delta/maxf(Engine.time_scale,.001)*2)
