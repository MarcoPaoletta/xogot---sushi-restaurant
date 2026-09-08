extends Node
## Merges the on-screen buttons with keyboard input.

var left_held := false
var right_held := false
var _act_pressed := false


func axis() -> float:
	var kb := Input.get_axis("move_left", "move_right")
	if absf(kb) > 0.01:
		return kb
	return (1.0 if right_held else 0.0) - (1.0 if left_held else 0.0)


func press_act() -> void:
	if not _act_pressed:
		_act_pressed = true
		Input.action_press("interact")


func release_act() -> void:
	if _act_pressed:
		_act_pressed = false
		Input.action_release("interact")
