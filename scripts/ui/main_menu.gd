extends Node3D
## Title screen over a live diorama of the counter.

@onready var camera: Camera3D = $Camera
@onready var title: Label = $UI/Title
@onready var subtitle: Label = $UI/Subtitle
@onready var play_btn: Button = $UI/Play
@onready var stats: Label = $UI/Stats
@onready var credit: Label = $UI/Credit
@onready var diorama: Node3D = $Diorama
var _t := 0.0
var _base_cam: Vector3


func _ready() -> void:
	UiKit.style_title(title, 150)
	UiKit.style_label(subtitle, 34, Color(1, 0.95, 0.85), 8)
	subtitle.text = "walk with ◀ ▶  ·  grab ingredients  ·  mix at the pass  ·  serve the rabbits"
	UiKit.style_button(play_btn, UiKit.ACCENT, 52)
	play_btn.custom_minimum_size = Vector2(420, 130)
	UiKit.style_label(stats, 34)
	UiKit.style_label(credit, 24, Color(1, 1, 1, 0.85), 5)
	stats.text = "Best day  %d coins     %d / %d stars" % [Game.best_day_earnings(), Game.total_stars(), Game.DAYS.size() * 3]
	play_btn.pressed.connect(func(): Game.go_to_days())
	Audio.play_music("menu")
	_base_cam = camera.position
	UiKit.fly_in(title, 0.1, Vector2(0, -80))
	UiKit.fly_in(subtitle, 0.25)
	UiKit.fly_in(play_btn, 0.4)
	UiKit.fly_in(stats, 0.5)
	title.pivot_offset = title.size / 2.0
	var t := create_tween().set_loops()
	t.tween_property(title, "rotation", deg_to_rad(-2.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(title, "rotation", deg_to_rad(2.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for c in diorama.get_children():
		var anim := FX.find_anim(c)
		if anim == null:
			continue
		if c.name.begins_with("Chef"):
			FX.set_loop(anim, ["Idle"], true)
			anim.play("Idle")
		elif c.name.begins_with("Guest"):
			FX.set_loop(anim, ["Sitting_Eating", "Sitting_Idle"], true)
			anim.play("Sitting_Eating")
			anim.seek(randf() * anim.current_animation_length)


func _process(delta: float) -> void:
	_t += delta
	var yaw := deg_to_rad(6.0) * sin(_t * TAU / 12.0)
	camera.position = _base_cam.rotated(Vector3.UP, yaw)
	camera.look_at(Vector3(0, 1.2, 0))
