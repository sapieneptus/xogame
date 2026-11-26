extends Node
## Game Maker kit. Loaded automatically in every game as `Kit`.
## Do not edit this folder inside a game: it is replaced on update.
## Put game-specific code in the game's own scripts instead.

const KIT_VERSION := "0.1.0"

## Hold these three keys together for this long to leave kid mode.
const GROWNUP_EXIT_KEYS := [KEY_CTRL, KEY_SHIFT, KEY_Q]
const GROWNUP_EXIT_SECONDS := 2.0

signal grownup_exit_progress(fraction: float)

var kid_mode := true
var test_mode := false
var exit_requested := false  ## set when the grown-up exit fires (tests read this)
var _exit_hold := 0.0
var _players: Array[AudioStreamPlayer] = []
var _voice_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _stream_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	test_mode = Array(args).any(func(a): return a.begins_with("--kit-test"))
	if args.has("--windowed") or test_mode:
		kid_mode = false
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_voice_player = AudioStreamPlayer.new()
	add_child(_voice_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -10.0
	add_child(_music_player)
	if kid_mode:
		_enter_kid_mode()
	if test_mode:
		var runner = load("res://addons/gamekit/tests/runner.gd").new()
		add_child(runner)


# ---------------------------------------------------------------- kid mode

func _enter_kid_mode() -> void:
	# Fullscreen, ignore the window's close button and Alt+F4.
	# The operating system's own shortcuts (Windows key, Alt+Tab) cannot be
	# blocked from inside a game; a grown-up should stay nearby.
	get_tree().set_auto_accept_quit(false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not kid_mode:
		get_tree().quit()


func _process(delta: float) -> void:
	if not kid_mode:
		return
	var held := GROWNUP_EXIT_KEYS.all(func(k): return Input.is_physical_key_pressed(k))
	var before := _exit_hold
	_exit_hold = _exit_hold + delta if held else 0.0
	if _exit_hold != before:
		grownup_exit_progress.emit(clampf(_exit_hold / GROWNUP_EXIT_SECONDS, 0.0, 1.0))
	if _exit_hold >= GROWNUP_EXIT_SECONDS:
		_exit_hold = 0.0
		exit_requested = true
		if not test_mode:
			get_tree().quit()


# ---------------------------------------------------------------- sound

## Play a sound effect by name, e.g. Kit.play("pop").
## Looks in the game's assets/sounds first, then the kit's starter sounds.
func play(sound_name: String, pitch := 1.0, volume_db := 0.0) -> void:
	var stream := _find_stream(sound_name, ["res://assets/sounds/", "res://addons/gamekit/assets/sounds/"])
	if stream == null:
		push_warning("Kit.play: no sound called '%s'" % sound_name)
		return
	var player := _free_player()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


## Play a recorded voice line from assets/voice/<line_id>.wav.
## Returns false (and stays silent) if it has not been recorded yet,
## so games work before any voice lines exist.
func say(line_id: String, interrupt := false) -> bool:
	if _voice_player.playing and not interrupt:
		return false
	var stream := _find_stream(line_id, ["res://assets/voice/"])
	if stream == null:
		return false
	_voice_player.stream = stream
	_voice_player.play()
	return true


func is_speaking() -> bool:
	return _voice_player.playing


func play_music(sound_name: String) -> void:
	var stream := _find_stream(sound_name, ["res://assets/music/", "res://addons/gamekit/assets/sounds/"])
	if stream == null:
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / (2 * (2 if stream.stereo else 1))
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]


func _find_stream(stream_name: String, folders: Array) -> AudioStream:
	for folder in folders:
		var path: String = folder + stream_name + ".wav"
		if _stream_cache.has(path):
			return _stream_cache[path]
		var stream: AudioStream = null
		if ResourceLoader.exists(path):
			stream = load(path)
		elif FileAccess.file_exists(path):
			# Freshly recorded and not imported yet.
			stream = AudioStreamWAV.load_from_file(path)
		if stream:
			_stream_cache[path] = stream
			return stream
	return null


## Forget cached sounds (used after recording new voice lines).
func reload_sounds() -> void:
	_stream_cache.clear()


# ---------------------------------------------------------------- effects

## Burst of confetti at a point. Returns the effect node.
func celebrate(at: Vector2, parent: Node = null) -> Node2D:
	var c = preload("res://addons/gamekit/nodes/confetti.gd").new()
	c.position = at
	(parent if parent else get_tree().current_scene).add_child(c)
	return c


## Bright, friendly colours with names (names match voice line ids).
const COLORS := {
	"red": Color("#ff4d4d"),
	"orange": Color("#ff9f1c"),
	"yellow": Color("#ffd23f"),
	"green": Color("#3bc14a"),
	"blue": Color("#3a86ff"),
	"purple": Color("#9b5de5"),
	"pink": Color("#ff70a6"),
}

## Musical notes that always sound nice together (pentatonic scale),
## as pitch multipliers. Use for anything a child can mash.
const HAPPY_PITCHES := [1.0, 1.122, 1.26, 1.498, 1.682, 2.0]
