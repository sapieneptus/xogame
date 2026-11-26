extends Node
## Runs every test_*.gd in the kit's tests and the game's tests/ folder.
## Started by Kit when the game is launched with `-- --kit-test`.
## Options: --kit-test=<name> runs only tests whose file name contains <name>.
##          --kit-out=<folder> is where screenshots go.

var only := ""
var out_dir := "user://test-output"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kit-test="):
			only = a.trim_prefix("--kit-test=")
		elif a.begins_with("--kit-out="):
			out_dir = a.trim_prefix("--kit-out=")
	out_dir = ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(out_dir)
	# Fixed window size so screenshots and tap positions are predictable.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_run_all.call_deferred()


func _find_tests() -> Array[String]:
	var found: Array[String] = []
	for folder in ["res://addons/gamekit/tests/", "res://tests/"]:
		var d := DirAccess.open(folder)
		if d == null:
			continue
		for f in d.get_files():
			f = f.trim_suffix(".remap")
			if f.begins_with("test_") and f.ends_with(".gd") and (only == "" or f.contains(only)):
				found.append(folder + f)
	return found


func _run_all() -> void:
	var tree := get_tree()
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	var tests := _find_tests()
	var failed_tests := 0
	var all_shots: Array[String] = []
	print("\n=== Game checks (%d test files) ===" % tests.size())
	for path in tests:
		tree.change_scene_to_file(main_scene)
		for i in 3:
			await tree.process_frame
		var t: KitTest = load(path).new()
		t.tree = tree
		t.scene = tree.current_scene
		t.test_name = path.get_file().trim_prefix("test_").trim_suffix(".gd")
		t.out_dir = out_dir
		print("- ", t.test_name)
		await t.run()
		all_shots.append_array(t.screenshots)
		if t.failures.is_empty():
			print("  PASS (%d checks)" % t.checks)
		else:
			failed_tests += 1
			print("  FAILED %d of %d checks" % [t.failures.size(), t.checks])
	print("\nScreenshots:")
	for s in all_shots:
		print("  ", s)
	print("\nRESULT: ", "PASS" if failed_tests == 0 and tests.size() > 0 else "FAIL")
	tree.quit(0 if failed_tests == 0 and tests.size() > 0 else 1)
