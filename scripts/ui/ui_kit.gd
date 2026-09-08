class_name UiKit
## Shared styling so every screen looks like one game.

const INK := Color(0.2, 0.1, 0.08)
const PAPER := Color(1.0, 0.97, 0.9)
const ACCENT := Color(0.86, 0.23, 0.2)     # lantern red
const ACCENT2 := Color(0.36, 0.66, 0.42)   # wasabi green
const WOOD := Color(0.72, 0.5, 0.3)
const GOLD := Color(1.0, 0.8, 0.3)
const FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")


static func style_button(b: Button, color := ACCENT, font_size := 40) -> void:
	b.add_theme_stylebox_override("normal", _box(color, 22.0))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.12), 22.0))
	var pressed := _box(color.darkened(0.15), 22.0)
	pressed.content_margin_top = 14.0
	pressed.shadow_size = 0
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", _box(color.lightened(0.12), 22.0))
	b.add_theme_stylebox_override("disabled", _box(Color(0.55, 0.5, 0.48), 22.0))
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", PAPER)
	b.add_theme_color_override("font_pressed_color", PAPER)
	b.add_theme_color_override("font_disabled_color", Color(0.85, 0.82, 0.8))
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 6)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", font_size)
	b.custom_minimum_size = Vector2(maxf(b.custom_minimum_size.x, 260), maxf(b.custom_minimum_size.y, 96))
	b.focus_mode = Control.FOCUS_NONE
	if not b.pressed.is_connected(_click_sound):
		b.pressed.connect(_click_sound)
	if not b.button_down.is_connected(_squash.bind(b)):
		b.button_down.connect(_squash.bind(b))


static func _click_sound() -> void:
	Audio.play("ui", 1.0, -6.0)


static func _squash(b: Button) -> void:
	b.pivot_offset = b.size / 2.0
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2(0.94, 0.94), 0.05)
	t.tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _box(color: Color, radius: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(int(radius))
	s.set_content_margin_all(18.0)
	s.content_margin_bottom = 22.0
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 6)
	return s


static func panel(color := Color(0.16, 0.09, 0.07, 0.88), radius := 32.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(int(radius))
	s.set_content_margin_all(40.0)
	s.border_color = WOOD
	s.set_border_width_all(4)
	return s


static func style_label(l: Label, size := 40, color := PAPER, outline := 8) -> void:
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)


static func style_title(l: Label, size := 96) -> void:
	style_label(l, size, PAPER, 14)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_y", 8)


## Fly-in animation for a control: from an offset + fade.
static func fly_in(c: Control, delay := 0.0, from := Vector2(0, 60)) -> void:
	var target := c.position
	c.position = target + from
	c.modulate.a = 0.0
	var t := c.create_tween().set_parallel(true)
	t.tween_property(c, "position", target, 0.45).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, 0.3).set_delay(delay)


## Pop a control (scale up and back).
static func pop(c: Control, amount := 1.3, time := 0.25) -> void:
	c.pivot_offset = c.size / 2.0
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2.ONE * amount, time * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2.ONE, time * 0.65).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Pop-in for container children (never touches position): scale from 0.8 + fade.
static func pop_in(c: Control, delay := 0.0) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(0.8, 0.8)
	var t := c.create_tween().set_parallel(true)
	t.tween_callback(func(): c.pivot_offset = c.size / 2.0).set_delay(delay)
	t.tween_property(c, "modulate:a", 1.0, 0.25).set_delay(delay)
	t.tween_property(c, "scale", Vector2.ONE, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
