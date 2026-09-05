extends Control


## A speech bubble's pointy tail, drawn in _draw so it cannot be resized by the
## layout the way a Panel child would be. Extends MarginContainer, whose margin
## on the pointing side reserves the space the triangle is painted into.
##   "left" — points toward John Dee's portrait (his lines)
##   "down" — points down toward the viewer (the player's lines)
## The base of the triangle overlaps a few pixels into the bubble so the white
## fill blends over the bubble's black border, and only the two outer edges are
## outlined — so it reads as a real comic-book tail, not a square notch.
class BubbleTail extends MarginContainer:
	const REACH := 22.0   # how far the point sticks out past the bubble
	const SPREAD := 28.0  # width of the tail where it meets the bubble
	var dir := "left"

	func _draw() -> void:
		var fill := Color.WHITE
		var line := Color.BLACK
		var overlap := 4.0  # push the base into the bubble to cover its border
		if dir == "down":
			var base_y := size.y - REACH
			var cx := 46.0
			var a := Vector2(cx, base_y - overlap)
			var b := Vector2(cx + SPREAD, base_y - overlap)
			var tip := Vector2(cx + SPREAD * 0.4, size.y - 1.0)
			draw_colored_polygon([a, b, tip], fill)
			draw_line(a, tip, line, 3.0)
			draw_line(b, tip, line, 3.0)
		else:  # left
			var base_x := REACH
			var cy := 26.0
			var a := Vector2(base_x + overlap, cy)
			var b := Vector2(base_x + overlap, cy + SPREAD)
			var tip := Vector2(1.0, cy + SPREAD * 0.4)
			draw_colored_polygon([a, b, tip], fill)
			draw_line(a, tip, line, 3.0)
			draw_line(b, tip, line, 3.0)


## Every conversation in the game, rebuilt to match the web build's two modes.
##
## Ported from renderPatronDialogue in index.html, which switches presentation
## partway through the intro:
##
##   PLAIN   Before John Dee's face has appeared. Full-screen black, a
##           fixed-aspect image frame at a constant height, text directly below
##           it, and a Continue / Skip footer. Because the frame never resizes,
##           images and text stay at the same level whatever the beat contains —
##           text-only beats reserve the same (invisible) slot.
##
##   CALL    Once a `dee` beat has been reached. A Windows-95 "Incoming
##           Transmission" window: title bar with window buttons, Dee's portrait
##           filling the left 42%, and the line on the right styled by speaker —
##           narration in an inset box, Dee in a speech bubble, the player as
##           plain white text.
##
## The switch is one-way and sticky: patronDlgFaceSeen() scans every beat up to
## the current one, so once the face appears the call window stays for the rest
## of the intro. Dee's interludes and the victory exchange always use CALL,
## since by then the player knows him.
##
## Choices do not branch — picking one simply advances, as in the web build.

const FRAME_ASPECT := 260.0 / 220.0
const FRAME_MAX_WIDTH := 640.0
const FRAME_WIDTH_RATIO := 0.92
const FRAME_TOP_RATIO := 0.06
const FRAME_MAX_HEIGHT_RATIO := 0.64

const PLAIN_TEXT := Color("e8e0d0")
const PORTRAIT_LABEL := Color("39ff6a")

## The flicker overlay's keyframes, as (time in seconds, alpha). Taken from
## @keyframes patron-img-flicker: 1.1s, steps(1, end), infinite.
const FLICKER_STEPS := [
	[0.000, 0.0], [0.088, 1.0], [0.154, 0.0], [0.418, 0.0],
	[0.484, 1.0], [0.572, 0.0], [0.814, 1.0], [0.880, 0.0],
]
const FLICKER_PERIOD := 1.1

## Arranged layout for the four-image beat, from the nth-child rules:
## [width ratio, max-height ratio, centre x ratio, centre y ratio].
## Entries 3 and 4 pin to the left and right edges instead of centring.
const ARRANGED := [
	{"w": 0.30, "h": 0.26, "cx": 0.50, "top": 0.16},
	{"w": 0.34, "h": 0.42, "cx": 0.50, "top": 0.42},
	{"w": 0.26, "h": 0.60, "left": 0.02, "cy": 0.50},
	{"w": 0.26, "h": 0.60, "right": 0.02, "cy": 0.50},
]

