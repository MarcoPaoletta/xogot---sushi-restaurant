extends Node3D
## Day controller: wires stations, plate, chef, customers and HUD together (GDD sections 6 and 7).

const CUSTOMER := preload("res://scenes/actors/customer.tscn")
const KIT_CHARS := "res://assets/Sushi Restaurant Kit - May 2023/Characters/Normal/glTF/"

var day_index := 0
var day: Dictionary = {}
var earnings := 0
var streak := 0
var best_streak := 0
var happy := 0
var angry := 0
var handled := 0
var strikes := 0
var time := 0.0
var running := false
var finished := false
var _tutorial_step := 0

@onready var stations: Node3D = $Stations
@onready var plate: Node3D = $Plate
@onready var sink_target: Area3D = $Sink/TapTarget
@onready var chef: Node3D = $Chef
@onready var seats: Node3D = $Seats
@onready var door: Marker3D = $Door
@onready var customers: Node3D = $Customers
@onready var spawner: Node = $Spawner
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera3D = $Camera


func _ready() -> void:
	add_to_group("restaurant")
	get_viewport().physics_object_picking = true
	day_index = Game.current_day
	day = Game.DAYS[day_index]
	for s in stations.get_children():
		s.tapped.connect(_on_station_tapped)
		s.set_unlocked(day["stations"].has(s.ingredient))
	plate.changed.connect(_on_plate_changed)
	plate.tapped.connect(_on_plate_tapped)
	spawner.spawn_requested.connect(_spawn_customer)
	spawner.build(day, day_index)
	hud.setup(self)
	hud.set_day(day_index, day["name"], 0, int(day["customers"]))
	hud.set_earnings(0, 0)
	hud.set_streak(0)
	hud.set_strikes(0)
	Audio.play_music("day", 0.8, 1.0 + 0.03 * maxi(day_index - 2, 0))
	_intro()


