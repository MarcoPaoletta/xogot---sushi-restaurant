extends Node
## Root of the running game: one screen in SceneSlot, iris fader above everything.

@onready var slot: Node = $SceneSlot
@onready var fader: ColorRect = $Fader/Rect
var _mat: ShaderMaterial
var _switching := false


func _ready() -> void:
	Game.main = self
	_mat = fader.material as ShaderMaterial
	_mat.set_shader_parameter("fade", 1.0)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load("res://scenes/ui/main_menu.tscn")
	_fade(0.0, 0.7)


func switch_to(path: String) -> void:
	if _switching:
		return
	_switching = true
	get_tree().paused = false
	await _fade(1.0, 0.35)
	_load(path)
	await get_tree().process_frame
	await _fade(0.0, 0.45)
	_switching = false


func _load(path: String) -> void:
	for c in slot.get_children():
		c.queue_free()
	var scene: PackedScene = load(path)
	if scene:
		slot.add_child(scene.instantiate())


func _fade(to: float, time: float) -> Signal:
	var t := create_tween()
	t.tween_method(func(v): _mat.set_shader_parameter("fade", v), _mat.get_shader_parameter("fade"), to, time).set_trans(Tween.TRANS_SINE)
	return t.finished