var _beats: Array = []
var _topics: Array = []
var _index := 0
var _seen_key := ""
var _active_topic: Dictionary = {}
var _victory_choice := -1
var _is_intro := false

# Plain mode nodes.
var _plain: Control
var _frame: Control
var _plain_text: Label
var _plain_choices: VBoxContainer
var _plain_footer: VBoxContainer
var _plain_next: Button
var _plain_skip: Button

# Call mode nodes.
var _call: Control
var _portrait: TextureRect
var _content: VBoxContainer
var _call_footer: HBoxContainer
var _call_next: Button

var _arranged_rects: Array = []


func _ready() -> void:
	_build_plain()
	_build_call()
	_configure()
	_render()


func _configure() -> void:
	match RunState.screen:
		"patron-dialogue":
			_beats = Narrative.DEE_DIALOGUE
			_is_intro = true
		"dee-checkin-dialogue":
			_beats = Narrative.DEE_CHECKIN_INTRO
			_topics = Narrative.DEE_CHECKIN_TOPICS
			_seen_key = "seen_dee_topics"
		"dee-dialogue3":
			_beats = Narrative.DEE_DIALOGUE3_INTRO
			_topics = Narrative.DEE_DIALOGUE3_TOPICS
			_seen_key = "seen_dee3_topics"
		"dee-final-dialogue":
			_beats = Narrative.DEE_FINAL
		"victory-dialogue":
			_beats = []
			for line in Narrative.VICTORY_LINES:
				_beats.append({"speaker": "dee", "text": line})
		_:
			_beats = []


## True once any beat up to and including the current one was spoken by Dee.
## Ported from patronDlgFaceSeen: the transition is sticky, not per-beat.
func _face_seen() -> bool:
	if not _is_intro:
		return true
	for i in range(0, mini(_index + 1, _beats.size())):
		if String(_beats[i].get("speaker", "")) == "dee":
			return true
	return false


# ══════════════════════════════════════════════════════════════════════════════
#  Plain mode — the cinematic run before Dee appears
# ══════════════════════════════════════════════════════════════════════════════

func _build_plain() -> void:
	_plain = Control.new()
	_plain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_plain)

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plain.add_child(bg)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 0)
	_plain.add_child(column)

	# The image frame keeps a constant size so nothing below it ever shifts.
	var frame_holder := CenterContainer.new()
	frame_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(frame_holder)

	_frame = Control.new()
	_frame.clip_contents = true
	frame_holder.add_child(_frame)

	var lower := VBoxContainer.new()
	lower.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_theme_constant_override("separation", 28)
	lower.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_child(lower)

	var text_holder := CenterContainer.new()
	text_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(text_holder)

	_plain_text = Label.new()
	_plain_text.custom_minimum_size.x = 800
	_plain_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_plain_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plain_text.add_theme_font_override("font", UITheme.font("pixel"))
	_plain_text.add_theme_color_override("font_color", PLAIN_TEXT)
	text_holder.add_child(_plain_text)

	var choices_holder := CenterContainer.new()
	choices_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(choices_holder)

	_plain_choices = VBoxContainer.new()
	_plain_choices.custom_minimum_size.x = 560
	_plain_choices.add_theme_constant_override("separation", 12)
	choices_holder.add_child(_plain_choices)

	var footer_holder := CenterContainer.new()
	footer_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(footer_holder)

	_plain_footer = VBoxContainer.new()
	_plain_footer.add_theme_constant_override("separation", 8)
	_plain_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_holder.add_child(_plain_footer)

	_plain_next = Button.new()
	_style_next(_plain_next)
	_plain_next.pressed.connect(_advance)
	_plain_footer.add_child(_plain_next)

	_plain_skip = Button.new()
	_style_skip(_plain_skip)
	_plain_skip.pressed.connect(_finish)
	_plain_footer.add_child(_plain_skip)


