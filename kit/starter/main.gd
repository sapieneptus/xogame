extends Node2D
## Starter game: "Pop!"
## Any tap, click, drag or key makes a big bright shape pop up with a happy note.
## Every 10 pops fills the row of stars at the top and starts a celebration.
## No reading, no failing, no timers.

const POPS_PER_CELEBRATION := 10
const MAX_SHAPES := 18          ## older shapes fade away so the screen never fills up
const MIN_SECONDS_BETWEEN_POPS := 0.09   ## keeps key-mashing pleasant, not noisy

var pops := 0                   ## pops towards the next celebration
var celebrations := 0
var _since_last_pop := 1.0
var _drag_distance := 0.0
var _progress_colors: Array[Color] = []

@onready var shapes: Node2D = $Shapes
@onready var mascot: KitMascot = $Mascot


func _ready() -> void:
	Kit.play_music("music_box_loop")
	get_viewport().size_changed.connect(queue_redraw)


func _process(delta: float) -> void:
	_since_last_pop += delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pop_at(event.position)
	elif event is InputEventMouseMotion and event.button_mask != 0:
		# Dragging leaves a trail of little shapes (forgiving for trackpads).
		_drag_distance += event.relative.length()
		if _drag_distance > 90.0:
			_drag_distance = 0.0
			pop_at(event.position, 0.5)
	elif event is InputEventKey and event.pressed and not event.echo:
		pop_at(_random_spot())


## Make a shape at a point. size_factor < 1 makes a smaller one.
func pop_at(where: Vector2, size_factor := 1.0) -> void:
	if _since_last_pop < MIN_SECONDS_BETWEEN_POPS:
		return
	_since_last_pop = 0.0

	var color_name: String = Kit.COLORS.keys().pick_random()
	var shape := KitShape.new()
	shape.kind = KitShape.KINDS.pick_random()
	shape.color = Kit.COLORS[color_name]
	shape.color_name = color_name
	shape.radius = randf_range(70.0, 110.0) * size_factor
	shape.position = where
	shapes.add_child(shape)
	shape.pop_in()

	if shapes.get_child_count() > MAX_SHAPES:
		shapes.get_child(0).fade_out()

	Kit.play("pop", Kit.HAPPY_PITCHES.pick_random())
	# Says the colour if a grown-up has recorded it (e.g. "Red!"); silent otherwise.
	Kit.say(color_name)
	mascot.look_at_point(where)
	mascot.hop()

	pops += 1
	_progress_colors.append(shape.color)
	queue_redraw()
	if pops >= POPS_PER_CELEBRATION:
		celebrate()


func celebrate() -> void:
	celebrations += 1
	pops = 0
	_progress_colors.clear()
	queue_redraw()
	var middle := get_viewport_rect().size / 2.0
	Kit.celebrate(middle)
	Kit.celebrate(mascot.position + Vector2(0, -80))
	Kit.play("fanfare")
	if not Kit.say("well_done", true):
		Kit.play("sparkle")
	mascot.cheer()
	for shape in shapes.get_children():
		shape.wiggle()


func shape_count() -> int:
	var n := 0
	for s in shapes.get_children():
		if not s.is_queued_for_deletion() and s.modulate.a > 0.5:
			n += 1
	return n


func _random_spot() -> Vector2:
	var size := get_viewport_rect().size
	return Vector2(randf_range(0.2, 0.85) * size.x, randf_range(0.28, 0.75) * size.y)


func _draw() -> void:
	var size := get_viewport_rect().size
	# Sky
	draw_rect(Rect2(Vector2.ZERO, size), Color("#bde4ff"))
	draw_rect(Rect2(0, size.y * 0.45, size.x, size.y * 0.55), Color("#d4efff"))
	# Hills
	var hill := PackedVector2Array([Vector2(0, size.y)])
	for i in 33:
		var x := size.x * i / 32.0
		hill.append(Vector2(x, size.y * 0.82 + sin(i * 0.45) * 22.0))
	hill.append(Vector2(size.x, size.y))
	draw_colored_polygon(hill, Color("#9be08f"))
	# Progress stars along the top: fill one per pop.
	var gap := 76.0
	var left := size.x / 2.0 - gap * (POPS_PER_CELEBRATION - 1) / 2.0
	for i in POPS_PER_CELEBRATION:
		var c := Vector2(left + i * gap, 56)
		var pts := KitShape.make_points("star", 30)
		var moved := PackedVector2Array()
		for p in pts:
			moved.append(p + c)
		if i < _progress_colors.size():
			draw_colored_polygon(moved, _progress_colors[i])
		else:
			draw_colored_polygon(moved, Color(1, 1, 1, 0.55))
