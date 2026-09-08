extends Node3D
## One ingredient station on the counter. Tap it to add its ingredient to the plate.

signal tapped(ingredient: String)

@export var ingredient := "rice"
var unlocked := true

@onready var model_root: Node3D = $Model
@onready var cover: Node3D = $Cover
@onready var label: Label3D = $Label
@onready var tap_target: Area3D = $TapTarget

var _model: Node3D


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


func on_tap() -> void:
	if unlocked:
		tapped.emit(ingredient)


## Feedback when the ingredient was accepted.
func bounce() -> void:
	FX.pop(model_root, 1.25, 0.22)


## Feedback when the tap was refused (plate full / duplicate).
func refuse() -> void:
	FX.shake(model_root, 0.12, 0.22)
	Audio.play("no", 1.0, -8.0)
