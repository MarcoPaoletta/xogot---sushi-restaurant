extends Control
## Pause overlay living inside the HUD.

var _restaurant: Node
@onready var panel: PanelContainer = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var resume_btn: Button = $Panel/VBox/Resume
@onready var restart_btn: Button = $Panel/VBox/Restart
@onready var days_btn: Button = $Panel/VBox/Days
@onready var music_btn: Button = $Panel/VBox/Toggles/Music
@onready var sfx_btn: Button = $Panel/VBox/Toggles/Sound
@onready var dim: ColorRect = $Dim


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_theme_stylebox_override("panel", UiKit.panel())
	UiKit.style_title(title, 72)
	UiKit.style_button(resume_btn, UiKit.ACCENT2)
	UiKit.style_button(restart_btn)
	UiKit.style_button(days_btn, Color(0.45, 0.4, 0.5))
	UiKit.style_button(music_btn, Color(0.45, 0.4, 0.5), 30)
	UiKit.style_button(sfx_btn, Color(0.45, 0.4, 0.5), 30)
	resume_btn.pressed.connect(close)
	restart_btn.pressed.connect(func(): close(); Game.restart_day())
	days_btn.pressed.connect(func(): close(); Game.go_to_days())
	music_btn.pressed.connect(func(): Game.set_music_enabled(not Game.save_data.get("music", true)); _refresh())
	sfx_btn.pressed.connect(func(): Game.set_sfx_enabled(not Game.save_data.get("sfx", true)); _refresh())
	dim.color = Color(0.08, 0.04, 0.03, 0.6)


func setup(restaurant: Node) -> void:
	_restaurant = restaurant


func _refresh() -> void:
	music_btn.text = "Music: %s" % ("On" if Game.save_data.get("music", true) else "Off")
	sfx_btn.text = "Sound: %s" % ("On" if Game.save_data.get("sfx", true) else "Off")


func open() -> void:
	_refresh()
	visible = true
	get_tree().paused = true
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.15)
	t.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	get_tree().paused = false
	visible = false
