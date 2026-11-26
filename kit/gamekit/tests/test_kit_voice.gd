extends KitTest
## Kit check: missing voice lines are silent (no crash), and a freshly
## recorded clip plays straight away, before Godot has imported it.


func run() -> void:
	check(not Kit.say("no_such_line_xyz"), "A voice line that was never recorded stays silent")
	var dir := ProjectSettings.globalize_path("res://assets/voice")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("zz_kit_check.wav")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(22050)  # half a second of silence
	wav.data = data
	wav.save_to_wav(path)
	Kit.reload_sounds()
	check(Kit.say("zz_kit_check", true), "A freshly recorded voice line plays without re-importing")
	await wait(0.1)
	check(Kit.is_speaking(), "The voice line is actually playing")
	Kit._voice_player.stop()
	DirAccess.remove_absolute(path)
	Kit.reload_sounds()
