class_name KitShape
extends Node2D
## A big, bright shape that pops in with a bounce. No image files needed.

const KINDS := ["circle", "star", "square", "triangle", "heart"]

@export_enum("circle", "star", "square", "triangle", "heart") var kind := "circle"
@export var color := Color("#3a86ff")
@export var radius := 90.0
@export var outline := true

var color_name := ""


func _ready() -> void:
	queue_redraw()


func pop_in(duration := 0.35) -> void:
	scale = Vector2.ZERO
	rotation = randf_range(-0.3, 0.3)
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, duration)


func wiggle() -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "rotation", rotation + 0.25, 0.08)
	t.tween_property(self, "rotation", rotation - 0.25, 0.12)
	t.tween_property(self, "rotation", rotation, 0.08)


func fade_out(duration := 0.6) -> void:
	var t := create_tween().set_parallel()
	t.tween_property(self, "modulate:a", 0.0, duration)
	t.tween_property(self, "scale", Vector2(0.6, 0.6), duration)
	t.chain().tween_callback(queue_free)


func points() -> PackedVector2Array:
	return KitShape.make_points(kind, radius)


static func make_points(shape_kind: String, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape_kind:
		"star":
			for i in 10:
				var a := -PI / 2 + i * PI / 5
				var rr := r if i % 2 == 0 else r * 0.45
				pts.append(Vector2(cos(a), sin(a)) * rr)
		"square":
			var s := r * 0.85
			pts = PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
		"triangle":
			for i in 3:
				var a := -PI / 2 + i * TAU / 3
				pts.append(Vector2(cos(a), sin(a)) * r * 1.1)
		"heart":
			for i in 48:
				var t := TAU * i / 48.0
				var x := 16 * pow(sin(t), 3)
				var y := -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
				pts.append(Vector2(x, y) * r / 16.0)
		_:
			for i in 48:
				var a := TAU * i / 48.0
				pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _draw() -> void:
	var pts := points()
	# Soft shadow, body, highlight, outline: reads well on any background.
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(0, radius * 0.08))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.18))
	draw_colored_polygon(pts, color)
	var shine := PackedVector2Array()
	for p in pts:
		shine.append(p * 0.55 + Vector2(-radius * 0.18, -radius * 0.2))
	draw_colored_polygon(shine, color.lightened(0.25))
	if outline:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, color.darkened(0.35), maxf(4.0, radius * 0.07), true)
