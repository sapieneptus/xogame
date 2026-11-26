extends SceneTree
## Checks VoiceClean on a fake recording: 1 s silence, 0.5 s quiet tone, 1 s silence.

func _init() -> void:
	var rate := 44100
	var data := PackedByteArray()
	var frames := int(2.5 * rate)
	data.resize(frames * 4)
	for f in frames:
		var t := float(f) / rate
		var v := 0.0
		if t >= 1.0 and t < 1.5:
			v = 0.2 * sin(TAU * 440.0 * t)
		elif randf() < 0.5:
			v = randf_range(-0.005, 0.005)  # room noise
		data.encode_s16(f * 4, int(v * 32767))
		data.encode_s16(f * 4 + 2, int(v * 32767))
	var raw := AudioStreamWAV.new()
	raw.format = AudioStreamWAV.FORMAT_16_BITS
	raw.mix_rate = rate
	raw.stereo = true
	raw.data = data
	var out := VoiceClean.clean(raw)
	var secs := VoiceClean.seconds(out)
	var peak := 0.0
	for x in VoiceClean.to_mono_floats(out):
		peak = maxf(peak, absf(x))
	var ok := not out.stereo and secs > 0.6 and secs < 0.75 and peak > 0.85 and peak < 0.95
	var silent := AudioStreamWAV.new()
	silent.format = AudioStreamWAV.FORMAT_16_BITS
	silent.mix_rate = rate
	silent.data = PackedByteArray([0, 0, 0, 0])
	ok = ok and VoiceClean.clean(silent) == null
	print("trimmed to %.2fs, peak %.2f, mono %s -> %s" % [secs, peak, not out.stereo, "PASS" if ok else "FAIL"])
	quit(0 if ok else 1)
