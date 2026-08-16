extends Node

## Music and SFX playback, ported from the audio section of index.html.
##
## The web build had to work around browser autoplay policies — arming unlock
## handlers on the first pointerdown, retrying playback on gesture. None of that
## applies to a desktop build, so all of it is gone; tracks simply play.
##
## Music crossfades on change. SFX use a small pool of players so rapid
## overlapping plays (dragging cards quickly) do not cut each other off.

const SFX_POOL_SIZE := 6
const MUSIC_FADE_TIME := 0.8

const MUSIC_VOLUME := 0.4
const INTRO_VOLUME := 0.5

var _music: AudioStreamPlayer
var _music_fading: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _current_track := ""
var _last_game_track := ""


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)

	_music_fading = AudioStreamPlayer.new()
	_music_fading.bus = "Music"
	add_child(_music_fading)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	apply_volumes()


## Applies the saved volume sliders to the buses. Called on load and whenever
## the settings change.
func apply_volumes() -> void:
	_set_bus_volume("Music", float(SaveManager.profile.get("music_volume", 0.7)))
	_set_bus_volume("SFX", float(SaveManager.profile.get("sfx_volume", 0.7)))


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))


func play_music(path: String, volume: float = MUSIC_VOLUME) -> void:
	if path == _current_track and _music.playing:
		return
	_current_track = path

	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("Music track missing: %s" % path)
		return

	# Hand the outgoing track to the spare player so the new one can fade in
	# over it rather than cutting.
	if _music.playing:
		var tmp := _music
		_music = _music_fading
		_music_fading = tmp
		_fade_out(_music_fading)

	_loop_stream(stream)
	_music.stream = stream
	_music.volume_db = linear_to_db(0.001)
	_music.play()
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", linear_to_db(volume), MUSIC_FADE_TIME)


## Godot's MP3 import exposes looping on the stream itself rather than the
## player, so set it per-stream at playback time.
func _loop_stream(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _fade_out(player: AudioStreamPlayer) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(0.001), MUSIC_FADE_TIME)
	tween.tween_callback(player.stop)


func stop_music() -> void:
	_current_track = ""
	if _music.playing:
		_fade_out(_music)


func play_intro_music() -> void:
	play_music(AssetPaths.MUSIC_INTRO, INTRO_VOLUME)


func play_map_music() -> void:
	play_music(AssetPaths.MUSIC_MAP)


## Picks a random gameplay track, avoiding an immediate repeat.
func play_game_music() -> void:
	var options: Array = []
	for t in AssetPaths.MUSIC_GAME:
		if t != _last_game_track:
			options.append(t)
	if options.is_empty():
		options = AssetPaths.MUSIC_GAME.duplicate()
	_last_game_track = options[randi() % options.size()]
	play_music(_last_game_track)


func play_sfx(sfx_name: String) -> void:
	if not AssetPaths.SFX.has(sfx_name):
		return
	var stream := load(AssetPaths.SFX[sfx_name]) as AudioStream
	if stream == null:
		return
	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	player.stream = stream
	player.play()


func card_taken() -> void:
	play_sfx("taken")


func card_moved() -> void:
	play_sfx("moved")