func _intro() -> void:
	var target_pos := camera.position
	camera.position = target_pos + Vector3(0, 1.6, 4.5)
	var t := create_tween()
	t.tween_property(camera, "position", target_pos, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	chef.react("Wave")
	Audio.play("wave", 1.0, -4.0)
	hud.show_title("Day %d · %s" % [day_index + 1, day["name"]])
	await t.finished
	running = true
	spawner.start()
	if not Game.tutorial_done() and day_index == 0:
		hud.flash_message("Read the dish over the customer's head", 3.0)


func _process(delta: float) -> void:
	if running:
		time += delta


## One tap = one ray from the camera against the tap targets (layer 8). Works for mouse, touch and injected input.
func _unhandled_input(event: InputEvent) -> void:
	if not FX.is_tap(event) or not running:
		return
	var pos: Vector2 = event.position
	var from := camera.project_ray_origin(pos)
	var to := from + camera.project_ray_normal(pos) * 200.0
	var q := PhysicsRayQueryParameters3D.create(from, to, 128)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var area: Node = hit["collider"]
	get_viewport().set_input_as_handled()
	if area == sink_target:
		_on_sink_tapped()
		return
	var owner_node := area.get_parent()
	if owner_node and owner_node.has_method("on_tap"):
		owner_node.on_tap()


# --- taps ------------------------------------------------------------------------

func _on_station_tapped(ingredient: String) -> void:
	if not running:
		return
	var station := _station(ingredient)
	var result: String = plate.add(ingredient)
	if result == "added":
		chef.chop()
		if station:
			station.bounce()
		_tutorial("added")
	else:
		if station:
			station.refuse()
		if result == "ruined" or result == "full":
			_tutorial("stuck")


func _station(ingredient: String) -> Node:
	for s in stations.get_children():
		if s.ingredient == ingredient:
			return s
	return null


func _on_plate_changed(_ingredients: Array, dish: String) -> void:
	if dish != "":
		_tutorial("complete")


func _on_plate_tapped() -> void:
	if plate.dish == "" and plate.ingredients.is_empty():
		hud.flash_message("Tap an ingredient to start a dish")


func _on_sink_tapped() -> void:
	if plate.ingredients.is_empty() and plate.dish == "":
		return
	Audio.play("splash", randf_range(0.95, 1.05), -6.0)
	FX.burst(get_tree(), sink_target.global_position + Vector3.UP * 0.5, Color(0.6, 0.8, 1.0), 20, 1.0)
	if plate.ruined:
		chef.react("No")
	plate.clear()


func _on_customer_tapped(c: Node) -> void:
	if not running:
		return
	if plate.dish == "":
		c.remind()
		if plate.ingredients.is_empty():
			hud.flash_message("Build a dish first")
		else:
			hud.flash_message("The dish is not finished")
		return
	var dish: String = plate.take()
	_fly_dish(dish, c)
	Audio.play("whoosh", 1.0, -8.0)
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(c):
		return
	var correct: bool = c.serve(dish)
	if correct:
		chef.react("Yes")
	else:
		chef.react("No")
		hud.flash_message("Wrong dish — they wanted %s" % Recipes.dish_name(c.order))


func _fly_dish(dish: String, c: Node3D) -> void:
	var info: Dictionary = Recipes.DISHES[dish]
	var scene := Recipes.load_model(info["model"])
	if scene == null:
		return
	var m: Node3D = scene.instantiate()
	add_child(m)
	m.global_position = plate.global_position + Vector3.UP * 0.3
	var target: Vector3 = c.global_position + Vector3.UP * 2.0
	var mid := (m.global_position + target) / 2.0 + Vector3.UP * 1.4
	var t := create_tween()
	t.tween_method(func(f: float):
		var p := plate.global_position + Vector3.UP * 0.3
		var q := p.lerp(mid, f).lerp(mid.lerp(target, f), f)
		m.global_position = q
		m.rotation.y += 0.2, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_callback(m.queue_free)


# --- customers ---------------------------------------------------------------------

func _spawn_customer(orders: Array, seat_index: int) -> void:
	var c := CUSTOMER.instantiate()
	var seat: Node3D = seats.get_child(seat_index)
	var model_path: String = KIT_CHARS + spawner.model_for(spawner.spawned) + ".gltf"
	c.setup(model_path, orders, float(day["patience"]), seat_index, seat.global_position, door.global_position)
	c.tapped.connect(_on_customer_tapped)
	c.served.connect(_on_customer_served)
	c.left.connect(_on_customer_left)
	customers.add_child(c)
	if not Game.tutorial_done() and day_index == 0 and _tutorial_step == 0:
		_tutorial_step = 1
		await get_tree().create_timer(2.6).timeout
		if running and _tutorial_step == 1:
			hud.flash_message("Tap Rice, then the topping you see", 3.0)


func _on_customer_served(c: Node, correct: bool, patience_left: float) -> void:
	if correct:
		var price := Recipes.dish_price(c.order)
		if patience_left >= 0.5:
			streak += 1
		else:
			streak = 0
		best_streak = maxi(best_streak, streak)
		var mult := 1.0 + 0.25 * minf(streak, 8)
		var tip := int(floor(price * 0.5 * patience_left * mult))
		earnings += price + tip
		happy += 1
		hud.set_earnings(earnings, price + tip)
		hud.set_streak(streak)
		Audio.play("coin", pow(2.0, minf(streak, 8) * 2.0 / 12.0), -3.0)
		if streak >= 3:
			Audio.play("streak", 1.0, -10.0)
		hud.flash_message("%s  +%d" % [("Perfect!" if patience_left >= 0.8 else "Nice!"), price + tip])
		_tutorial("served")
	else:
		streak = 0
		hud.set_streak(0)


func _on_customer_left(c: Node, was_happy: bool) -> void:
	handled += 1
	spawner.free_seat(c.seat_index)
	if not was_happy:
		angry += 1
		strikes += 1
		streak = 0
		hud.set_streak(0)
		hud.set_strikes(strikes)
		hud.damage_flash()
		hud.flash_message("They left angry!")
		Audio.play("strike")
		chef.react("HitReact")
		_shake_camera()
	hud.set_day(day_index, day["name"], handled, int(day["customers"]))
	if strikes >= 3:
		_finish(false)
	elif handled >= int(day["customers"]):
		_finish(true)


func _shake_camera() -> void:
	var base := camera.position
	var t := create_tween()
	for i in 4:
		t.tween_property(camera, "position", base + Vector3(randf_range(-0.12, 0.12), randf_range(-0.08, 0.08), 0), 0.05)
	t.tween_property(camera, "position", base, 0.06)


# --- end of day ---------------------------------------------------------------------

func _finish(completed: bool) -> void:
	if finished:
		return
	finished = true
	running = false
	spawner.stop()
	for c in customers.get_children():
		if c.has_method("cancel") and c.state != c.State.LEAVING:
			c.cancel()
	var total := int(day["customers"])
	var stars := 0
	if completed:
		stars = 1
		if happy >= int(ceil(total * 0.8)):
			stars = 2
		if stars == 2 and angry == 0 and earnings >= int(day["target"]):
			stars = 3
	if completed:
		Audio.play("fanfare")
		chef.react("Wave")
		hud.show_title("Day complete!")
	else:
		Audio.play("closed")
		chef.react("No")
		hud.show_title("Closed early")
	Audio.duck_music(-8.0)
	await get_tree().create_timer(2.2).timeout
	Audio.duck_music(0.0, 0.1)
	Game.day_complete({
		"day": day_index, "completed": completed, "stars": stars, "earnings": earnings, "target": int(day["target"]),
		"happy": happy, "angry": angry, "total": total, "best_streak": best_streak, "time": time,
	})


# --- tutorial (day 1 only, GDD section 11) -------------------------------------------

func _tutorial(event: String) -> void:
	if Game.tutorial_done() or day_index != 0:
		return
	match event:
		"complete":
			if _tutorial_step < 2:
				_tutorial_step = 2
				hud.flash_message("Tap the rabbit to serve", 2.5)
		"stuck":
			if _tutorial_step < 3:
				_tutorial_step = 3
				hud.flash_message("Tap the sink to start over", 2.5)
		"served":
			if _tutorial_step < 4:
				_tutorial_step = 4
				hud.flash_message("Serve fast for tips — keep the streak going!", 2.5)
