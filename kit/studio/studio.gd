extends Control
## Voice Studio: record the game's voice lines one by one.
## Keys: Space = record / stop, Enter = listen, Left/Right = previous / next line.

var voice_dir := ""
var lines: Array[Dictionary] = []   # {id, text, how}
var index := 0
var recording := false
var mic_ok := false

var _record_effect: AudioEffectRecord
var _mic_player: AudioStreamPlayer
var _playback: AudioStreamPlayer
var _bus := -1

var _counter: Label
var _text: Label
var _how: Label
var _status: Label
var _meter: ProgressBar
var _record_button: Button
var _listen_button: Button


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--voice-dir="):
			voice_dir = a.trim_prefix("--voice-dir=")
	_build_ui()
	if voice_dir == "" or not DirAccess.dir_exists_absolute(voice_dir):
		_show_problem("No game voice folder was given. Ask Claude to open the studio for you.")
		return
	_load_lines()
	if lines.is_empty():
		_show_problem("There are no lines to record yet. Ask Claude to write some.")
		return
	_setup_audio()
	_show_line()


# ------------------------------------------------------------ data

func _load_lines() -> void:
	var f := FileAccess.open(voice_dir.path_join("lines.txt"), FileAccess.READ)
	if f == null:
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var parts := line.split("|")
		if parts.size() < 2:
			continue
		lines.append({
			"id": parts[0].strip_edges(),
			"text": parts[1].strip_edges(),
			"how": parts[2].strip_edges() if parts.size() > 2 else "",
		})


func _clip_path(i: int) -> String:
	return voice_dir.path_join(lines[i].id + ".wav")


func _done_count() -> int:
	var n := 0
	for i in lines.size():
		if FileAccess.file_exists(_clip_path(i)):
			n += 1
	return n


# ------------------------------------------------------------ audio

func _setup_audio() -> void:
	_bus = AudioServer.bus_count
	AudioServer.add_bus(_bus)
	AudioServer.set_bus_name(_bus, "Record")
	AudioServer.set_bus_mute(_bus, true)   # don't play the mic back through the speakers
	_record_effect = AudioEffectRecord.new()
	AudioServer.add_bus_effect(_bus, _record_effect)
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = "Record"
	add_child(_mic_player)
	_mic_player.play()
	_playback = AudioStreamPlayer.new()
	add_child(_playback)
	mic_ok = AudioServer.get_input_device_list().size() > 0 and AudioServer.get_input_device() != ""


func _toggle_record() -> void:
	if lines.is_empty():
		return
	if not recording:
		_playback.stop()
		_record_effect.set_recording_active(true)
		recording = true
		_status.text = "Recording... press Space (or the button) when you're done."
	else:
		_record_effect.set_recording_active(false)
		recording = false
		var raw := _record_effect.get_recording()
		_save(raw)
	_refresh_buttons()


func _save(raw: AudioStreamWAV) -> void:
	if raw == null:
		_status.text = "Nothing was recorded. Is the microphone plugged in and allowed?"
		return
	var clean := VoiceClean.clean(raw)
	if clean == null:
		_status.text = "That was silent. Check the microphone, then try again."
		return
	var err := clean.save_to_wav(_clip_path(index))
	if err != OK:
		_status.text = "Could not save the recording (error %d)." % err
		return
	_status.text = "Saved (%.1f seconds). Listening back..." % VoiceClean.seconds(clean)
	_playback.stream = clean
	_playback.play()
	_show_line(false)


func _listen() -> void:
	if lines.is_empty() or not FileAccess.file_exists(_clip_path(index)):
		return
	_playback.stream = AudioStreamWAV.load_from_file(_clip_path(index))
	_playback.play()


func _process(_delta: float) -> void:
	if _meter == null or _bus < 0:
		return
	var db := AudioServer.get_bus_peak_volume_left_db(_bus, 0)
	_meter.value = clampf((db + 60.0) / 60.0, 0.0, 1.0) * 100.0


# ------------------------------------------------------------ navigation

func _go(step: int) -> void:
	if recording or lines.is_empty():
		return
	index = clampi(index + step, 0, lines.size() - 1)
	_show_line()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: _toggle_record()
			KEY_ENTER, KEY_KP_ENTER: _listen()
			KEY_LEFT: _go(-1)
			KEY_RIGHT: _go(1)


# ------------------------------------------------------------ UI

func _show_line(reset_status := true) -> void:
	var line: Dictionary = lines[index]
	var has_clip := FileAccess.file_exists(_clip_path(index))
	_counter.text = "Line %d of %d     (%d recorded)" % [index + 1, lines.size(), _done_count()]
	_text.text = line.text
	_how.text = ("How: " + line.how) if line.how != "" else ""
	if reset_status:
		if not mic_ok:
			_status.text = "No microphone found. Plug one in or allow microphone access, then reopen the studio."
		elif has_clip:
			_status.text = "Recorded ✓  Press Listen to hear it, or Record to try again."
		else:
			_status.text = "Not recorded yet. Press Record (or Space) and say the line."
	_refresh_buttons()


func _refresh_buttons() -> void:
	_record_button.text = "■  Stop" if recording else "●  Record"
	_record_button.modulate = Color("#ff6b6b") if recording else Color.WHITE
	_listen_button.disabled = recording or lines.is_empty() or not FileAccess.file_exists(_clip_path(index))


func _show_problem(message: String) -> void:
	_text.text = "Voice Studio"
	_status.text = message
	_record_button.disabled = true
	_listen_button.disabled = true


func _big_button(label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(190, 76)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(callback)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#24283b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 60; box.offset_right = -60; box.offset_top = 40; box.offset_bottom = -40
	box.add_theme_constant_override("separation", 22)
	add_child(box)
	_counter = _label(22, Color("#a9b1d6"))
	_text = _label(64, Color.WHITE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_how = _label(28, Color("#e0af68"))
	_meter = ProgressBar.new()
	_meter.custom_minimum_size = Vector2(0, 18)
	_meter.show_percentage = false
	_status = _label(24, Color("#c0caf5"))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.add_child(_big_button("◀  Back", _go.bind(-1)))
	_record_button = _big_button("●  Record", _toggle_record)
	row.add_child(_record_button)
	_listen_button = _big_button("▶  Listen", _listen)
	row.add_child(_listen_button)
	row.add_child(_big_button("Next  ▶", _go.bind(1)))
	for c in [_counter, _text, _how, _meter, _status, row]:
		box.add_child(c)


func _label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
