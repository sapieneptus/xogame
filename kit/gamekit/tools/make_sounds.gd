extends SceneTree
## Makes the kit's starter sounds from scratch (pure maths, no samples),
## so they are free to use for anything (public domain / CC0).
##
## Run:  godot --headless --path <game> -s res://addons/gamekit/tools/make_sounds.gd -- <output folder>
## Add new recipes at the bottom; each is a function returning samples in -1..1.

const RATE := 22050


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "res://assets/sounds"
	out = ProjectSettings.globalize_path(out) if out.begins_with("res://") else out
	DirAccess.make_dir_recursive_absolute(out)
	var recipes := {
		"pop": pop(), "chime": chime(), "fanfare": fanfare(), "sparkle": sparkle(),
		"boing": boing(), "whoosh": whoosh(), "tick": tick(), "bubble": bubble(),
		"tada": tada(), "music_box_loop": music_box_loop(),
	}
	for sound_name in recipes:
		var path: String = out.path_join(sound_name + ".wav")
		_save(recipes[sound_name], path)
		print("made ", path)
	quit()


# ------------------------------------------------------------ building blocks

func _save(samples: PackedFloat32Array, path: String) -> void:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	var gain := 0.85 / peak
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav(path)


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## A soft bell / music-box note: a few harmonics with exponential decay.
func _bell(buf: PackedFloat32Array, start: float, freq: float, length: float, amp := 1.0, decay := 6.0) -> void:
	var s0 := int(start * RATE)
	for i in int(length * RATE):
		if s0 + i >= buf.size():
			break
		var t := float(i) / RATE
		var env := exp(-t * decay) * minf(1.0, t * 400.0)
		var v := sin(TAU * freq * t) + 0.4 * sin(TAU * freq * 2.0 * t) * exp(-t * 4.0) + 0.15 * sin(TAU * freq * 3.01 * t) * exp(-t * 8.0)
		buf[s0 + i] += v * env * amp


func _note(semitones_from_c5: float) -> float:
	return 523.25 * pow(2.0, semitones_from_c5 / 12.0)


# ------------------------------------------------------------ recipes

func pop() -> PackedFloat32Array:
	var b := _buf(0.18)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 900.0 * exp(-t * 18.0) + 260.0
		phase += TAU * f / RATE
		b[i] = sin(phase) * exp(-t * 22.0) * minf(1.0, t * 800.0)
	return b


func chime() -> PackedFloat32Array:
	var b := _buf(1.2)
	_bell(b, 0.0, _note(7), 1.2, 1.0, 4.0)
	_bell(b, 0.0, _note(12), 1.2, 0.5, 5.0)
	return b


func fanfare() -> PackedFloat32Array:
	var b := _buf(1.6)
	var notes := [0, 4, 7, 12]
	for i in notes.size():
		_bell(b, i * 0.13, _note(notes[i]), 1.4, 0.9, 3.5)
	_bell(b, 0.52, _note(16), 1.0, 0.6, 3.0)
	_bell(b, 0.52, _note(19), 1.0, 0.4, 3.0)
	return b


func sparkle() -> PackedFloat32Array:
	var b := _buf(0.7)
	var notes := [12, 16, 19, 24, 28]
	for i in notes.size():
		_bell(b, i * 0.05, _note(notes[i]), 0.5, 0.6, 9.0)
	return b


func boing() -> PackedFloat32Array:
	var b := _buf(0.5)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 180.0 + 220.0 * (1.0 - exp(-t * 10.0)) + 25.0 * sin(TAU * 14.0 * t)
		phase += TAU * f / RATE
		b[i] = sin(phase) * exp(-t * 6.0) * minf(1.0, t * 500.0)
	return b


func whoosh() -> PackedFloat32Array:
	var b := _buf(0.45)
	var low := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in b.size():
		var t := float(i) / RATE
		var cutoff := 0.02 + 0.25 * sin(PI * t / 0.45)
		low += (rng.randf_range(-1, 1) - low) * cutoff
		b[i] = low * sin(PI * t / 0.45)
	return b


func tick() -> PackedFloat32Array:
	var b := _buf(0.06)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 1800.0 * t) * exp(-t * 90.0)
	return b


func bubble() -> PackedFloat32Array:
	var b := _buf(0.22)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 300.0 + 1400.0 * t / 0.22
		phase += TAU * f / RATE
		b[i] = sin(phase) * sin(PI * t / 0.22)
	return b


func tada() -> PackedFloat32Array:
	var b := _buf(2.0)
	for n in [0, 4, 7]:
		_bell(b, 0.0, _note(n - 12), 0.3, 0.5, 8.0)
	for n in [0, 4, 7, 12]:
		_bell(b, 0.18, _note(n), 1.8, 0.6, 2.5)
	return b


## A gentle 8-bar music-box loop on a pentatonic scale (always sounds calm).
func music_box_loop() -> PackedFloat32Array:
	var beat := 0.375
	var melody := [0, 4, 7, 9, 7, 4, 2, 4,  0, 2, 4, 7, 9, 7, 4, -1,
				   7, 9, 12, 9, 7, 4, 2, 0,  2, 4, 2, 0, -3, 0, -1, -1]
	var b := _buf(melody.size() * beat)
	for i in melody.size():
		if melody[i] >= -3 and melody[i] != -1:
			_bell(b, i * beat, _note(melody[i]), 1.5, 0.7, 3.0)
		if i % 4 == 0:
			var bass: int = [0, -5, -3, -7][(i / 8) % 4]
			_bell(b, i * beat, _note(bass - 12), 2.0, 0.35, 2.0)
	# Wrap the tail into the start so the loop is seamless.
	return b
