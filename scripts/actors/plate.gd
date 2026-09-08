extends Node3D
## The pass: shows the ingredients added so far and swaps to the finished dish when a recipe matches.

signal changed(ingredients: Array, dish: String)
signal tapped

var ingredients: Array = []
var dish := ""        # matched dish id, "" while incomplete
var ruined := false

@onready var stack: Node3D = $Stack
@onready var finished: Node3D = $Finished
@onready var glow: OmniLight3D = $Glow
@onready var tap_target: Area3D = $TapTarget

const STACK_STEP := 0.14


func _ready() -> void:
	glow.light_energy = 0.0


func on_tap() -> void:
	tapped.emit()


## Try to add an ingredient. Returns "added", "full", "duplicate" or "ruined".
func add(ingredient: String) -> String:
	if ruined:
		return "ruined"
	if ingredients.has(ingredient):
		return "duplicate"
	if ingredients.size() >= Recipes.MAX_INGREDIENTS or dish != "":
		return "full"
	ingredients.append(ingredient)
	_spawn_ingredient(ingredient, ingredients.size() - 1)
	dish = Recipes.match_dish(ingredients)
	if dish != "":
		_show_finished()
	elif not Recipes.is_prefix(ingredients):
		_ruin()
	changed.emit(ingredients, dish)
	return "added"


func clear() -> void:
	var had := not ingredients.is_empty()
	ingredients.clear()
	dish = ""
	ruined = false
	for c in stack.get_children():
		c.queue_free()
	for c in finished.get_children():
		c.queue_free()
	stack.visible = true
	glow.light_energy = 0.0
	if had:
		FX.burst(get_tree(), global_position + Vector3.UP * 0.6, Color(0.7, 0.85, 1.0), 18, 0.9)
	changed.emit(ingredients, dish)


## Take the finished dish off the plate (for serving). Returns the dish id.
func take() -> String:
	var id := dish
	ingredients.clear()
	dish = ""
	ruined = false
	for c in stack.get_children():
		c.queue_free()
	for c in finished.get_children():
		c.queue_free()
	glow.light_energy = 0.0
	changed.emit(ingredients, dish)
	return id


func _spawn_ingredient(ingredient: String, index: int) -> void:
	var info: Dictionary = Recipes.INGREDIENTS[ingredient]
	var scene := Recipes.load_model(info["model"])
	if scene == null:
		return
	var m: Node3D = scene.instantiate()
	stack.add_child(m)
	m.position = Vector3(0, 0.1 + STACK_STEP * index, 0)
	m.rotation.y = randf_range(-0.4, 0.4)
	FX.appear(m, 0.7 * float(info.get("scale", 1.0)), 0.25)
	Audio.play_var("tap", 0.1, -4.0)


func _show_finished() -> void:
	var info: Dictionary = Recipes.DISHES[dish]
	var scene := Recipes.load_model(info["model"])
	stack.visible = false
	if scene:
		var m: Node3D = scene.instantiate()
		finished.add_child(m)
		m.position = Vector3(0, 0.12, 0)
		FX.appear(m, 1.0, 0.3)
	Audio.play("complete", 1.0, -2.0)
	FX.burst(get_tree(), global_position + Vector3.UP * 0.7, Color(0.6, 1.0, 0.6), 16, 0.8)
	var t := create_tween()
	t.tween_property(glow, "light_energy", 2.2, 0.12)
	t.tween_property(glow, "light_energy", 0.9, 0.5)


func _ruin() -> void:
	ruined = true
	for c in stack.get_children():
		_tint(c, Color(0.5, 0.5, 0.5))
	Audio.play("buzz", 1.0, -6.0)
	FX.shake(stack, 0.1, 0.25)


func _tint(node: Node, color: Color) -> void:
	if node is GeometryInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		(node as GeometryInstance3D).material_overlay = mat
	for c in node.get_children():
		_tint(c, color)
