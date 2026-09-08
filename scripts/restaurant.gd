extends Node3D
## Day controller (v2): the chef walks along the counter and presses the action button next to
## stations, the pass, customers and the sink. Nothing in the world is tapped any more.

const CUSTOMER := preload("res://scenes/actors/customer.tscn")
const KIT_CHARS := "res://assets/Sushi Restaurant Kit - May 2023/Characters/Normal/glTF/"
const REACH := 1.35          # metres in X the chef can reach a station or a customer from
const REACH_WIDE := 1.7      # the pass and the sink are bigger

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
var _target: Node = null
var _target_kind := ""

@onready var stations: Node3D = $Stations
@onready var plate: Node3D = $Plate
@onready var sink: Node3D = $Sink
@onready var chef: Node3D = $Chef
@onready var seats: Node3D = $Seats
@onready var door: Marker3D = $Door
@onready var customers: Node3D = $Customers
@onready var spawner: Node = $Spawner
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera3D = $Camera
@onready var prompt: Label3D = $Prompt


func _ready() -> void:
	add_to_group("restaurant")
	day_index = Game.current_day
	day = Game.DAYS[day_index]
	for s in stations.get_children():
		s.set_unlocked(day["stations"].has(s.ingredient))
	chef.interact_requested.connect(_on_interact)
	spawner.spawn_requested.connect(_spawn_customer)
	spawner.build(day, day_index)
	hud.setup(self)
	hud.set_day(day_index, day["name"], 0, int(day["customers"]))
	hud.set_earnings(0, 0)
	hud.set_streak(0)
	hud.set_strikes(0)
	prompt.visible = false
	Audio.play_music("day", 0.8, 1.0 + 0.03 * maxi(day_index - 2, 0))
	_intro()


