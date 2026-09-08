extends Node3D
## One ingredient station on the back counter. The chef walks up and presses the action button.

@export var ingredient := "rice"
var unlocked := true

@onready var model_root: Node3D = $Model
@onready var cover: Node3D = $Cover
@onready var label: Label3D = $Label

var _model: Node3D
var _highlight := false


func _ready() -> void:
	var info: Dictionary = Recipes.INGREDIENTS.get(ingredient, {})
	if not info.is_empty():
		var scene := Recipes.load_model(info["model"])
		if scene:
			_model = scene.instantiate()
			model_root.add_child(_model)
			_model.scale = Vector3.ONE * float(info.get("scale", 1.0))
		label.text = info["name"]
	set_unlocked(unlocked)


func set_unlocked(on: bool) -> void:
	unlocked = on
	cover.visible = false
	model_root.visible = on
	label.visible = on


## Nearest-target highlight: the model lifts a little and the label brightens.
func set_highlight(on: bool) -> void:
	if on == _highlight:
		return
	_highlight = on
	var t := create_tween().set_parallel(true)
	t.tween_property(model_root, "position:y", 0.14 + (0.25 if on else 0.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(model_root, "scale", Vector3.ONE * (1.15 if on else 1.0), 0.15)
	label.modulate = Color(1.0, 0.9, 0.5, 1) if on else Color(1, 0.97, 0.9, 1)


## Feedback when the ingredient was taken.
func bounce() -> void:
	FX.pop(model_root, 1.3, 0.25)
	FX.burst(get_tree(), global_position + Vector3.UP * 0.6, Color(1.0, 0.95, 0.7), 10, 0.6, 0.6)


## Feedback when the grab was refused.
func refuse() -> void:
	FX.shake(model_root, 0.12, 0.22)
	Audio.play("no", 1.0, -8.0)
