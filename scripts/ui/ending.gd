extends Node3D
## Ending: Panda waves, the rabbits eat, confetti.

@onready var title: Label = $UI/Title
@onready var stats: Label = $UI/Stats
@onready var back: Button = $UI/Back
@onready var cast: Node3D = $Cast


func _ready() -> void:
	UiKit.style_title(title, 110)
	UiKit.style_label(stats, 40)
	UiKit.style_button(back, UiKit.ACCENT2, 44)
	stats.text = "%d coins earned across the week\n%d / %d stars" % [Game.total_earnings(), Game.total_stars(), Game.DAYS.size() * 3]
	back.pressed.connect(func(): Game.go_to_days())
	Audio.play_music("menu")
	for c in cast.get_children():
		var anim := FX.find_anim(c)
		if anim == null:
			continue
		if c.name.begins_with("Chef"):
			FX.set_loop(anim, ["Wave"], true)
			anim.play("Wave")
		else:
			FX.set_loop(anim, ["Sitting_Eating"], true)
			anim.play("Sitting_Eating")
			anim.seek(randf() * anim.current_animation_length)
	UiKit.fly_in(title, 0.1, Vector2(0, -80))
	UiKit.fly_in(stats, 0.3)
	UiKit.fly_in(back, 0.5)
	_confetti()


func _confetti() -> void:
	while is_inside_tree():
		FX.burst(get_tree(), Vector3(randf_range(-5, 5), 5.5, randf_range(-1, 3)), Color.from_hsv(randf(), 0.7, 1.0), 20, 1.4, 0.6)
		await get_tree().create_timer(0.45).timeout
