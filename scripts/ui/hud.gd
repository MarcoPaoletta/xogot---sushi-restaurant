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
	if $Touch.visible:
		# The recipe book lives in the bottom-right corner; lift it over the action button on phones.
		for c: Control in [menu_btn, $Menu]:
			c.offset_top -= 210.0
			c.offset_bottom -= 210.0


func setup(restaurant: Node) -> void:
	_restaurant = restaurant
	pause_menu.setup(restaurant)
	var board := StyleBoxFlat.new()
	board.bg_color = Color(0.99, 0.96, 0.9)
	board.set_corner_radius_all(28)
	board.set_content_margin_all(26)
	board.border_color = UiKit.WOOD
	board.set_border_width_all(6)
	board.shadow_color = Color(0, 0, 0, 0.3)
	board.shadow_size = 12
	board.shadow_offset = Vector2(0, 8)
	$Menu.add_theme_stylebox_override("panel", board)
	menu_box.add_theme_constant_override("separation", 14)
	UiKit.style_button(menu_btn, Color(0.35, 0.25, 0.22, 0.92), 48)
	menu_btn.custom_minimum_size = Vector2(96, 96)
	menu_btn.pressed.connect(_toggle_menu)
	$Menu.visible = false
	_build_menu(restaurant.day["dishes"])


func _toggle_menu() -> void:
	$Menu.visible = not $Menu.visible
	if $Menu.visible:
		UiKit.pop_in($Menu, 0.0)


## One row per dish: [ingredient] + [ingredient] = [dish], every icon baked from the real model.
func _build_menu(dishes: Array) -> void:
	for c in menu_box.get_children():
		c.queue_free()
	# Up to 7 dishes stack in one column; later days split the board into two columns.
	var columns: Array[VBoxContainer] = []
	var column_count := 1 if dishes.size() <= 7 else 2
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 48)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_box.add_child(strip)
	for i in column_count:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(col)
		columns.append(col)
	var per_column := int(ceil(float(dishes.size()) / column_count))
	for n in dishes.size():
		var id: String = dishes[n]
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		@warning_ignore("integer_division")
		columns[n / per_column].add_child(row)
		var first := true
		for ing in Recipes.DISHES[id]["ingredients"]:
			if not first:
				row.add_child(_symbol("+"))
			first = false
			row.add_child(_chip(await icon_baker.bake(Recipes.INGREDIENTS[ing]["model"]), 104, Recipes.INGREDIENTS[ing]["name"]))
		row.add_child(_symbol("="))
		row.add_child(_chip(await icon_baker.bake(Recipes.DISHES[id]["model"]), 124, Recipes.dish_name(id)))


## An icon on a rounded chip with its name underneath.
func _chip(tex: Texture2D, size: int, label_text: String) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.94, 0.9, 0.82)
	sb.set_corner_radius_all(20)
	sb.set_content_margin_all(6)
	sb.border_color = Color(0.86, 0.78, 0.66)
	sb.set_border_width_all(3)
	chip.add_theme_stylebox_override("panel", sb)
	chip.custom_minimum_size = Vector2(size, size)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(t)
	box.add_child(chip)
	var name_label := Label.new()
	name_label.text = label_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(size + 36, 0)
	UiKit.style_label(name_label, 20, UiKit.INK, 0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	return box


func _symbol(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.style_label(l, 52, UiKit.INK, 0)
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
