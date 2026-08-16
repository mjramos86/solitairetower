extends Control

## A single playing card, drawn rather than blitted.
##
## The web build has no card face art at all — every face is a white rounded
## rectangle with a Unicode suit glyph and a rank, built from CSS. This node is
## the direct equivalent: faces are drawn with _draw(), backs use the selected
## card back texture. That keeps faces sharp at any resolution and means the
## whole 52-card set costs one texture (the back) instead of a sprite sheet.

signal card_pressed(view: Control)

const CORNER_RADIUS := 5.0
const BORDER_WIDTH := 1.5

## Rank/pip inset as a fraction of card width.
const PAD_RATIO := 0.09

var card: Dictionary = {}
var face_up := false
var selected := false:
	set(value):
		selected = value
		queue_redraw()
var hinted := false:
	set(value):
		hinted = value
		queue_redraw()
var playable := true

var _back_texture: Texture2D
var _rank_font: Font
var _pip_font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rank_font = UITheme.font("pixel")
	_pip_font = UITheme.font("body")
	_refresh_back()


func setup(card_data: Dictionary) -> void:
	card = card_data
	face_up = bool(card_data.get("face_up", false))
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


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)

	if not face_up:
		_draw_back(r)
	else:
		_draw_face(r)

	if selected:
		draw_rect(r, UITheme.GOLD, false, 3.0)
	elif hinted:
		draw_rect(r.grow(-1.0), UITheme.GOLD_GLOW, false, 3.0)

	if not playable:
		draw_rect(r, Color(0, 0, 0, 0.35), true)


func _draw_back(r: Rect2) -> void:
	if _back_texture != null:
		draw_texture_rect(_back_texture, r, false)
	else:
		draw_rect(r, UITheme.BG_PANEL, true)
	draw_rect(r, UITheme.CARD_BORDER, false, BORDER_WIDTH)


func _draw_face(r: Rect2) -> void:
	draw_rect(r, UITheme.CARD_FACE, true)
	draw_rect(r, UITheme.CARD_BORDER, false, BORDER_WIDTH)

	if card.is_empty():
		return

	var suit := int(card.get("suit", 0))
	var rank := int(card.get("rank", 1))
	var colour := UITheme.CARD_RED if Cards.is_red(suit) else UITheme.CARD_BLACK
	var pad := size.x * PAD_RATIO
	var rank_size := maxi(10, int(size.x * 0.30))
	var pip_size := maxi(9, int(size.x * 0.26))
	var centre_size := maxi(14, int(size.x * 0.52))

	var rank_text: String = Cards.RANK_NAMES[rank]
	var pip_text: String = Cards.SUIT_SYMBOLS[suit]

	# Top-left rank over pip, mirrored bottom-right — the standard index layout.
	draw_string(_rank_font, Vector2(pad, pad + rank_size * 0.85), rank_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, rank_size, colour)
	draw_string(_pip_font, Vector2(pad, pad + rank_size * 0.85 + pip_size), pip_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, pip_size, colour)

	var bottom := Vector2(size.x - pad, size.y - pad)
	draw_set_transform(bottom, PI, Vector2.ONE)
	draw_string(_rank_font, Vector2(0, rank_size * 0.85), rank_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, rank_size, colour)
	draw_string(_pip_font, Vector2(0, rank_size * 0.85 + pip_size), pip_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, pip_size, colour)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Large centre pip, so a card is readable when only its top strip shows.
	var centre := _pip_font.get_string_size(pip_text, HORIZONTAL_ALIGNMENT_CENTER, -1, centre_size)
	draw_string(_pip_font,
		Vector2((size.x - centre.x) * 0.5, (size.y + centre.y * 0.6) * 0.5),
		pip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, centre_size,
		Color(colour, 0.85))
