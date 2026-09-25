extends Control

## The two boot cards shown once at launch, before the title screen:
##   1. "a game by / emjayhar" in the MS-DOS font — white on black
##   2. the Godot Engine logo — white wordmark on black
## Each card fades in, holds, then fades out; a click or any key skips ahead
## (to the next card, or to the title). This screen is only entered at startup,
## so returning to the title from a menu later never replays it.

const HOLD := 1.6      # seconds a card stays fully visible
const FADE := 0.5      # fade-in / fade-out duration

var _card: Control
var _step := 0
var _tween: Tween


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_show_step(0)


func _show_step(step: int) -> void:
	_step = step
	if is_instance_valid(_card):
		_card.queue_free()

	match step:
		0: _card = _game_by_card()
		1: _card = _godot_card()
		_:
			RunState.set_screen("title")
			return

	_card.modulate.a = 0.0
	add_child(_card)

	_tween = create_tween()
	_tween.tween_property(_card, "modulate:a", 1.0, FADE)
	_tween.tween_interval(HOLD)
	_tween.tween_property(_card, "modulate:a", 0.0, FADE)
	_tween.tween_callback(_show_step.bind(step + 1))


## A click or any key press skips the current card immediately.
func _unhandled_input(event: InputEvent) -> void:
	var skip: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if skip:
		if _tween and _tween.is_valid():
			_tween.kill()
		get_viewport().set_input_as_handled()
		_show_step(_step + 1)


## Card 1: "a game by / emjayhar", centred, in the MS-DOS pixel font.
func _game_by_card() -> Control:
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)

	box.add_child(_dos_label("a game by", 34))
	box.add_child(_dos_label("emjayhar", 64))

	centre.add_child(box)
	return centre


func _dos_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font("dos"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	return l


## Card 2: the Godot Engine logo, centred on black.
func _godot_card() -> Control:
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var logo := TextureRect.new()
	logo.texture = load(AssetPaths.UI["godot_logo"])
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Roughly half the screen width, capped, at the logo's aspect ratio.
	var tex := logo.texture
	var aspect := float(tex.get_height()) / float(tex.get_width())
	var target_w := clampf(get_viewport_rect().size.x * 0.5, 360.0, 760.0)
	logo.custom_minimum_size = Vector2(target_w, target_w * aspect)

	centre.add_child(logo)
	return centre
