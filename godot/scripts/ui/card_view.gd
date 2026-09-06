extends Control

## A single playing card, drawn rather than blitted.
##
## The web build has no card face art at all — every face is a white rounded
## rectangle with a Unicode suit glyph and a rank, built from CSS. This node is
## the direct equivalent: faces are drawn with _draw(), backs use the selected
## card back texture. That keeps faces sharp at any resolution and means the
## whole 52-card set costs one texture (the back) instead of a sprite sheet.

signal card_pressed(view: Control)

const CORNER_RADIUS := 4.0
## 2px so an overlapping (fanned) card always shows a crisp separating edge —
## a 1px line was lost to anti-aliasing when the canvas is scaled, so the first
## of three fanned waste cards had no visible divider from the second.
const BORDER_WIDTH := 2.0

## Card face metrics as fractions of card width, from the CSS --cfs/--cfss/--cfc
## on a 116px card: rank 32, corner suit 18, centre pip 84.
const PAD_RATIO := 0.045
const RANK_RATIO := 0.276
const CORNER_SUIT_RATIO := 0.155
const CENTRE_PIP_RATIO := 0.72

var card: Dictionary = {}
var face_up := false
var selected := false:
	set(value):
		selected = value
		queue_redraw()
var hinted := false:
	set(value):
		if hinted == value:
			return
		hinted = value
		set_process(hinted)  # only a hinted card needs to animate its glow
		_hint_phase = 0.0
		queue_redraw()
var playable := true

## Advances while the card is hinted so the Scrying Glass glow pulses.
var _hint_phase := 0.0

var _back_texture: Texture2D
var _face_texture: Texture2D
var _rank_font: Font
var _pip_font: Font


func _ready() -> void:
	set_process(false)  # idle unless the card is hinted (see the `hinted` setter)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The web card face is Georgia serif for both the index and the pip; EB
	# Garamond is the bundled serif and carries the suit glyphs.
	_rank_font = UITheme.font_at("body", 700)
	_pip_font = UITheme.font("body")
	_refresh_back()


func setup(card_data: Dictionary) -> void:
	card = card_data
	face_up = bool(card_data.get("face_up", false))
	_face_texture = null
	if not card.is_empty():
		var path := AssetPaths.card_face(int(card.get("suit", 0)), int(card.get("rank", 1)))
		if ResourceLoader.exists(path):
			_face_texture = load(path) as Texture2D
	queue_redraw()


func _refresh_back() -> void:
	var id := String(SaveManager.profile.get("cardback", "classic"))
	var path: String = AssetPaths.CARDBACKS.get(id, AssetPaths.CARDBACKS[AssetPaths.DEFAULT_CARDBACK])
	_back_texture = load(path) as Texture2D


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			card_pressed.emit(self)
			accept_event()


func _process(delta: float) -> void:
	_hint_phase += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)

	if not face_up:
		_draw_back(r)
	else:
		_draw_face(r)

	if hinted:
		_draw_hint_glow(r)
	if selected:
		draw_rect(r, UITheme.GOLD, false, 3.0)

	if not playable:
		draw_rect(r, Color(0, 0, 0, 0.35), true)


## The Scrying Glass highlight: a bright yellow→orange outline that pulses in
## width and brightness, plus a soft outer halo, so it reads at a glance the way
## the web build's animated `.hint-glow` does. Drawn under the selection ring so
## picking the card still shows the gold select border on top.
func _draw_hint_glow(r: Rect2) -> void:
	var pulse := 0.5 + 0.5 * sin(_hint_phase * 6.0)  # 0..1, ~1Hz-ish throb
	var colour := Color("ffff00").lerp(Color("ff8800"), pulse)
	# Outer halo: a few translucent expanding outlines fake a glow/bloom.
	for i in 3:
		var spread := 2.0 + i * 3.0
		draw_rect(r.grow(spread), Color(colour.r, colour.g, colour.b, 0.16 - i * 0.045),
			false, 3.0)
	# Bright core outline, thickest at the peak of the pulse.
	draw_rect(r.grow(-1.0), colour, false, 3.0 + pulse * 2.0)


## A rounded border matching the painted face's corners, so overlapping cards in
## a fan or tableau still show a clear separating edge.
func _draw_face_border(r: Rect2) -> void:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(int(BORDER_WIDTH))
	sb.border_color = UITheme.CARD_BORDER
	var radius := int(maxf(2.0, r.size.x * 0.05))
	sb.set_corner_radius_all(radius)
	draw_style_box(sb, r)


func _draw_back(r: Rect2) -> void:
	if _back_texture != null:
		draw_texture_rect(_back_texture, r, false)
	else:
		draw_rect(r, UITheme.BG_PANEL, true)
	draw_rect(r, UITheme.CARD_BORDER, false, BORDER_WIDTH)


func _draw_face(r: Rect2) -> void:
	# Painted face art (parchment body with transparent rounded corners) when it
	# exists; a thin rounded border over it keeps overlapping fanned cards apart.
	if _face_texture != null:
		draw_texture_rect(_face_texture, r, false)
		_draw_face_border(r)
		return

	# Fallback: the procedural face, drawn only if the PNG is missing.
	draw_rect(r, UITheme.CARD_FACE, true)
	draw_rect(r, UITheme.CARD_BORDER, false, BORDER_WIDTH)

	if card.is_empty():
		return

	var suit := int(card.get("suit", 0))
	var rank := int(card.get("rank", 1))
	var colour := UITheme.CARD_RED if Cards.is_red(suit) else UITheme.CARD_BLACK
	var pad := size.x * PAD_RATIO
	var rank_size := maxi(10, int(size.x * RANK_RATIO))
	var pip_size := maxi(8, int(size.x * CORNER_SUIT_RATIO))
	var centre_size := maxi(16, int(size.x * CENTRE_PIP_RATIO))

	var rank_text: String = Cards.RANK_NAMES[rank]
	var pip_text: String = Cards.SUIT_SYMBOLS[suit]

	# Top-left index only — the web card has no bottom-right mirror (.cb is hidden).
	draw_string(_rank_font, Vector2(pad, pad + rank_size * 0.82), rank_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, rank_size, colour)
	draw_string(_pip_font, Vector2(pad, pad + rank_size * 0.82 + pip_size * 0.95),
		pip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, pip_size, Color(colour, 0.85))

	# The large centre pip sits at 58% of the height, as in the CSS.
	var centre := _pip_font.get_string_size(pip_text, HORIZONTAL_ALIGNMENT_CENTER, -1, centre_size)
	draw_string(_pip_font,
		Vector2((size.x - centre.x) * 0.5, size.y * 0.58 + centre.y * 0.35),
		pip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, centre_size, colour)
