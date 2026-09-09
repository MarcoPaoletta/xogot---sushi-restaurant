extends Node3D
## One ingredient station on the back counter. The chef walks up and presses the action button.

@export var ingredient := "rice"
var unlocked := true
const TARGET_SIZE := 0.85     # longest edge of any ingredient sitting on the board
const FLAT_TILT := -34.0      # flat things (nori, a fillet, an eel) lean back to face the camera
const BASE_YAW := -18.0
const LABEL_HEIGHT := 1.6     # every label at the same height; the font is small enough for one slot

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
			_fit(_model)
		label.text = info["name"]
	place(position.x)
	set_unlocked(unlocked)


## Sizes an ingredient to TARGET_SIZE, stands it on the board and turns its long axis along the
## counter, so all fourteen models read at the same scale however the kit authored them.
func _fit(m: Node3D) -> void:
	m.transform = Transform3D.IDENTITY
	var local := _model_aabb(m)
	if local.size.length() < 0.0001:
		return
	var longest := maxf(local.size.x, maxf(local.size.y, local.size.z))
	var flat: bool = local.size.y < 0.4 * maxf(local.size.x, local.size.z)
	var lengthwise := 90.0 if local.size.z > local.size.x else 0.0
	m.rotation_degrees = Vector3(FLAT_TILT if flat else 0.0, BASE_YAW + lengthwise, 0.0)
	m.scale = Vector3.ONE * (TARGET_SIZE / longest)
	var placed: AABB = m.transform * local
	m.position = -Vector3(placed.get_center().x, placed.position.y, placed.get_center().z)


## AABB of every mesh under `node`, in that node's own untransformed space.
func _model_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var found := false
	var stack: Array = [[node, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var entry: Array = stack.pop_back()
		var n: Node = entry[0]
		var xform: Transform3D = entry[1]
		if n is MeshInstance3D and n.mesh != null:
			var b: AABB = xform * n.mesh.get_aabb()
			box = b if not found else box.merge(b)
			found = true
		for c in n.get_children():
			if c is Node3D:
				stack.append([c, xform * c.transform])
	return box


## Puts the station at X on the back counter. Labels share one height and a font that fits the
## 1.8 u slot, so the row reads as a single aligned line.
func place(x: float, _levels := 2) -> void:
	position.x = x
	label.position.y = LABEL_HEIGHT


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