func _intro() -> void:
	chef.control_enabled = false
	var target_pos := camera.position
	camera.position = target_pos + Vector3(0, 1.6, 4.5)
	var t := create_tween()
	t.tween_property(camera, "position", target_pos, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	chef.react("Wave", 1.2)
	Audio.play("wave", 1.0, -4.0)
	hud.show_title("Day %d · %s" % [day_index + 1, day["name"]])
	await t.finished
	running = true
	chef.control_enabled = true
	spawner.start()
	if not Game.tutorial_done() and day_index == 0:
		hud.flash_message("Walk with ◀ ▶ — grab ingredients from the back counter", 3.5)


func _process(delta: float) -> void:
	if running:
		time += delta
	_update_target()


# --- targets --------------------------------------------------------------------------

## Work out what the action button would do from where the chef stands, and show it.
func _update_target() -> void:
	var x: float = chef.global_position.x
	var best: Node = null
	var best_kind := ""
	var best_d := 99.0
	var carrying_dish: bool = chef.held_dish != ""
	for s in stations.get_children():
		if not s.unlocked or carrying_dish:
			continue
		var d: float = absf(s.global_position.x - x)
		if d < REACH and d < best_d:
			best = s
			best_kind = "station"
			best_d = d
	var dp: float = absf(plate.global_position.x - x)
	if dp < REACH_WIDE and dp < best_d and not chef.held.is_empty():
		best = plate
		best_kind = "mix"
		best_d = dp
	var ds: float = absf(sink.global_position.x - x)
	if ds < REACH_WIDE and ds < best_d and not chef.is_empty():
		best = sink
		best_kind = "bin"
		best_d = ds
	for c in customers.get_children():
		if c.state != c.State.WAITING:
			continue
		var dc: float = absf(c.global_position.x - x)
		if dc < REACH and dc < best_d and carrying_dish:
			best = c
			best_kind = "serve"
			best_d = dc
	if best != _target:
		if _target and is_instance_valid(_target) and _target.has_method("set_highlight"):
			_target.set_highlight(false)
		_target = best
		_target_kind = best_kind
		if _target and _target.has_method("set_highlight"):
			_target.set_highlight(true)
	if _target == null or not running:
		prompt.visible = false
		return
	var text := ""
	match _target_kind:
		"station": text = "Grab %s" % Recipes.INGREDIENTS[_target.ingredient]["name"]
		"mix": text = "Mix"
		"bin": text = "Bin it"
		"serve": text = "Serve %s" % Recipes.dish_name(chef.held_dish)
	prompt.text = text
	var above: Vector3 = _target.global_position + Vector3(0, 1.5, 0)
	if _target_kind == "serve":
		above = _target.global_position + Vector3(0, 4.4, 0)
	elif _target_kind == "bin":
		above = _target.global_position + Vector3(0, 1.9, 0)
	if not prompt.visible:
		prompt.global_position = above
		prompt.visible = true
	else:
		prompt.global_position = prompt.global_position.lerp(above, 0.35)


func _on_interact() -> void:
	if not running:
		return
	if _target == null:
		if chef.is_empty():
			hud.flash_message("Walk to an ingredient on the back counter")
		elif chef.held_dish != "":
			hud.flash_message("Bring the dish to a waiting rabbit")
		else:
			hud.flash_message("Mix the stack at the pass on the left")
		return
	match _target_kind:
		"station": _grab(_target)
		"mix": _mix()
		"bin": _bin()
		"serve": _serve(_target)


# --- actions --------------------------------------------------------------------------

func _grab(station: Node) -> void:
	var result: String = chef.add_ingredient(station.ingredient)
	match result:
		"added":
			chef.chop()
			station.bounce()
			Audio.play_var("tap", 0.1, -4.0)
			_tutorial("added")
		"dish":
			station.refuse()
			hud.flash_message("Serve or bin the dish first")
		"full":
			station.refuse()
			hud.flash_message("Hands full — mix it at the pass on the left")
			_tutorial("stuck")
		"duplicate":
			station.refuse()
			hud.flash_message("Already holding that")
		"ruined":
			station.refuse()
			hud.flash_message("That doesn't go with what you hold")
			_tutorial("stuck")
	_update_target()


func _mix() -> void:
	var dish: String = chef.mix()
	if dish == "":
		plate.fail_mix()
		chef.react("No", 0.6)
		hud.flash_message("Not a recipe yet — add a topping")
		return
	chef.chop()
	plate.show_mix(dish)
	hud.flash_message(Recipes.dish_name(dish) + "!")
	_tutorial("complete")
	_update_target()


func _bin() -> void:
	chef.drop_all()
	Audio.play("splash", randf_range(0.95, 1.05), -6.0)
	FX.burst(get_tree(), sink.global_position + Vector3.UP * 2.3, Color(0.6, 0.8, 1.0), 20, 1.0)
	_update_target()


func _serve(c: Node) -> void:
	var dish: String = chef.take_dish()
	_fly_dish(dish, c)
	Audio.play("whoosh", 1.0, -8.0)
	chef.react("Yes", 0.5)
	_update_target()
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(c):
		return
	var correct: bool = c.serve(dish)
	if not correct:
		chef.react("No", 0.7)
		hud.flash_message("Wrong dish — they wanted %s" % Recipes.dish_name(c.order))


func _fly_dish(dish: String, c: Node3D) -> void:
	var scene := Recipes.load_model(Recipes.DISHES[dish]["model"])
	if scene == null:
		return
	var m: Node3D = scene.instantiate()
	add_child(m)
	var start: Vector3 = chef.global_position + Vector3(0, 3.2, 0)
	var target: Vector3 = c.global_position + Vector3.UP * 2.0
	var mid := (start + target) / 2.0 + Vector3.UP * 1.2
	m.global_position = start
	var t := create_tween()
	t.tween_method(func(f: float):
		m.global_position = start.lerp(mid, f).lerp(mid.lerp(target, f), f)
		m.rotation.y += 0.2, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_callback(m.queue_free)


# --- customers ---------------------------------------------------------------------

func _spawn_customer(orders: Array, seat_index: int) -> void:
	var c := CUSTOMER.instantiate()
	c.name = "Customer%d" % (spawner.spawned + 1)
	var seat: Node3D = seats.get_child(seat_index)
	var model_path: String = KIT_CHARS + spawner.model_for(spawner.spawned) + ".gltf"
	c.setup(model_path, orders, float(day["patience"]), seat_index, seat.global_position, door.global_position)
	c.served.connect(_on_customer_served)
	c.left.connect(_on_customer_left)
	customers.add_child(c)
	if not Game.tutorial_done() and day_index == 0 and _tutorial_step == 0:
		_tutorial_step = 1
		await get_tree().create_timer(3.0).timeout
		if running and _tutorial_step == 1:
			hud.flash_message("Read the dish over the rabbit, then grab Rice + its topping", 3.5)


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
	if was_happy:
		happy += 1
	else:
		angry += 1
		strikes += 1
		streak = 0
		hud.set_streak(0)
		hud.set_strikes(strikes)
		hud.damage_flash()
		hud.flash_message("They left angry!")
		Audio.play("strike")
		chef.react("HitReact", 0.8)
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
	chef.control_enabled = false
	prompt.visible = false
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
		chef.react("Wave", 2.5)
		hud.show_title("Day complete!")
	else:
		Audio.play("closed")
		chef.react("No", 2.5)
		hud.show_title("Closed early")
	Audio.duck_music(-8.0)
	await get_tree().create_timer(2.2).timeout
	Audio.duck_music(0.0, 0.1)
	Game.day_complete({
		"day": day_index, "completed": completed, "stars": stars, "earnings": earnings, "target": int(day["target"]),
		"happy": happy, "angry": angry, "total": total, "best_streak": best_streak, "time": time,
	})


# --- tutorial (day 1 only) -----------------------------------------------------------

func _tutorial(event: String) -> void:
	if Game.tutorial_done() or day_index != 0:
		return
	match event:
		"added":
			if _tutorial_step < 2:
				_tutorial_step = 2
				hud.flash_message("Now walk to the pass on the far left and mix", 2.5)
		"complete":
			if _tutorial_step < 3:
				_tutorial_step = 3
				hud.flash_message("Carry it to the rabbit and serve", 2.5)
		"stuck":
			if _tutorial_step < 4:
				_tutorial_step = 4
				hud.flash_message("The sink on the right bins what you hold", 2.5)
		"served":
			if _tutorial_step < 5:
				_tutorial_step = 5
				hud.flash_message("Serve fast for tips — keep the streak going!", 2.5)