## Sizes the fixed frame against the current window, matching the CSS box:
## width min(640, 92vw), aspect 260:220, capped at 64vh, offset 6vh from the top.
func _layout_frame() -> void:
	var w: float = minf(FRAME_MAX_WIDTH, size.x * FRAME_WIDTH_RATIO)
	var h: float = w / FRAME_ASPECT
	var max_h: float = size.y * FRAME_MAX_HEIGHT_RATIO
	if h > max_h:
		h = max_h
		w = h * FRAME_ASPECT
	_frame.custom_minimum_size = Vector2(w, h)
	_frame.size = Vector2(w, h)
	_layout_arranged()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _frame != null:
		_layout_frame()


func _clear_frame() -> void:
	for child in _frame.get_children():
		child.queue_free()
	_arranged_rects = []


func _plain_image(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _fill_frame(beat: Dictionary) -> void:
	_clear_frame()

	if beat.has("imgs"):
		var paths: Array = beat["imgs"]
		if bool(beat.get("arranged", false)):
			# Absolutely placed collage; positions computed in _layout_arranged.
			for path in paths:
				var rect := _plain_image(str(path))
				rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				_frame.add_child(rect)
				_arranged_rects.append(rect)
			_layout_arranged()
		else:
			var column := VBoxContainer.new()
			column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			column.add_theme_constant_override("separation", 12)
			_frame.add_child(column)
			for path in paths:
				var rect := _plain_image(str(path))
				rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
				column.add_child(rect)
		return

	if beat.has("img"):
		var rect := _plain_image(str(beat["img"]))
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Single images fill the frame; `no_crop` letterboxes instead.
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED \
			if bool(beat.get("no_crop", false)) else TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_frame.add_child(rect)

		if beat.has("flicker_img"):
			var overlay := _plain_image(str(beat["flicker_img"]))
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			overlay.modulate.a = 0.0
			_frame.add_child(overlay)
			_start_flicker(overlay)
	# No image: the frame stays empty and invisible against the black backdrop.


## Reproduces the stepped CSS flicker: hard cuts, no interpolation, looping.
func _start_flicker(node: CanvasItem) -> void:
	var tween := create_tween()
	tween.set_loops()
	var previous := 0.0
	for step in FLICKER_STEPS:
		var at: float = step[0]
		var alpha: float = step[1]
		if at > previous:
			tween.tween_interval(at - previous)
			previous = at
		tween.tween_callback(func():
			if is_instance_valid(node):
				node.modulate.a = alpha)
	tween.tween_interval(maxf(0.0, FLICKER_PERIOD - previous))


func _layout_arranged() -> void:
	if _arranged_rects.is_empty():
		return
	var w := _frame.size.x
	var h := _frame.size.y
	for i in mini(_arranged_rects.size(), ARRANGED.size()):
		var spec: Dictionary = ARRANGED[i]
		var rect: Control = _arranged_rects[i]
		var rw: float = w * float(spec["w"])
		var rh: float = h * float(spec["h"])
		var x := 0.0
		var y := 0.0
		if spec.has("cx"):
			x = w * float(spec["cx"]) - rw * 0.5
		elif spec.has("left"):
			x = w * float(spec["left"])
		elif spec.has("right"):
			x = w - w * float(spec["right"]) - rw
		if spec.has("top"):
			y = h * float(spec["top"])
		elif spec.has("cy"):
			y = h * float(spec["cy"]) - rh * 0.5
		rect.position = Vector2(x, y)
		rect.size = Vector2(rw, rh)


# ══════════════════════════════════════════════════════════════════════════════
#  Call mode — the Windows-95 transmission window
# ══════════════════════════════════════════════════════════════════════════════

func _build_call() -> void:
	_call = Control.new()
	_call.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_call)

	var backdrop := ColorRect.new()
	backdrop.color = UITheme.BG_DEEP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_call.add_child(backdrop)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_call.add_child(centre)

	var window := PanelContainer.new()
	window.custom_minimum_size = Vector2(900, 640)
	window.add_theme_stylebox_override("panel", UITheme.bevel_raised())
	centre.add_child(window)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	window.add_child(stack)

	stack.add_child(_build_titlebar())

	# The call area is a sunken black inset, like a CRT set into the chassis.
	var area := PanelContainer.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var area_style := StyleBoxFlat.new()
	area_style.bg_color = Color.BLACK
	area_style.border_width_left = 2
	area_style.border_width_top = 2
	area_style.border_width_right = 2
	area_style.border_width_bottom = 2
	area_style.border_color = UITheme.W95_DARKER
	area_style.content_margin_left = 6
	area_style.content_margin_right = 6
	area_style.content_margin_top = 6
	area_style.content_margin_bottom = 6
	area.add_theme_stylebox_override("panel", area_style)
	stack.add_child(area)

	var area_stack := VBoxContainer.new()
	area_stack.add_theme_constant_override("separation", 8)
	area.add_child(area_stack)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	area_stack.add_child(body)

	# Portrait column: 42% of the window, image cropped to fill.
	var portrait_col := Control.new()
	portrait_col.custom_minimum_size.x = 360
	portrait_col.clip_contents = true
	body.add_child(portrait_col)

	_portrait = TextureRect.new()
	_portrait.texture = load(AssetPaths.PATRONS["johndee"])
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_col.add_child(_portrait)

	var label := Label.new()
	label.text = "JOHN DEE"
	label.position = Vector2(8, 8)
	label.add_theme_font_override("font", UITheme.font("pixel"))
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", PORTRAIT_LABEL)
	var label_bg := StyleBoxFlat.new()
	label_bg.bg_color = Color(0, 0, 0, 0.75)
	label_bg.content_margin_left = 8
	label_bg.content_margin_right = 8
	label_bg.content_margin_top = 2
	label_bg.content_margin_bottom = 2
	label.add_theme_stylebox_override("normal", label_bg)
	portrait_col.add_child(label)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 18)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_child(_content)
	body.add_child(margin)

	_call_footer = HBoxContainer.new()
	_call_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_call_footer.add_theme_constant_override("separation", 12)
	area_stack.add_child(_call_footer)

	_call_next = Button.new()
	_style_next(_call_next)
	_call_next.pressed.connect(_advance)
	_call_footer.add_child(_call_next)

	var skip := Button.new()
	_style_skip(skip)
	skip.pressed.connect(_finish)
	_call_footer.add_child(skip)


