class_name KitTest
extends RefCounted
## Base class for game tests. A test file lives in the game's tests/ folder,
## is named test_<something>.gd, extends KitTest and has `func run():`.
## The main scene is loaded fresh before each test file runs.
##
## Example:
##   extends KitTest
##   func run():
##       await shot("start")
##       await tap_center()
##       check(scene.get_node("Shapes").get_child_count() == 1, "A tap makes one shape")

var tree: SceneTree
var scene: Node            ## the game's main scene, freshly loaded
var test_name := ""
var out_dir := ""
var checks := 0
var failures: Array[String] = []
var screenshots: Array[String] = []


func run() -> void:
	pass


# ------------------------------------------------------------ checking

func check(ok: bool, what_should_happen: String) -> bool:
	checks += 1
	if not ok:
		failures.append(what_should_happen)
		print("  FAIL: ", what_should_happen)
	return ok


func check_eq(actual, expected, what_should_happen: String) -> bool:
	return check(actual == expected, "%s (expected %s, got %s)" % [what_should_happen, expected, actual])


# ------------------------------------------------------------ time

func wait(seconds: float) -> void:
	await tree.create_timer(seconds, true, false, true).timeout


func frames(n := 2) -> void:
	for i in n:
		await tree.process_frame


# ------------------------------------------------------------ input

func screen_size() -> Vector2:
	return scene.get_viewport().get_visible_rect().size


func center() -> Vector2:
	return screen_size() / 2.0


## Tap (click) a point given in game coordinates.
func tap(pos: Vector2, hold := 0.05) -> void:
	var win_pos := _to_window(pos)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = win_pos
	down.global_position = win_pos
	Input.parse_input_event(down)
	await wait(hold)
	var up := down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await frames(2)


func tap_center() -> void:
	await tap(center())


## Drag (mouse held down) from one point to another.
func drag(from: Vector2, to: Vector2, seconds := 0.4) -> void:
	var steps := maxi(4, int(seconds * 30))
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = _to_window(from)
	Input.parse_input_event(down)
	var last := from
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / steps)
		var m := InputEventMouseMotion.new()
		m.position = _to_window(p)
		m.relative = p - last
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(m)
		last = p
		await frames(1)
	var up := down.duplicate()
	up.pressed = false
	up.position = _to_window(to)
	Input.parse_input_event(up)
	await frames(2)


## Press and release a keyboard key, e.g. press(KEY_A) or press(KEY_SPACE).
func press(keycode: Key, hold := 0.05) -> void:
	key_down(keycode)
	await wait(hold)
	key_up(keycode)
	await frames(2)


func key_down(keycode: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.physical_keycode = keycode
	e.pressed = true
	Input.parse_input_event(e)


func key_up(keycode: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.physical_keycode = keycode
	e.pressed = false
	Input.parse_input_event(e)


## Mash random keys like a toddler would.
func mash(count := 20) -> void:
	var keys := [KEY_A, KEY_S, KEY_D, KEY_F, KEY_J, KEY_K, KEY_SPACE, KEY_ENTER, KEY_1, KEY_ESCAPE, KEY_TAB]
	for i in count:
		await press(keys[randi() % keys.size()], 0.02)


func _to_window(p: Vector2) -> Vector2:
	return scene.get_viewport().get_screen_transform() * p


# ------------------------------------------------------------ pictures

## Save a screenshot for Claude (and the human) to look at. Returns the image.
func shot(label: String) -> Image:
	await RenderingServer.frame_post_draw
	var img := scene.get_viewport().get_texture().get_image()
	var path := out_dir.path_join("%s_%02d_%s.png" % [test_name, screenshots.size() + 1, label])
	img.save_png(path)
	screenshots.append(path)
	return img


## Grab the screen without saving it (for before/after comparisons).
func grab() -> Image:
	await RenderingServer.frame_post_draw
	return scene.get_viewport().get_texture().get_image()


## Fraction (0..1) of sampled pixels that differ between two screenshots.
## Pass an area (e.g. around where you tapped) to ignore changes elsewhere,
## such as the mascot moving.
func difference(a: Image, b: Image, area := Rect2()) -> float:
	if a.get_size() != b.get_size():
		return 1.0
	var r := Rect2i(Vector2i.ZERO, a.get_size())
	if area.has_area():
		var scale_to_image := Vector2(a.get_size()) / screen_size()
		r = r.intersection(Rect2i(Rect2(area.position * scale_to_image, area.size * scale_to_image)))
	var changed := 0
	var total := 0
	for y in range(r.position.y, r.end.y, 4):
		for x in range(r.position.x, r.end.x, 4):
			total += 1
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.1:
				changed += 1
	return float(changed) / maxi(total, 1)


## A square area around a point, for difference().
func around(p: Vector2, half_size := 50.0) -> Rect2:
	return Rect2(p - Vector2(half_size, half_size), Vector2(half_size, half_size) * 2)
