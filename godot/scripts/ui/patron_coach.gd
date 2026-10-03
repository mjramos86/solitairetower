extends Control

## The run's patron, watching the table from the bottom-right corner, who speaks
## up whenever the board refuses a move and names the rule that refused it.
##
## Why a portrait and not a toast: a refused move used to be a 200ms shake and
## nothing else, so a player who did not already know the rule learned nothing —
## the Spider deal that stops while a column is empty read as a broken button.
## The patron is already the run's framing device (they stock the shop and carry
## the story), so the explanation arrives in a voice the game has established
## rather than as a system message.
##
## Mounted as a sibling of the felt rather than a child of it: _rebuild() frees
## every child of the felt on each move, and the coach has to outlive that.
## A plain Control reports no minimum size of its own, so nothing here can push
## the board's layout around.

const PORTRAIT_W := 168.0
const PORTRAIT_H := 208.0
const BUBBLE_MAX_W := 560.0
const EDGE := 18.0          # gap kept from the felt's bottom-right corner
const FADE := 0.18
## How long a line stays up: a floor, plus reading time per character, capped so
## a long line cannot sit over the table forever.
const DWELL_MIN := 3.2
const DWELL_PER_CHAR := 0.045
const DWELL_MAX := 7.0

var _frame: PanelContainer
var _portrait: TextureRect
var _name_label: Label
var _tail: BubbleTail
var _bubble: PanelContainer
var _label: Label
var _tween: Tween
var _hide_timer: SceneTreeTimer
var _patron := ""
var _row: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	set_patron(RunState.patron)


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_row = row
	# A corner preset bakes the offsets from the size the row has at the moment
	# it is applied, so applying it here (empty, zero-sized) would pin a zero-
	# sized rect to the corner and nothing would ever draw. It is re-applied
	# whenever the content or the felt changes size instead — see _place().
	row.minimum_size_changed.connect(_place)
	resized.connect(_place)

	# ── The bubble, to the left of the portrait, its tail pointing back at it ──
	_tail = BubbleTail.new()
	_tail.dir = "right"
	_tail.offset = 30.0
	_tail.apply_margin()
	_tail.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tail.modulate.a = 0.0
	_tail.visible = false
	row.add_child(_tail)

	_bubble = PanelContainer.new()
	var bubble_box := StyleBoxFlat.new()
	bubble_box.bg_color = Color.WHITE
	bubble_box.border_width_left = 3
	bubble_box.border_width_top = 3
	bubble_box.border_width_right = 3
	bubble_box.border_width_bottom = 3
	bubble_box.border_color = Color.BLACK
	bubble_box.shadow_color = Color(0, 0, 0, 0.55)
	bubble_box.shadow_size = 5
	# The hard comic shadow falls away from the tail, not across it: a shadow
	# offset to the right would be painted over the triangle (the bubble draws
	# after the tail it sits in) and split the tail off the bubble.
	bubble_box.shadow_offset = Vector2(-5, 5)
	bubble_box.content_margin_left = 20
	bubble_box.content_margin_right = 20
	bubble_box.content_margin_top = 16
	bubble_box.content_margin_bottom = 16
	_bubble.add_theme_stylebox_override("panel", bubble_box)
	_bubble.custom_minimum_size.x = BUBBLE_MAX_W
	_tail.add_child(_bubble)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("font", UITheme.font("body"))  # spoken prose → Inter
	_label.add_theme_font_size_override("font_size", 21)
	_label.add_theme_color_override("font_color", Color.BLACK)
	_bubble.add_child(_label)

	# ── The portrait, framed like the rest of the Windows-95 chrome ──
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.size_flags_vertical = Control.SIZE_SHRINK_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	_frame = PanelContainer.new()
	_frame.add_theme_stylebox_override("panel",
		UITheme.bevel_raised(UITheme.W95_BG, Vector2(4, 4)))
	column.add_child(_frame)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(PORTRAIT_W, PORTRAIT_H)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_portrait)

	var strip := PanelContainer.new()
	var strip_box := StyleBoxFlat.new()
	strip_box.bg_color = UITheme.W95_TITLEBAR1
	strip_box.border_width_left = 2
	strip_box.border_width_right = 2
	strip_box.border_width_bottom = 2
	strip_box.border_color = UITheme.W95_DARKER
	strip_box.content_margin_left = 6
	strip_box.content_margin_right = 6
	strip_box.content_margin_top = 3
	strip_box.content_margin_bottom = 3
	strip.add_theme_stylebox_override("panel", strip_box)
	column.add_child(strip)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_override("font", UITheme.font("pixel"))
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.add_theme_color_override("font_color", UITheme.GOLD)
	strip.add_child(_name_label)

	_place.call_deferred()


## Re-pins the portrait (and whatever bubble is open) to the felt's bottom-right
## corner at its current size. Deferred by its callers so the row has already
## recomputed its minimum size when the offsets are taken from it.
func _place() -> void:
	if _row == null:
		return
	_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT,
		Control.PRESET_MODE_MINSIZE, int(EDGE))


## Points the frame at a patron by id. Falls back to the first portrait in the
## compendium, so a patron added to the data without art still shows a face.
func set_patron(id: String) -> void:
	if id == _patron:
		return
	_patron = id
	var entry := {}
	for p in Narrative.PATRONS:
		if String(p.get("id", "")) == id:
			entry = p
			break
	var img := String(entry.get("img", ""))
	if img.is_empty() or not ResourceLoader.exists(img):
		img = String(Narrative.PATRONS[0]["img"])
		if entry.is_empty():
			entry = Narrative.PATRONS[0]
	_portrait.texture = load(img)
	var shown := String(entry.get("name", ""))
	if entry.has("true_name") and SaveManager.is_patron_revealed(String(entry.get("id", ""))):
		shown = String(entry["true_name"])
	_name_label.text = Locale.t(shown).to_upper()


## Says one line, or clears the bubble when the line is empty. Re-saying while a
## line is up replaces it and restarts the dwell, so a player mashing an illegal
## move sees one steady bubble rather than a flicker.
func say(text: String) -> void:
	if text.strip_edges().is_empty():
		hide_line()
		return
	set_patron(RunState.patron)
	_label.text = Locale.t(text)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tail.visible = true
	_place.call_deferred()
	_tail.pivot_offset = Vector2(_tail.size.x, _tail.size.y * 0.5)
	_tween = create_tween().set_parallel()
	_tween.tween_property(_tail, "modulate:a", 1.0, FADE)
	_tween.tween_property(_tail, "scale", Vector2.ONE, FADE) \
		.from(Vector2(0.92, 0.92)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var dwell := clampf(DWELL_MIN + _label.text.length() * DWELL_PER_CHAR, DWELL_MIN, DWELL_MAX)
	_hide_timer = get_tree().create_timer(dwell)
	_hide_timer.timeout.connect(_on_dwell_done.bind(_label.text))


func _on_dwell_done(spoken: String) -> void:
	# Only retire the line that armed this timer; a newer one has its own.
	if _label.text == spoken:
		hide_line()


func hide_line() -> void:
	if not _tail.visible:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_tail, "modulate:a", 0.0, FADE)
	_tween.tween_callback(func():
		_tail.visible = false
		_place.call_deferred())
