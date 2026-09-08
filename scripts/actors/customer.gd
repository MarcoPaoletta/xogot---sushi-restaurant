extends Node3D
## A rabbit customer: walks in, sits, shows an order, waits, eats or leaves angry (GDD 6.3).

signal tapped(customer: Node)
signal served(customer: Node, correct: bool, patience_left: float)
signal left(customer: Node, happy: bool)
signal wants_more(customer: Node)

enum State { ENTERING, SITTING_DOWN, WAITING, EATING, LEAVING }

const WALK_SPEED := 3.0
const LEAVE_SPEED := 3.0
const ANGRY_SPEED := 4.0
const MODEL_SCALE := 0.7
const BUBBLE_HEIGHT := 3.4

var state := State.ENTERING
var orders: Array = []            # remaining dish ids for this customer
var order := ""                   # current dish id
var patience := 1.0
var patience_seconds := 30.0
var seat_index := -1
var seat_position := Vector3.ZERO
var door_position := Vector3.ZERO
var model_path := ""

var _anim: AnimationPlayer
var _model: Node3D
var _dish_model: Node3D
var _ring_mat: ShaderMaterial
var _tick_t := 0.0
var _no_t := 0.0
var _served_once := false

@onready var model_root: Node3D = $Model
@onready var bubble: Node3D = $OrderBubble
@onready var dish_holder: Node3D = $OrderBubble/DishHolder
@onready var ring: MeshInstance3D = $OrderBubble/Ring
@onready var tap_target: Area3D = $TapTarget


func setup(p_model_path: String, p_orders: Array, p_patience: float, p_seat_index: int, p_seat: Vector3, p_door: Vector3) -> void:
	model_path = p_model_path
	orders = p_orders.duplicate()
	patience_seconds = p_patience
	seat_index = p_seat_index
	seat_position = p_seat
	door_position = p_door


func _ready() -> void:
	bubble.visible = false
	_ring_mat = ring.get_active_material(0) as ShaderMaterial
	var scene := Recipes.load_model(model_path)
	if scene:
		_model = scene.instantiate()
		model_root.add_child(_model)
		_model.scale = Vector3.ONE * MODEL_SCALE
		_anim = FX.find_anim(_model)
		FX.set_loop(_anim, ["Walk", "Sitting_Idle", "Sitting_Eating", "Idle"], true)
		FX.set_loop(_anim, ["Sitting_Start", "Sitting_End", "Yes", "No"], false)
	global_position = door_position
	_enter()


# --- states -----------------------------------------------------------------

func _enter() -> void:
	state = State.ENTERING
	_play("Walk")
	var target := seat_position + Vector3(0, 0, 1.0)
	_face(target - global_position)
	var t := create_tween()
	t.tween_property(self, "global_position", target, global_position.distance_to(target) / WALK_SPEED).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(_sit_down)
	Audio.play("bell", randf_range(0.95, 1.05), -8.0)


func _sit_down() -> void:
	state = State.SITTING_DOWN
	_face(Vector3(0, 0, -1))
	var t := create_tween()
	t.tween_property(self, "global_position", seat_position, 0.35).set_trans(Tween.TRANS_SINE)
	_play("Sitting_Start")
	var len := _anim.current_animation_length if _anim and _anim.current_animation == "Sitting_Start" else 0.9
	await get_tree().create_timer(maxf(len - 0.05, 0.3)).timeout
	if state != State.SITTING_DOWN:
		return
	_start_order()


func _start_order() -> void:
	if orders.is_empty():
		_leave(true)
		return
	order = orders.pop_front()
	patience = 1.0
	state = State.WAITING
	_play("Sitting_Idle")
	_show_bubble()