func _build_titlebar() -> Control:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.W95_TITLE
	style.content_margin_left = 6
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	bar.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)

	var title := Label.new()
	title.text = "📞  Incoming Transmission -- John Dee"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", UITheme.font("pixel"))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UITheme.W95_WHITE)
	row.add_child(title)

	# Decorative window buttons, exactly as the web build draws them.
	for glyph in ["_", "□", "✕"]:
		var button := Label.new()
		button.text = glyph
		button.custom_minimum_size = Vector2(20, 18)
		button.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_font_override("font", UITheme.font("pixel"))
		button.add_theme_color_override("font_color", UITheme.W95_DARKER)
		button.add_theme_stylebox_override("normal", UITheme.bevel_raised())
		row.add_child(button)

	return bar


## A beat's `text` is usually a String, but a few of the web build's "you"
## beats carry it as a single-element array (e.g. the "Queen's official punster"
## line). Join those so they never render as a bracketed array literal.
func _beat_text(beat: Dictionary) -> String:
	var t = beat.get("text", "")
	if t is Array:
		return " ".join(PackedStringArray(t.map(func(x): return str(x))))
	return str(t)


## Narration sits in a sunken grey box; Dee speaks from a bordered white bubble;
## the player is plain white text.
func _call_content(beat: Dictionary) -> void:
	for child in _content.get_children():
		child.queue_free()

	var speaker := String(beat.get("speaker", "scene"))
	var text := _beat_text(beat)
	var narration := bool(beat.get("scene", false)) or speaker == "scene"
	var choices: Array = beat.get("choices", [])

	if not choices.is_empty():
		for line in choices:
			var button := _choice_button(str(line))
			button.pressed.connect(_advance)
			_content.add_child(button)
		return

	if narration:
		var box := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = UITheme.W95_BG
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = UITheme.W95_DARKER
		style.content_margin_left = 24
		style.content_margin_right = 24
		style.content_margin_top = 20
		style.content_margin_bottom = 20
		box.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font", UITheme.font("pixel"))
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", UITheme.W95_DARKER)
		box.add_child(label)
		_content.add_child(box)
		return

	if speaker == "dee":
		_content.add_child(_speech_bubble(text, "left"))
		return

	# The player also speaks from a comic bubble, its tail pointing down toward
	# the viewer, so it is clear these are the player's own words.
	_content.add_child(_speech_bubble(text, "down"))


