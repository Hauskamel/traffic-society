## Integrationsprüfung: inventory.
## Start über Godot --script; fehlgeschlagene Bedingungen ergeben Exitcode 1.

extends SceneTree
const Inventory = preload("res://game/inventory/item_inventory.gd")
var failures: Array[String] = []


## Sammelt eine fehlgeschlagene Bedingung und gibt den zugehörigen Fehler aus.
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


## Startet den Testlauf verzögert nach Aufbau des SceneTree.
func _initialize() -> void:
	call_deferred("run")


## Prüft den vollständigen Szenarioablauf und beendet den Prozess mit dem gesammelten Ergebnis.
func run() -> void:
	var player = Inventory.for_player()
	var npc = Inventory.for_driver("Bobby Mayer")
	var id: String = npc.items[0].id
	player.capacity = 1
	check(
		not npc.transfer_to(id, player) and npc.items.size() == 3,
		"Full inventory must preserve the original item"
	)
	player.capacity = 12
	check(npc.transfer_to(id, player), "Taking an item must work")
	check(npc.items.size() == 2 and player.items.size() == 7, "Transfer must move, not duplicate")
	check(not npc.transfer_to(id, player), "Duplicate take must fail")
	check(player.transfer_to(id, npc), "Returning must restore original item")
	check(
		npc.items.size() == 3 and player.items.size() == 6, "Return must preserve total item count"
	)
	var scene = load("res://game/world/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.traffic.set_physics_process(false)
	for car in scene.traffic.cars:
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
	var bobby = scene.traffic.cars[0]
	var original_inventory = bobby.inventory
	check(
		original_inventory.transfer_to(id, scene.player_inventory),
		"Taking from encounter must work"
	)
	bobby.state = bobby.State.FINISHED
	scene.traffic._physics_process(0)
	check(scene.traffic.spawn_next(52), "Finished driver must be able to return")
	var returned = scene.traffic.cars.back()
	check(
		returned.inventory == original_inventory and returned.inventory.items.size() == 2,
		"Respawn must reuse inventory without recreating taken items"
	)
	for car in scene.traffic.cars:
		check(
			car.inventory != null and car.inventory.items.size() <= 3,
			"Every fixed driver must have an inventory"
		)
		car.set_physics_process(false)
		car.driver.set_physics_process(false)
		check(not car.driver.begin_search(), "Seated driver must not be searchable")
		check(car.driver.request_exit(), "Every driver must be able to exit")
		for i in range(300):
			car.driver._physics_process(1.0 / 60.0)
		check(car.driver.begin_search(), "Every outside driver must accept search")
		check(not car.driver.begin_search(), "Repeated search request must be rejected")
		for i in range(240):
			car.driver._physics_process(1.0 / 60.0)
		check(car.driver.search_ready, "Every driver must finish the short search animation")
		car.driver.end_search()
		check(car.driver.state == car.driver.State.OUTSIDE, "Search must restore the waiting state")
	scene.inventory_view.open_view(scene.player_inventory, returned.inventory, returned.driver_name)
	scene.inventory_view.select_item("player:flashlight", "player")
	check(
		scene.inventory_view.return_button.disabled,
		"Player equipment must not be returnable to an NPC"
	)
	scene.inventory_view.transfer_selected("player")
	check(
		scene.player_inventory.items.size() == 7,
		"Wrong-owner return must not remove player equipment"
	)
	scene.inventory_view.close_view()
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print(
			"PASS: fixed items, full inventory, atomic transfer/return, no duplicates, respawn persistence and ownership"
		)
	quit(0 if failures.is_empty() else 1)
