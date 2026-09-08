extends Control
## End-of-day screen: stars, earnings vs target, happy / angry, streak, time.

@onready var panel: PanelContainer = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var stars: HBoxContainer = $Panel/VBox/Stars
@onready var stats: Label = $Panel/VBox/Stats
@onready var next_btn: Button = $Panel/VBox/Buttons/Next
@onready var replay_btn: Button = $Panel/VBox/Buttons/Replay
@onready var days_btn: Button = $Panel/VBox/Buttons/Days


func _ready() -> void:
	var r := Game.last_result
	panel.add_theme_stylebox_override("panel", UiKit.panel())
	UiKit.style_title(title, 84)
	UiKit.style_label(stats, 36)
	UiKit.style_button(next_btn, UiKit.ACCENT2, 44)
	UiKit.style_button(replay_btn)
	UiKit.style_button(days_btn, Color(0.45, 0.4, 0.5))
	var idx: int = r.get("day", Game.current_day)
	var completed: bool = r.get("completed", false)
	title.text = ("Day %d complete!" % (idx + 1)) if completed else "Closed early"
	stats.text = "Earnings  %d  (target %d)\nHappy  %d / %d     Angry  %d\nBest streak  %d     Time  %s" % [
		r.get("earnings", 0), r.get("target", 0), r.get("happy", 0), r.get("total", 0), r.get("angry", 0), r.get("best_streak", 0), Game.format_time(float(r.get("time", 0.0)))]
	next_btn.text = ("Next day" if idx + 1 < Game.DAYS.size() else "Finish") if completed else "Try again"
	next_btn.pressed.connect(func(): Game.next_day() if completed else Game.restart_day())
	replay_btn.pressed.connect(func(): Game.restart_day())
	replay_btn.visible = completed
	days_btn.pressed.connect(func(): Game.go_to_days())
	Audio.play_music("results")
	var got: int = r.get("stars", 0)
	var i := 0
	for s in stars.get_children():
		s.on = false
		s.modulate = Color(1, 1, 1, 0.0)
		s.pivot_offset = s.size / 2.0
		s.scale = Vector2(2.5, 2.5)
		var on := i < got
		var tw := s.create_tween()
		tw.tween_interval(0.4 + 0.3 * i)
		tw.tween_callback(func():
			s.on = on
			Audio.play("star" if on else "no", 1.0 + 0.1 * i, -4.0 if on else -12.0))
		tw.tween_property(s, "modulate", Color(1, 1, 1, 1.0), 0.12)
		tw.parallel().tween_property(s, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	UiKit.pop_in(panel, 0.05)