## White box, heavy black border, hard offset shadow and a pointy tail. The tail
## direction ("left" for Dee, "down" for the player) is reserved as a margin so
## the triangle has room, and BubbleTail paints it in _draw (a Panel child of a
## Container would be stretched to fill and cover the text).
func _speech_bubble(text: String, tail_dir := "left") -> Control:
	var tail := BubbleTail.new()
	tail.dir = tail_dir
	if tail_dir == "down":
		tail.add_theme_constant_override("margin_bottom", BubbleTail.REACH)
	else:
		tail.add_theme_constant_override("margin_left", BubbleTail.REACH)

	var bubble := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color.BLACK
	style.shadow_color = Color.BLACK
	style.shadow_size = 5
	style.shadow_offset = Vector2(5, 5)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	bubble.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UITheme.font("pixel"))
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.BLACK)
	bubble.add_child(label)
	tail.add_child(bubble)

	return tail


# ══════════════════════════════════════════════════════════════════════════════
#  Shared controls — clearly clickable choice buttons and the skip control
# ══════════════════════════════════════════════════════════════════════════════

## Every choice, topic and victory option is one of these: a raised Windows-95
## button with a big readable label. The web build left the intro's "plain" mode
## choices as near-invisible outlined text; here every choice reads as a real,
## pressable button so nothing looks like inert text.
func _choice_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", UITheme.CARD_BLACK)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	button.add_theme_stylebox_override("normal", UITheme.bevel_raised(UITheme.W95_BG, Vector2(20, 14)))
	button.add_theme_stylebox_override("hover", UITheme.bevel_raised(UITheme.W95_HOVER, Vector2(20, 14)))
	button.add_theme_stylebox_override("pressed", UITheme.bevel_sunken(UITheme.W95_HOVER, Vector2(20, 14)))
	button.add_theme_stylebox_override("focus", UITheme.bevel_raised(UITheme.W95_BG, Vector2(20, 14)))
	return button


## The gold "Skip" control, matching .patron-choice-btn-skip: gold text on a dark
## panel with a gold border. Full opacity and large enough to read at a glance —
## secondary to the choices, but never a dim afterthought.
func _style_skip(button: Button) -> void:
	button.text = "Skip ▸▸"
	button.flat = false
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", UITheme.GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _skip_box(UITheme.W95_TITLEBAR2))
	button.add_theme_stylebox_override("hover", _skip_box(Color("3a2814")))
	button.add_theme_stylebox_override("pressed", _skip_box(Color("3a2814")))
	button.add_theme_stylebox_override("focus", _skip_box(UITheme.W95_TITLEBAR2))


## The primary "Continue ▸" / "Begin" advance button — a raised gold-bordered
## panel, larger than Skip so the way forward is obvious.
func _style_next(button: Button) -> void:
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", UITheme.GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _next_box(UITheme.W95_TITLEBAR2, UITheme.GOLD_DIM))
	button.add_theme_stylebox_override("hover", _next_box(Color("3a2814"), UITheme.GOLD))
	button.add_theme_stylebox_override("pressed", _next_box(Color("241a0c"), UITheme.GOLD))
	button.add_theme_stylebox_override("focus", _next_box(UITheme.W95_TITLEBAR2, UITheme.GOLD_DIM))


