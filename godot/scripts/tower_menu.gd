extends Control

## Animated tower for the map screen.
##
## Replaces the web build's looping "Tower Menu Animation 1400.mp4". Analysis of
## that clip showed the tower itself never moves — the only animation is lightning
## in the sky. So instead of shipping video, this composites three layers:
##
##   Base    a clean tower plate (the temporal median of the clip, bolts removed)
##   Bolt    one of 9 lightning shapes lifted from the clip, shown in bursts
##   Flash   a full-area sky glow, matching the web build's .tower-lightning CSS
##
## Result is sharper than the video, ~2.5 MB instead of a video decoder, and the
## strike timing is controllable instead of baked into a 5-second loop.
##
## The web build's own procedural lightning (startTowerAtmosphere) is gated behind
## TOWER_OVERLAYS_ENABLED = false, so the video's baked bolts were the only ones
## visible. This brings the two systems back together.

## Emitted on each strike so the map screen can play thunder. The web build
## synthesises this with the Web Audio API (playThunder: filtered noise + a
## 40-70 Hz sawtooth over 0.8-2.0 s) rather than using a sample, so there is no
## audio file to import — wire this up to a synthesised or sampled cue.
signal thunder

## Seconds between strikes, matching scheduleLightning() in index.html.
const STRIKE_DELAY_MIN := 2.0
const STRIKE_DELAY_MAX := 8.0

## Probability a strike is the longer, flickering kind (web build: Math.random() > 0.6).
const LONG_FLASH_CHANCE := 0.4

@onready var _bolt: TextureRect = $Bolt
@onready var _flash: TextureRect = $Flash

var _frames: SpriteFrames
var _bolt_count := 0
var _last_bolt := -1
var _tween: Tween


func _ready() -> void:
	_frames = load("res://assets/tower/tower_lightning.tres")
	if _frames and _frames.has_animation("bolts"):
		_bolt_count = _frames.get_frame_count("bolts")
	_bolt.modulate.a = 0.0
	_flash.modulate.a = 0.0
	if _bolt_count == 0:
		push_warning("tower_lightning.tres has no 'bolts' frames — tower will be static.")
		return
	_schedule_strike()


func _strike() -> void:
	# The timer outlives this node if the map screen is torn down mid-wait.
	if not is_inside_tree():
		return

	# Pick a bolt, never the same one twice in a row.
	var idx := randi() % _bolt_count
	if _bolt_count > 1 and idx == _last_bolt:
		idx = (idx + 1 + randi() % (_bolt_count - 1)) % _bolt_count
	_last_bolt = idx
	_bolt.texture = _frames.get_frame_texture("bolts", idx)

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)

	if randf() < LONG_FLASH_CHANCE:
		_flicker_long()
	else:
		_flicker_short()

	_tween.finished.connect(_schedule_strike, CONNECT_ONE_SHOT)
	thunder.emit()


func _schedule_strike() -> void:
	if not is_inside_tree():
		return
	get_tree().create_timer(randf_range(STRIKE_DELAY_MIN, STRIKE_DELAY_MAX)) \
		.timeout.connect(_strike)


## .12s linear fade — @keyframes lightning-flash
func _flicker_short() -> void:
	for node in [_bolt, _flash]:
		node.modulate.a = 1.0
		_tween.tween_property(node, "modulate:a", 0.0, 0.12)


## .6s stuttering fade — @keyframes lightning-flash-long, whose opacity stops are
## 0/.9, 8%/.15, 20%/.75, 35%/.1, 50%/.5, 70%/.15, 100%/0 over 600 ms.
func _flicker_long() -> void:
	const STOPS := [
		[0.00, 0.90], [0.08, 0.15], [0.20, 0.75], [0.35, 0.10],
		[0.50, 0.50], [0.70, 0.15], [1.00, 0.00],
	]
	const DURATION := 0.6
	for node in [_bolt, _flash]:
		node.modulate.a = STOPS[0][1]
		var prev: float = 0.0
		for i in range(1, STOPS.size()):
			var at: float = STOPS[i][0]
			var alpha: float = STOPS[i][1]
			_tween.tween_property(node, "modulate:a", alpha, (at - prev) * DURATION) \
				.set_delay(prev * DURATION)
			prev = at
