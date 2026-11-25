extends Control

## Time Patron picker, shown once at the start of a run (after the intro, before
## the map), ported from renderPatronSelect in index.html.
##
## Each patron shapes the whole descent — above all the shop they stock — so the
## card states only what the player needs to choose: portrait, name, occupation,
## and a one-line flavour that hints at the playstyle. Unlocked patrons are
## pickable; in-development ones show their name and a tag; unrevealed ones stay
## a padlocked "???".

const CARD_W := 260.0
const PORTRAIT := 176.0

@onready var _grid: HBoxContainer = $Layout/Grid
@onready var _title: Label = $Layout/Title
@onready var _subtitle: Label = $Layout/Subtitle
@onready var _confirm: Label = $Layout/Confirm


func _ready() -> void:
	_title.text = Locale.t("Choose Your Time Patron")
	_title.add_theme_font_override("font", UITheme.font_at("display", 700))
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", UITheme.GOLD)

	_subtitle.text = Locale.t("An ally for this descent, lending their nature to the wares you can purchase along the way.")
	_subtitle.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Name the choice only while Dee is the sole patron on offer.
	var playable := 0
	for patron in Narrative.PATRONS:
		if _is_playable(patron):
			playable += 1
	_confirm.text = Locale.t("Select John Dee to begin your descent.") if playable <= 1 \
		else Locale.t("Select a Time Patron to begin your descent.")
	_confirm.add_theme_font_override("font", UITheme.font("pixel"))
	_confirm.add_theme_font_size_override("font_size", 14)
	_confirm.add_theme_color_override("font_color", UITheme.TEXT_DIM)

	for patron in Narrative.PATRONS:
		_grid.add_child(_build_card(patron))


## Patron art comes in different shapes: Dee's is a square bust, Mary's a tall
## 2:3 painting with a grey strip along its top. Cropping both to a square
## taken near the top of the image gives every card the same head-and-shoulders
## framing; a plain centred cover crop cut through Mary's headdress instead.
const PORTRAIT_TOP := 0.06
## The share of a tall image's width the square keeps, so a full-figure
## painting is brought in to roughly the head size of Dee's close bust.
const PORTRAIT_ZOOM := 0.86


static func square_portrait(texture: Texture2D) -> Texture2D:
	if texture == null:
		return texture
	var w := float(texture.get_width())
	var h := float(texture.get_height())
	if h <= w:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	var side := w * PORTRAIT_ZOOM
	var top := minf(h * PORTRAIT_TOP, h - side)
	atlas.region = Rect2((w - side) * 0.5, top, side, side)
	return atlas


## A patron is revealed either in its data (Dee) or by the player's progress:
## Mary's identity is uncovered with John Dee's thread in the compendium. The
## static flag alone left her a padlocked "???" here forever, whatever the save
## said — the compendium asked SaveManager, this screen never did.
func _is_revealed(patron: Dictionary) -> bool:
	return bool(patron.get("revealed", false)) \
		or SaveManager.is_patron_revealed(String(patron["id"]))


func _is_playable(patron: Dictionary) -> bool:
	return bool(patron.get("unlocked", false)) and _is_revealed(patron)


func _build_card(patron: Dictionary) -> Control:
	var unlocked := bool(patron.get("unlocked", false))
	var revealed := _is_revealed(patron)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.occult_panel())
	panel.custom_minimum_size = Vector2(CARD_W, 0)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	# Top-aligned, so every portrait sits at the same height whatever the length
	# of the text beneath it. Centred, a longer tagline pushed Mary's portrait
	# above Dee's.
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)

	# Portrait (or a padlock for a patron not yet revealed).
	var art := Control.new()
	art.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.clip_contents = true
	# A bare Control stops the mouse by default, which made the portrait — the
	# first thing a player clicks — the one part of the card that ignored them.
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(art)
	if revealed:
		var tex := TextureRect.new()
		tex.texture = square_portrait(load(String(patron["img"])))
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(tex)
	else:
		var bg := ColorRect.new()
		bg.color = UITheme.BG_DEEP
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(bg)
		var lock := Label.new()
		lock.text = "🔒"
		lock.add_theme_font_size_override("font_size", 52)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(lock)

	# Name.
	var name_lbl := Label.new()
	name_lbl.text = _patron_name(patron) if revealed else "???"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", UITheme.font_at("display", 600))
	name_lbl.add_theme_font_size_override("font_size", 21)
	name_lbl.add_theme_color_override("font_color", UITheme.GOLD if unlocked else UITheme.TEXT)
	col.add_child(name_lbl)

	if not revealed:
		return panel  # unrevealed patrons show only the padlocked "???"

	# Occupation.
	var occ := String(patron.get("occupation", ""))
	if occ != "":
		var occ_lbl := Label.new()
		occ_lbl.text = Locale.t(occ)
		occ_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		occ_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		occ_lbl.custom_minimum_size = Vector2(CARD_W - 28, 0)
		occ_lbl.add_theme_font_override("font", UITheme.font("pixel"))
		occ_lbl.add_theme_font_size_override("font_size", 13)
		occ_lbl.add_theme_color_override("font_color", Color("a98b4f"))  # readable muted gold
		col.add_child(occ_lbl)

	# Strategy flavour.
	var tagline := String(patron.get("tagline", ""))
	if tagline != "":
		var flavour := Label.new()
		flavour.text = Locale.t(tagline)
		flavour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		flavour.custom_minimum_size = Vector2(CARD_W - 28, 0)
		flavour.add_theme_font_override("font", UITheme.font("body"))
		flavour.add_theme_font_size_override("font_size", 16)
		flavour.add_theme_color_override("font_color", UITheme.TEXT)
		col.add_child(flavour)

	if unlocked:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event): _on_card_input(event, String(patron["id"])))
	else:
		# Revealed but not yet playable.
		var tag := Label.new()
		tag.text = Locale.t("In development")
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_override("font", UITheme.font("pixel"))
		tag.add_theme_font_size_override("font_size", 12)
		tag.add_theme_color_override("font_color", UITheme.GOLD)
		col.add_child(tag)

	return panel


## Patrons keep their alias until revealed in the compendium.
func _patron_name(patron: Dictionary) -> String:
	if _is_revealed(patron) and patron.has("true_name") \
			and SaveManager.is_patron_revealed(String(patron["id"])):
		return String(patron["true_name"])
	return Locale.t(String(patron["name"]))


func _on_card_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_choose(id)


func _choose(id: String) -> void:
	RunState.patron = id
	AudioManager.card_taken()
	# Dee has already spoken by now — his first contact is the intro that leads
	# here. Mary has not, so choosing her opens her line before the tower.
	RunState.set_screen("marie-greeting" if id == "marie" else "map")
