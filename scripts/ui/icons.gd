class_name IconControl
extends Control
## Vector icons drawn in code (no icon textures in the packs): coin, star, strike, lock.

@export_enum("coin", "star", "strike", "lock") var icon := "star"
@export var on := true:
	set(v):
		on = v
		queue_redraw()
@export var color := Color(1.0, 0.8, 0.3)


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	var col := color if on else Color(1, 1, 1, 0.22)
	var ink := Color(0.2, 0.1, 0.08, 1.0 if on else 0.3)
	match icon:
		"coin":
			draw_circle(c, r, ink)
			draw_circle(c, r * 0.86, col)
			draw_circle(c, r * 0.55, col.darkened(0.2))
			draw_circle(c, r * 0.42, col)
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				var rr := r if i % 2 == 0 else r * 0.45
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(pts, ink)
			var inner := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				var rr := r * 0.84 if i % 2 == 0 else r * 0.38
				inner.append(c + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(inner, col)
		"strike":
			draw_circle(c, r, ink)
			draw_circle(c, r * 0.84, col if on else Color(0.35, 0.3, 0.3, 0.6))
			if on:
				var w := r * 0.22
				draw_line(c + Vector2(-r, -r) * 0.5, c + Vector2(r, r) * 0.5, ink, w, true)
				draw_line(c + Vector2(-r, r) * 0.5, c + Vector2(r, -r) * 0.5, ink, w, true)
		"lock":
			var body := Rect2(c + Vector2(-r * 0.7, -r * 0.05), Vector2(r * 1.4, r * 1.05))
			draw_rect(body, ink)
			draw_rect(body.grow(-r * 0.12), col)
			draw_arc(c + Vector2(0, -r * 0.1), r * 0.45, PI, TAU, 24, ink, r * 0.22, true)
			draw_circle(c + Vector2(0, r * 0.45), r * 0.16, ink)
