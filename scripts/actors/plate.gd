extends Node3D
## The pass: where the chef mixes a stack into a dish. Shows the mixed dish for a moment.

@onready var finished: Node3D = $Finished
@onready var glow: OmniLight3D = $Glow
@onready var stack: Node3D = $Stack


func _ready() -> void:
	glow.light_energy = 0.0


## Flash the mixed dish on the plate; the chef keeps carrying it.
func show_mix(dish: String) -> void:
	for c in finished.get_children():
		c.queue_free()
	var scene := Recipes.load_model(Recipes.DISHES[dish]["model"])
	if scene:
		var m: Node3D = scene.instantiate()
		finished.add_child(m)
		m.position = Vector3(0, 0.12, 0)
		FX.appear(m, 1.0, 0.25)
		var t := m.create_tween()
		t.tween_interval(0.45)
		t.tween_property(m, "scale", Vector3.ZERO, 0.15)
		t.tween_callback(m.queue_free)
	Audio.play("complete", 1.0, -2.0)
	FX.burst(get_tree(), global_position + Vector3.UP * 0.7, Color(0.6, 1.0, 0.6), 18, 0.8)
	var g := create_tween()
	g.tween_property(glow, "light_energy", 2.4, 0.1)
	g.tween_property(glow, "light_energy", 0.0, 0.6)


func fail_mix() -> void:
	Audio.play("buzz", 1.0, -6.0)
	FX.shake(stack, 0.12, 0.25)
	FX.burst(get_tree(), global_position + Vector3.UP * 0.5, Color(0.5, 0.5, 0.5), 14, 0.9)


func set_highlight(on: bool) -> void:
	glow.light_energy = 0.5 if on else 0.0
