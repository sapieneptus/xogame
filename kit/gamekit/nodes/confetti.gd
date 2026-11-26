extends Node2D
## Confetti and stars bursting out from a point, then cleaning itself up.

@export var pieces := 60
@export var spread := 900.0
@export var lifetime := 1.8

var _parts := []
var _age := 0.0


func _ready() -> void:
	z_index = 100
	var colors: Array = Kit.COLORS.values()
	for i in pieces:
		var angle := randf_range(-PI, 0.0) if i % 3 else randf() * TAU
		_parts.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * randf_range(0.3, 1.0) * spread,
			"rot": randf() * TAU,
			"spin": randf_range(-10, 10),
			"color": colors[i % colors.size()],
			"size": randf_range(10, 22),
			"star": i % 4 == 0,
		})


func _process(delta: float) -> void:
	_age += delta
	for p in _parts:
		p.vel.y += 1400.0 * delta
		p.vel *= 0.985
		p.pos += p.vel * delta
		p.rot += p.spin * delta
	modulate.a = clampf((lifetime - _age) / 0.5, 0.0, 1.0)
	queue_redraw()
	if _age >= lifetime:
		queue_free()


func _draw() -> void:
	for p in _parts:
		draw_set_transform(p.pos, p.rot)
		if p.star:
			draw_colored_polygon(KitShape.make_points("star", p.size), p.color)
		else:
			draw_rect(Rect2(-p.size / 2, -p.size / 4, p.size, p.size / 2), p.color)
	draw_set_transform(Vector2.ZERO)
