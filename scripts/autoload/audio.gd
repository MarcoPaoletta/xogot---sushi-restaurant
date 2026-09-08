extends Node
## SFX pool + music player. Streams live in res://assets/audio (generated WAVs).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 12

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_index := 0
var _music: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music := ""
var _music_enabled := true
var _sfx_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = "Music"
	add_child(_music_b)
	set_music_enabled(Game.save_data.get("music", true))
	set_sfx_enabled(Game.save_data.get("sfx", true))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _stream(stream_name: String, dir: String, looping: bool) -> AudioStream:
	var key := dir + stream_name
	if _streams.has(key):
		return _streams[key]
	var path := key + ".wav"
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	if s is AudioStreamWAV and looping:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		@warning_ignore("integer_division")
		s.loop_end = s.data.size() / 2
	_streams[key] = s
	return s


## Play a one-shot sound effect.
func play(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _sfx_enabled:
		return
	var s := _stream(sfx_name, SFX_DIR, false)
	if s == null:
		return
	var p := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## Random-pitch variant helper.
func play_var(sfx_name: String, spread: float = 0.08, volume_db: float = 0.0) -> void:
	play(sfx_name, randf_range(1.0 - spread, 1.0 + spread), volume_db)


func play_music(music_name: String, fade: float = 0.8, pitch: float = 1.0) -> void:
	if music_name == _current_music and is_equal_approx(_music.pitch_scale, pitch):
		return
	_current_music = music_name
	var s := _stream(music_name, MUSIC_DIR, music_name != "results")
	var old := _music
	_music = _music_b
	_music_b = old
	if s:
		_music.stream = s
		_music.pitch_scale = pitch
		_music.volume_db = -40.0
		_music.play()
		create_tween().tween_property(_music, "volume_db", 0.0, fade)
	if old.playing:
		var t := create_tween()
		t.tween_property(old, "volume_db", -40.0, fade)
		t.tween_callback(old.stop)


func duck_music(db: float, time: float = 0.3) -> void:
	var idx := AudioServer.get_bus_index("Music")
	var tw := create_tween()
	tw.tween_method(func(v): AudioServer.set_bus_volume_db(idx, v), AudioServer.get_bus_volume_db(idx), db, time)


func set_music_enabled(on: bool) -> void:
	_music_enabled = on
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not on)


func set_sfx_enabled(on: bool) -> void:
	_sfx_enabled = on
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not on)
