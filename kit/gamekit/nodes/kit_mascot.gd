class_name KitMascot
extends Node2D
## A friendly round character drawn in code (no art files).
## Change body_color, size and name per game. Call hop(), cheer(), look_at_point().

@export var body_color := Color("#7bd389")
@export var size := 110.0
@export var mascot_name := "Pip"

var _t := 0.0
var _blink := 0.0
var _next_blink := 2.0
var _squash := Vector2.ONE
var _look := Vector2.ZERO
var _cheering := 0.0
var _body := Node2D.new()


func _ready() -> void:
	add_child(_body)
	_body.draw.connect(_draw_body)


func _process(delta: float) -> void:
	_t += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.15
		_next_blink = randf_range(2.0, 4.5)
	_blink = maxf(0.0, _blink - delta)
	_cheering = maxf(0.0, _cheering - delta)
	_look = _look.lerp(Vector2.ZERO, delta * 1.5)
	_body.position.y = sin(_t * 2.2) * size * 0.04
	_body.scale = _squash
	_body.queue_redraw()


## A small happy jump. Good after every tap.
func hop() -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "_squash", Vector2(1.15, 0.85), 0.07)
	t.tween_property(self, "_squash", Vector2(0.9, 1.12), 0.1)
	t.parallel().tween_property(self, "position:y", position.y - size * 0.35, 0.12).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", position.y, 0.14).set_ease(Tween.EASE_IN)
	t.tween_property(self, "_squash", Vector2.ONE, 0.12)


## Big celebration: arms up, eyes closed with joy, a few hops.
func cheer(seconds := 1.6) -> void:
	_cheering = seconds
	for i in 3:
		get_tree().create_timer(i * 0.42).timeout.connect(hop)


func is_cheering() -> bool:
	return _cheering > 0.0


## Glance towards a point in the scene (e.g. where the child tapped).
func look_at_point(p: Vector2) -> void:
	_look = (p - global_position).normalized()


func _draw_body() -> void:
	var s := size
	var c := body_color
	# Shadow
	_body.draw_set_transform(Vector2(0, s * 0.95 - _body.position.y), 0, Vector2(1.0, 0.25))
	_body.draw_circle(Vector2.ZERO, s * 0.8, Color(0, 0, 0, 0.15))
	_body.draw_set_transform(Vector2.ZERO)
	# Arms (raised when cheering)
	var arm_up := _cheering > 0.0
	for side in [-1, 1]:
		var shoulder := Vector2(side * s * 0.8, s * 0.1)
		var hand := shoulder + (Vector2(side * s * 0.35, -s * 0.7) if arm_up else Vector2(side * s * 0.3, s * 0.35))
		_body.draw_line(shoulder, hand, c.darkened(0.15), s * 0.16, true)
		_body.draw_circle(hand, s * 0.12, c.darkened(0.15))
	# Feet
	for side in [-1, 1]:
		_body.draw_circle(Vector2(side * s * 0.4, s * 0.88), s * 0.2, c.darkened(0.25))
	# Body
	_body.draw_circle(Vector2.ZERO, s, c.darkened(0.3))
	_body.draw_circle(Vector2.ZERO, s * 0.95, c)
	_body.draw_circle(Vector2(-s * 0.3, -s * 0.35), s * 0.3, c.lightened(0.25))
	# Cheeks
	for side in [-1, 1]:
		_body.draw_circle(Vector2(side * s * 0.55, s * 0.2), s * 0.14, Color(1, 0.5, 0.6, 0.55))
	# Eyes
	var happy := _cheering > 0.0
	for side in [-1, 1]:
		var e := Vector2(side * s * 0.32, -s * 0.15)
		if happy:
			_body.draw_arc(e + Vector2(0, s * 0.05), s * 0.13, PI, TAU, 16, Color.BLACK, s * 0.06, true)
		elif _blink > 0.0:
			_body.draw_line(e - Vector2(s * 0.12, 0), e + Vector2(s * 0.12, 0), Color.BLACK, s * 0.06, true)
		else:
			_body.draw_circle(e, s * 0.17, Color.WHITE)
			var pupil := e + _look * s * 0.06
			_body.draw_circle(pupil, s * 0.1, Color("#222"))
			_body.draw_circle(pupil + Vector2(-s * 0.03, -s * 0.04), s * 0.035, Color.WHITE)
	# Mouth
	if happy:
		var mouth := PackedVector2Array()
		for i in 17:
			var a := PI * i / 16.0
			mouth.append(Vector2(cos(a) * s * 0.28, s * 0.25 + sin(a) * s * 0.25))
		_body.draw_colored_polygon(mouth, Color("#7a1f2b"))
	else:
		_body.draw_arc(Vector2(0, s * 0.22), s * 0.2, 0.15 * PI, 0.85 * PI, 16, Color("#3b2026"), s * 0.06, true)
