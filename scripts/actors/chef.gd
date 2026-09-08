extends Node3D
## Panda, player controlled: walks left/right behind the counter, carries a stack of ingredients
## or a finished dish over its head (GDD v2, section 15).

signal interact_requested

const SPEED := 7.5
const MIN_X := -9.2
const MAX_X := 9.6
const STACK_STEP := 0.62

var held: Array = []          # ingredient ids in pickup order
var held_dish := ""           # dish id once mixed
var control_enabled := true
var _anim: AnimationPlayer
var _facing := 0.0
var _react_until := 0.0
var _chop_until := 0.0

@onready var model: Node3D = $Model
@onready var hands: Node3D = $Hands


func _ready() -> void:
	_anim = FX.find_anim(model)
	FX.set_loop(_anim, ["Idle", "Idle_Holding", "Walk", "Walk_Holding", "Chop"], true)
	FX.set_loop(_anim, ["Yes", "No", "Wave", "HitReact"], false)
	if _anim:
		_anim.play("Idle")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and control_enabled:
		get_viewport().set_input_as_handled()
		interact_requested.emit()


func _physics_process(delta: float) -> void:
	var dir := TouchInput.axis() if control_enabled else 0.0
	position.x = clampf(position.x + dir * SPEED * delta, MIN_X, MAX_X)
	var moving := absf(dir) > 0.05
	# Face the walking direction, and the customers when standing still.
	var target_yaw := (PI / 2.0 if dir > 0.0 else -PI / 2.0) if moving else 0.0
	_facing = rotate_toward(_facing, target_yaw, deg_to_rad(900.0) * delta)
	model.rotation.y = _facing
	_update_anim(moving)


func _update_anim(moving: bool) -> void:
	if _anim == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _react_until:
		return
	var carrying := not held.is_empty() or held_dish != ""
	var clip := ""
	if now < _chop_until:
		clip = "Chop"
	elif moving:
		clip = "Walk_Holding" if carrying else "Walk"
	else:
		clip = "Idle_Holding" if carrying else "Idle"
	if _anim.current_animation != clip:
		_anim.play(clip, 0.12)


func react(clip: String, lock := 0.8) -> void:
	if _anim and _anim.has_animation(clip):
		_anim.play(clip, 0.08)
		_react_until = Time.get_ticks_msec() / 1000.0 + lock


func chop() -> void:
	_chop_until = Time.get_ticks_msec() / 1000.0 + 0.5


# --- carrying -----------------------------------------------------------------

func is_empty() -> bool:
	return held.is_empty() and held_dish == ""


## Adds an ingredient to the stack. Returns "added", "full", "duplicate", "ruined" or "dish".
func add_ingredient(id: String) -> String:
	if held_dish != "":
		return "dish"
	if held.has(id):
		return "duplicate"
	if held.size() >= Recipes.MAX_INGREDIENTS:
		return "full"
	var candidate := held.duplicate()
	candidate.append(id)
	if Recipes.match_dish(candidate) == "" and not Recipes.is_prefix(candidate):
		return "ruined"
	held = candidate
	_spawn_held(Recipes.INGREDIENTS[id]["model"], held.size() - 1, 0.9 * float(Recipes.INGREDIENTS[id].get("scale", 1.0)))
	return "added"


## Turns the stack into the dish it matches. Returns the dish id or "".
func mix() -> String:
	var dish := Recipes.match_dish(held)
	if dish == "":
		return ""
	held_dish = dish
	held.clear()
	_clear_held_models()
	_spawn_held(Recipes.DISHES[dish]["model"], 0, 1.5)
	return dish


func take_dish() -> String:
	var d := held_dish
	held_dish = ""
	_clear_held_models()
	return d


func drop_all() -> void:
	held.clear()
	held_dish = ""
	_clear_held_models()


func _spawn_held(path: String, index: int, scale: float) -> void:
	var scene := Recipes.load_model(path)
	if scene == null:
		return
	var m: Node3D = scene.instantiate()
	hands.add_child(m)
	m.position = Vector3(0, STACK_STEP * index, 0)
	FX.appear(m, scale, 0.25)


func _clear_held_models() -> void:
	for c in hands.get_children():
		c.queue_free()


func _process(delta: float) -> void:
	# Gentle bob of the carried stack.
	hands.position.y = 3.75 + sin(Time.get_ticks_msec() / 1000.0 * 4.0) * 0.05
	for c in hands.get_children():
		c.rotation.y += delta * 1.2
