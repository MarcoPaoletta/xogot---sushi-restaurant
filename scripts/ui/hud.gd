extends CanvasLayer
## In-day HUD: earnings, streak, customers, strikes, pause, messages, pause menu.

var _restaurant: Node
var _shown_earnings := 0
var _target_earnings := 0
@onready var earnings_label: Label = $Top/Earnings/Label
@onready var earnings_icon: Control = $Top/Earnings/Coin
@onready var streak_label: Label = $Top/Streak
@onready var day_label: Label = $Top/Day
@onready var strikes_box: HBoxContainer = $Top/Strikes
@onready var pause_button: Button = $PauseButton
@onready var message: Label = $Message
@onready var title: Label = $Title
@onready var screen_fx: ColorRect = $ScreenFX
@onready var pause_menu: Control = $PauseMenu
@onready var menu_box: VBoxContainer = $Menu/VBox
@onready var menu_btn: Button = $MenuButton
@onready var icon_baker: SubViewport = $IconViewport
@onready var left_btn: Button = $Touch/Left
@onready var right_btn: Button = $Touch/Right
@onready var act_btn: Button = $Touch/Act


func _ready() -> void:
	layer = 10
	UiKit.style_label(earnings_label, 46, UiKit.GOLD)
	UiKit.style_label(streak_label, 36, Color(1.0, 0.6, 0.35))
	UiKit.style_label(day_label, 40)
	UiKit.style_label(message, 44, UiKit.PAPER, 10)
	UiKit.style_title(title, 84)
	UiKit.style_button(pause_button, Color(0.35, 0.25, 0.22), 40)
	pause_button.custom_minimum_size = Vector2(96, 96)
	message.modulate.a = 0.0
	title.modulate.a = 0.0
	streak_label.modulate.a = 0.0
	pause_button.pressed.connect(_on_pause)
	screen_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_menu.visible = false
	for b in [left_btn, right_btn, act_btn]:
		UiKit.style_button(b, Color(0.35, 0.25, 0.22, 0.85), 64)
		b.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(act_btn, Color(0.86, 0.23, 0.2, 0.9), 44)
	left_btn.button_down.connect(func(): TouchInput.left_held = true)
	left_btn.button_up.connect(func(): TouchInput.left_held = false)
	right_btn.button_down.connect(func(): TouchInput.right_held = true)
	right_btn.button_up.connect(func(): TouchInput.right_held = false)
	act_btn.button_down.connect(TouchInput.press_act)
	act_btn.button_up.connect(TouchInput.release_act)
	# On a Mac with a keyboard the on-screen buttons stay out of the way.
	$Touch.visible = OS.get_name() in ["iOS", "Android"]


func setup(restaurant: Node) -> void:
	_restaurant = restaurant
	pause_menu.setup(restaurant)
	$Menu.add_theme_stylebox_override("panel", UiKit.panel(Color(0.16, 0.09, 0.07, 0.8), 22.0))
	UiKit.style_button(menu_btn, Color(0.35, 0.25, 0.22, 0.9), 44)
	menu_btn.custom_minimum_size = Vector2(96, 96)
	menu_btn.pressed.connect(_toggle_menu)
	$Menu.visible = false
	_build_menu(restaurant.day["dishes"])


func _toggle_menu() -> void:
	$Menu.visible = not $Menu.visible
	if $Menu.visible:
		UiKit.pop_in($Menu, 0.0)


## One row per dish: [dish] = [ingredient] + [ingredient] (+ [ingredient]), icons baked from the real models.
func _build_menu(dishes: Array) -> void:
	for c in menu_box.get_children():
		c.queue_free()
	for id in dishes:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_box.add_child(row)
		row.add_child(_icon(await icon_baker.bake(Recipes.DISHES[id]["model"]), 124))
		row.add_child(_symbol("="))
		var first := true
		for ing in Recipes.DISHES[id]["ingredients"]:
			if not first:
				row.add_child(_symbol("+"))
			first = false
			row.add_child(_icon(await icon_baker.bake(Recipes.INGREDIENTS[ing]["model"]), 100))


func _icon(tex: Texture2D, size: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _symbol(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.style_label(l, 44, UiKit.GOLD, 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause()


func _on_pause() -> void:
	if _restaurant and _restaurant.finished:
		return
	if get_tree().paused:
		pause_menu.close()
	else:
		pause_menu.open()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if is_inside_tree() and _restaurant and not get_tree().paused and not _restaurant.finished and _restaurant.running:
			pause_menu.open()


# --- state ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _shown_earnings != _target_earnings:
		var step := maxi(1, int(abs(_target_earnings - _shown_earnings) * 6.0 * delta) + 1)
		_shown_earnings = mini(_shown_earnings + step, _target_earnings) if _target_earnings > _shown_earnings else _target_earnings
		earnings_label.text = "%d" % _shown_earnings


func set_earnings(total: int, gained: int) -> void:
	_target_earnings = total
	if gained > 0:
		UiKit.pop(earnings_icon, 1.4, 0.3)


func set_streak(n: int) -> void:
	if n >= 2:
		streak_label.text = "×%s streak" % str(1.0 + 0.25 * minf(n, 8)).trim_suffix(".0")
		streak_label.modulate.a = 1.0
		UiKit.pop(streak_label, 1.3, 0.3)
	else:
		streak_label.modulate.a = 0.0


func set_day(index: int, day_name: String, handled: int, total: int) -> void:
	day_label.text = "Day %d · %s   %d / %d" % [index + 1, day_name, handled, total]


func set_strikes(n: int) -> void:
	var i := 0
	for s in strikes_box.get_children():
		var was: bool = s.on
		s.on = i < n
		if s.on and not was:
			UiKit.pop(s, 1.6, 0.35)
		i += 1


func flash_message(text: String, hold := 1.0) -> void:
	message.text = text
	message.pivot_offset = message.size / 2.0
	message.scale = Vector2(0.7, 0.7)
	var t := message.create_tween()
	t.tween_property(message, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(message, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold)
	t.tween_property(message, "modulate:a", 0.0, 0.3)


func show_title(text: String) -> void:
	title.text = text
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2(1.2, 1.2)
	var t := title.create_tween()
	t.tween_property(title, "modulate:a", 1.0, 0.25)
	t.parallel().tween_property(title, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.5)
	t.tween_property(title, "modulate:a", 0.0, 0.4)


func damage_flash() -> void:
	var mat := screen_fx.material as ShaderMaterial
	var t := create_tween()
	t.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.8, 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
