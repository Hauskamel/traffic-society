## Integrationsprüfung: departure.
## Start über Godot --script; fehlgeschlagene Bedingungen ergeben Exitcode 1.

extends SceneTree
var failures: Array[String] = []


## Startet den Testlauf verzögert nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Sammelt eine fehlgeschlagene Bedingung und gibt den zugehörigen Fehler aus.
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		car.state = car.State.PARKED
		check(car.driver.request_exit(), "Exit must work")
		for i in range(300):
			car.driver._physics_process(1.0 / 60.0)
		check(car.driver.request_enter(), "Entry-only command must work")
		for i in range(300):
			car.driver._physics_process(1.0 / 60.0)
			car._physics_process(1.0 / 60.0)
		check(car.state == car.State.PARKED, "Entry-only command must not drive off")
		car.driver.request_exit()
		for i in range(300):
			car.driver._physics_process(1.0 / 60.0)
		check(car.request_departure(), "Outside driver must accept combined departure")
		for i in range(300):
			for part in car.parts:
				part._physics_process(1.0 / 60.0)
			car.driver._physics_process(1.0 / 60.0)
			car._physics_process(1.0 / 60.0)
		check(
			car.state == car.State.LEAVING, "Combined action must automatically depart after entry"
		)
	if failures.is_empty():
		print(
			"PASS: entry-only stays parked and combined outside departure works for all four models"
		)
	quit(0 if failures.is_empty() else 1)