func _next_box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.set_corner_radius_all(3)
	s.content_margin_left = 26
	s.content_margin_right = 26
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func _skip_box(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = UITheme.GOLD_DIM
	s.set_corner_radius_all(3)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s


# ══════════════════════════════════════════════════════════════════════════════
#  Render
# ══════════════════════════════════════════════════════════════════════════════

func _render() -> void:
	_layout_frame()

	if _index >= _beats.size():
		if RunState.screen == "victory-dialogue" and _victory_choice < 0:
			_show_victory_choices()
			return
		if not _topics.is_empty() and _active_topic.is_empty():
			_show_topic_menu()
			return
		_finish()
		return

	var beat: Dictionary = _beats[_index]
	var plain := not _face_seen()
	_plain.visible = plain
	_call.visible = not plain

	if plain:
		_render_plain(beat)
	else:
		_render_call(beat)


func _render_plain(beat: Dictionary) -> void:
	_fill_frame(beat)

	var choices: Array = beat.get("choices", [])
	for child in _plain_choices.get_children():
		child.queue_free()

	if choices.is_empty():
		_plain_text.visible = true
		_plain_text.text = _beat_text(beat)
		_plain_text.add_theme_font_size_override("font_size", 30)
		_plain_choices.visible = false
		_plain_next.visible = true
		_plain_next.text = str(beat.get("next_label", "Continue ▸"))
	else:
		# A choosing beat drops the line and the Continue button; only Skip stays.
		_plain_text.visible = false
		_plain_choices.visible = true
		_plain_next.visible = false
		for line in choices:
			var button := _choice_button(str(line))
			button.pressed.connect(_advance)
			_plain_choices.add_child(button)


func _render_call(beat: Dictionary) -> void:
	_call_content(beat)
	var choosing := not (beat.get("choices", []) as Array).is_empty()
	_call_footer.visible = not choosing
	var last := _index == _beats.size() - 1
	_call_next.text = "Begin" if (last and _is_intro) else "Continue ▸"


func _show_topic_menu() -> void:
	_plain.visible = false
	_call.visible = true
	for child in _content.get_children():
		child.queue_free()

	var prompt := Label.new()
	prompt.text = "What would you like to ask?"
	prompt.add_theme_font_override("font", UITheme.font("pixel"))
	prompt.add_theme_font_size_override("font_size", 26)
	prompt.add_theme_color_override("font_color", Color.WHITE)
	_content.add_child(prompt)

	for topic in _topics:
		var seen := SaveManager.has_seen(_seen_key, String(topic["id"]))
		var button := _choice_button(("✓ " if seen else "") + String(topic["question"]))
		button.pressed.connect(_open_topic.bind(topic))
		_content.add_child(button)

	var done := _choice_button("That's all for now.")
	done.pressed.connect(_finish)
	_content.add_child(done)
	_call_footer.visible = false


func _open_topic(topic: Dictionary) -> void:
	SaveManager.mark_seen(_seen_key, String(topic["id"]))
	_active_topic = topic
	_beats = topic["beats"]
	_index = 0
	_call_footer.visible = true
	_render()


func _show_victory_choices() -> void:
	_plain.visible = false
	_call.visible = true
	for child in _content.get_children():
		child.queue_free()
	for i in Narrative.VICTORY_CHOICES.size():
		var button := _choice_button(String(Narrative.VICTORY_CHOICES[i]))
		button.pressed.connect(_choose_victory.bind(i))
		_content.add_child(button)
	_call_footer.visible = false


func _choose_victory(index: int) -> void:
	_victory_choice = index
	_beats = [{"speaker": "dee", "text": String(Narrative.VICTORY_RESPONSES[index])}]
	_index = 0
	_call_footer.visible = true
	_render()


func _advance() -> void:
	if _index >= _beats.size() - 1 and _topics.is_empty() and _active_topic.is_empty():
		_finish()
		return
	_index += 1
	# Finishing a topic returns to the menu rather than ending the conversation.
	if _index >= _beats.size() and not _active_topic.is_empty():
		_active_topic = {}
		_beats = []
		_index = 0
	_render()


func _finish() -> void:
	match RunState.screen:
		"patron-dialogue":
			# Replaying from the map returns there; the first viewing starts the run
			# and stops at the Time Patron picker before the map, as the web build does.
			if RunState.intro_replay:
				RunState.intro_replay = false
				RunState.set_screen("map")
			else:
				RunState.new_run()
				RunState.set_screen("patron-select")
		"dee-checkin-dialogue", "dee-dialogue3", "dee-final-dialogue":
			SaveManager.mark_dirty()
			RunState.proceed_to_shop()
		"victory-dialogue":
			RunState.set_screen("victory")
		_:
			RunState.set_screen("map")
