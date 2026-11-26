class_name VoiceClean
extends RefCounted
## Tidies a raw microphone recording: trims silence at both ends,
## makes it mono, and evens out the volume. Pure functions, easy to test.

const SILENCE := 0.03        ## below this (0..1) counts as silence
const PADDING_SECONDS := 0.08
const TARGET_PEAK := 0.9


static func clean(raw: AudioStreamWAV) -> AudioStreamWAV:
	var mono := to_mono_floats(raw)
	var rate := raw.mix_rate
	var first := -1
	var last := -1
	for i in mono.size():
		if absf(mono[i]) > SILENCE:
			if first < 0:
				first = i
			last = i
	if first < 0:
		return null   # nothing but silence
	var pad := int(PADDING_SECONDS * rate)
	first = maxi(0, first - pad)
	last = mini(mono.size() - 1, last + pad)
	var peak := 0.0001
	for i in range(first, last + 1):
		peak = maxf(peak, absf(mono[i]))
	var gain := TARGET_PEAK / peak
	var count := last - first + 1
	var fade := mini(int(0.01 * rate), count / 4)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var v := mono[first + i] * gain
		if i < fade:
			v *= float(i) / fade
		elif i > count - fade:
			v *= float(count - i) / fade
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var out := AudioStreamWAV.new()
	out.format = AudioStreamWAV.FORMAT_16_BITS
	out.mix_rate = rate
	out.stereo = false
	out.data = data
	return out


static func to_mono_floats(raw: AudioStreamWAV) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if raw.format != AudioStreamWAV.FORMAT_16_BITS:
		push_error("VoiceClean expects 16-bit audio")
		return out
	var channels := 2 if raw.stereo else 1
	var frames := raw.data.size() / (2 * channels)
	out.resize(frames)
	for f in frames:
		var sum := 0.0
		for c in channels:
			sum += raw.data.decode_s16((f * channels + c) * 2) / 32768.0
		out[f] = sum / channels
	return out


static func seconds(stream: AudioStreamWAV) -> float:
	var channels := 2 if stream.stereo else 1
	return stream.data.size() / float(2 * channels * stream.mix_rate)
