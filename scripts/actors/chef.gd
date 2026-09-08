extends Node3D
## Panda behind the pass: reacts to taps and serves, never moves.

@onready var model: Node3D = $Model
var _anim: AnimationPlayer
var _busy_until := 0.0


func _ready() -> void:
	_anim = FX.find_anim(model)
	FX.set_loop(_anim, ["Idle", "Chop_Loop", "Idle_Holding"], true)
	FX.set_loop(_anim, ["Yes", "No", "Wave", "HitReact", "Chop_Start", "Chop_End"], false)
	if _anim:
		_anim.animation_finished.connect(_on_finished)
		_anim.play("Idle")


func chop() -> void:
	if _anim and _anim.current_animation in ["Yes", "No", "Wave", "HitReact"]:
		return
	if _anim:
		_anim.play("Chop_Loop", 0.1)
	_busy_until = Time.get_ticks_msec() / 1000.0 + 0.45


func _process(_delta: float) -> void:
	if _anim and _anim.current_animation == "Chop_Loop" and Time.get_ticks_msec() / 1000.0 > _busy_until:
		_anim.play("Idle", 0.2)


func react(clip: String) -> void:
	if _anim and _anim.has_animation(clip):
		_anim.play(clip, 0.1)


func _on_finished(_name: StringName) -> void:
	if _anim and _anim.current_animation == "":
		_anim.play("Idle", 0.2)
