extends TextureRect

## Looping tower animation for the map screen.
##
## Plays the frames extracted from "Tower Menu Animation 1400.mp4" — the real
## footage, unaltered, just decoded ahead of time because Godot cannot play MP4.
##
## 76 frames at 15 fps = the original 5.07 second loop. Frames are stored at
## 700x933, the size the tower is actually displayed at, as lossless WebP.
##
## TextureRect rather than AnimatedSprite2D so the tower participates in the
## map screen's Control layout instead of needing manual pixel positioning.

const ANIMATION_PATH := "res://assets/tower/tower_animation.tres"
const ANIMATION_NAME := &"tower"

## Frames per second. The source clip is 30 fps; every second frame was kept.
@export var fps := 15.0

## Uncheck to freeze on the first frame (useful when editing the map layout).
@export var playing := true

var _frames: SpriteFrames
var _count := 0
var _index := 0
var _accumulator := 0.0


func _ready() -> void:
	_frames = load(ANIMATION_PATH)
	if _frames == null or not _frames.has_animation(ANIMATION_NAME):
		push_error("Tower animation missing or has no '%s' track: %s" % [ANIMATION_NAME, ANIMATION_PATH])
		set_process(false)
		return

	_count = _frames.get_frame_count(ANIMATION_NAME)
	if _count == 0:
		push_error("Tower animation has no frames.")
		set_process(false)
		return

	texture = _frames.get_frame_texture(ANIMATION_NAME, 0)


func _process(delta: float) -> void:
	if not playing or _count == 0 or fps <= 0.0:
		return

	_accumulator += delta
	var step := 1.0 / fps
	var advanced := false
	# A while loop rather than a single step so a dropped frame catches up
	# instead of stretching the loop.
	while _accumulator >= step:
		_accumulator -= step
		_index = (_index + 1) % _count
		advanced = true

	if advanced:
		texture = _frames.get_frame_texture(ANIMATION_NAME, _index)
