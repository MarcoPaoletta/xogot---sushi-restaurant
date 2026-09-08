class_name FX
## Static helpers: particle bursts, pops and tap handling.

const BURST := preload("res://scenes/fx/burst.tscn")


## Spawn a one-shot particle burst at a world position.
static func burst(tree: SceneTree, pos: Vector3, color: Color, amount := 24, scale := 1.0, velocity := 1.0) -> void:
	var root: Node3D = BURST.instantiate()
	tree.current_scene.add_child(root)
	root.global_position = pos
	var p: GPUParticles3D = root.get_node("Particles")
	p.amount = amount
	var mat := (p.process_material as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	mat.color = color
	mat.scale_min *= scale
	mat.scale_max *= scale
	mat.initial_velocity_min *= velocity
	mat.initial_velocity_max *= velocity
	p.process_material = mat
	p.emitting = true
	p.finished.connect(root.queue_free)


## Pop: scale up then back.
static func pop(node: Node3D, amount := 1.3, time := 0.22) -> void:
	var base := node.scale
	var t := node.create_tween()
	t.tween_property(node, "scale", base * amount, time * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", base, time * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Shake: small horizontal wobble.
static func shake(node: Node3D, amount := 0.12, time := 0.22) -> void:
	var base := node.position
	var t := node.create_tween()
	for i in 3:
		t.tween_property(node, "position:x", base.x + amount * (1.0 if i % 2 == 0 else -1.0), time / 4.0)
	t.tween_property(node, "position", base, time / 4.0)


## Appear: scale from zero with a bounce.
static func appear(node: Node3D, target_scale := 1.0, time := 0.3) -> void:
	node.scale = Vector3.ONE * 0.01
	node.create_tween().tween_property(node, "scale", Vector3.ONE * target_scale, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## True for the pressed half of a tap or left click (touch is emulated as mouse).
static func is_tap(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return event.pressed
	return false


## Set the loop mode of animation clips on an AnimationPlayer found under `root`.
static func find_anim(root: Node) -> AnimationPlayer:
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer


static func set_loop(anim: AnimationPlayer, names: Array, loop := true) -> void:
	if anim == null:
		return
	for n in names:
		if anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