func _show_bubble() -> void:
	for c in dish_holder.get_children():
		c.queue_free()
	var info: Dictionary = Recipes.DISHES[order]
	var scene := Recipes.load_model(info["model"])
	if scene:
		_dish_model = scene.instantiate()
		dish_holder.add_child(_dish_model)
		_dish_model.position = Vector3(0, -0.25, 0)
	bubble.visible = true
	bubble.scale = Vector3.ONE * 0.01
	bubble.create_tween().tween_property(bubble, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_set_ring(1.0)


func _process(delta: float) -> void:
	if state != State.WAITING:
		return
	patience = maxf(patience - delta / patience_seconds, 0.0)
	_set_ring(patience)
	if _dish_model:
		_dish_model.rotation.y += deg_to_rad(60.0) * delta
	bubble.position.y = BUBBLE_HEIGHT + sin(Time.get_ticks_msec() / 1000.0 * 2.5) * 0.08
	if patience < 0.3:
		_tick_t -= delta
		if _tick_t <= 0.0:
			_tick_t = 1.0
			Audio.play("tick", 1.0, -10.0)
		_no_t -= delta
		if _no_t <= 0.0:
			_no_t = 4.0
			_play_once("No", "Sitting_Idle")
	if patience <= 0.0:
		_angry()


func _set_ring(v: float) -> void:
	if _ring_mat:
		_ring_mat.set_shader_parameter("progress", v)
		_ring_mat.set_shader_parameter("pulse", 1.0 if v < 0.3 and fmod(Time.get_ticks_msec() / 500.0, 2.0) < 1.0 else 0.0)


## Called by the restaurant when a dish is delivered. Returns true if it was the right one.
func serve(dish: String) -> bool:
	if state != State.WAITING:
		return false
	if dish == order:
		var left_p := patience
		state = State.EATING
		served.emit(self, true, left_p)
		_hide_bubble()
		_play_once("Yes", "Sitting_Eating")
		FX.burst(get_tree(), global_position + Vector3.UP * 2.2, Color(1.0, 0.85, 0.3), 26, 1.0)
		_eat()
		return true
	patience = maxf(patience - 0.25, 0.0)
	served.emit(self, false, patience)
	_play_once("No", "Sitting_Idle")
	FX.pop(bubble, 1.3, 0.3)
	Audio.play("no", 1.0, -4.0)
	return false


func _eat() -> void:
	await get_tree().create_timer(1.0).timeout
	if state != State.EATING:
		return
	_play("Sitting_Eating")
	await get_tree().create_timer(2.5).timeout
	if state != State.EATING:
		return
	if orders.is_empty():
		_leave(true)
	else:
		wants_more.emit(self)
		_start_order()


func _angry() -> void:
	state = State.LEAVING
	_hide_bubble()
	Audio.play("angry")
	_play_once("No", "")
	await get_tree().create_timer(0.8).timeout
	_leave(false)


func _leave(happy: bool) -> void:
	state = State.LEAVING
	_hide_bubble()
	_play("Sitting_End")
	await get_tree().create_timer(0.6).timeout
	left.emit(self, happy)
	var speed := LEAVE_SPEED if happy else ANGRY_SPEED
	_face(door_position - global_position)
	_play("Walk")
	var t := create_tween()
	t.tween_property(self, "global_position", door_position, global_position.distance_to(door_position) / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func _hide_bubble() -> void:
	if bubble.visible:
		var t := bubble.create_tween()
		t.tween_property(bubble, "scale", Vector3.ONE * 0.01, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_callback(func(): bubble.visible = false)


func cancel() -> void:
	state = State.LEAVING
	_hide_bubble()
	queue_free()


# --- helpers -------------------------------------------------------------------

func _face(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.01:
		model_root.rotation.y = atan2(dir.x, dir.z)


func _play(clip: String, blend := 0.15) -> void:
	if _anim and _anim.has_animation(clip) and _anim.current_animation != clip:
		_anim.play(clip, blend)


func _play_once(clip: String, then: String) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	_anim.play(clip, 0.1)
	var len := _anim.current_animation_length
	await get_tree().create_timer(maxf(len - 0.05, 0.2)).timeout
	if then != "" and _anim and is_inside_tree() and _anim.current_animation == clip:
		_anim.play(then, 0.15)


func on_tap() -> void:
	if state == State.WAITING:
		tapped.emit(self)


func remind() -> void:
	FX.pop(bubble, 1.25, 0.3)
