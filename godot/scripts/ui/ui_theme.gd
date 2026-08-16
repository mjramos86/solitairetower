class_name UITheme
extends RefCounted

## Colour palette and font helpers, ported from the CSS custom properties in
## index.html. Built in code rather than as a .tres so the values stay next to
## the names they had in the stylesheet and are diffable.

# ── Occult palette (--gold, --text, backgrounds) ──
const GOLD := Color("d4a84b")
const GOLD_DIM := Color("7a5f28")
const GOLD_GLOW := Color(0.831, 0.659, 0.294, 0.35)
const BG_DEEP := Color("0a0616")
const BG_PANEL := Color("16121e")
const TEXT := Color("e8e0d0")
const TEXT_DIM := Color("9a8fb0")
const DANGER := Color("b91c1c")

# ── Windows-95 chrome (--w95-*) ──
const W95_BG := Color("c0c0c0")
const W95_WHITE := Color("ffffff")
const W95_DARK := Color("808080")
const W95_DARKER := Color("000000")
const W95_TITLE := Color("000080")

# ── Card face ──
const CARD_FACE := Color("fdfbf5")
const CARD_RED := Color("cc0000")
const CARD_BLACK := Color("000000")
const CARD_BORDER := Color("2a2418")

## Card aspect matches the 750x1050 card back art exactly (5:7).
const CARD_ASPECT := 750.0 / 1050.0


static func font(key: String) -> FontFile:
	return load(AssetPaths.FONTS[key]) as FontFile


## Variable-font instance at a given weight. Cinzel, EB Garamond and Playfair
## all ship as single variable files, so this is how any weight is selected.
static func font_at(key: String, weight: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = font(key)
	v.variation_opentype = {"wght": weight}
	return v


## Raised Windows-95 bevel: light top-left, dark bottom-right.
static func bevel_raised(bg: Color = W95_BG) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = W95_WHITE
	# Godot styleboxes take one border colour, so the sunken edge is drawn by
	# expanding the dark side rather than per-edge colours.
	s.shadow_color = W95_DARKER
	s.shadow_size = 0
	s.set_corner_radius_all(0)
	return s


static func bevel_sunken(bg: Color = W95_BG) -> StyleBoxFlat:
	var s := bevel_raised(bg)
	s.border_color = W95_DARK
	return s


## Gold-bordered occult panel, used by the map, compendium and dialogue screens.
static func occult_panel(bg: Color = BG_PANEL) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = GOLD_DIM
	s.set_corner_radius_all(6)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


## Project-wide Theme. Assigned to the root Control so every child inherits it.
static func build() -> Theme:
	var t := Theme.new()

	var body := font("body")
	t.default_font = body
	t.default_font_size = 18

	# Buttons wear the Windows-95 chrome, using the pixel font like the original.
	var pixel := font("pixel")
	t.set_font("font", "Button", pixel)
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Button", W95_DARKER)
	t.set_color("font_hover_color", "Button", W95_TITLE)
	t.set_color("font_pressed_color", "Button", W95_TITLE)
	t.set_color("font_disabled_color", "Button", W95_DARK)
	t.set_stylebox("normal", "Button", bevel_raised())
	t.set_stylebox("hover", "Button", bevel_raised(Color("d4d4d4")))
	t.set_stylebox("pressed", "Button", bevel_sunken())
	t.set_stylebox("disabled", "Button", bevel_raised(Color("b0b0b0")))

	t.set_color("font_color", "Label", TEXT)

	var panel := StyleBoxFlat.new()
	panel.bg_color = BG_PANEL
	t.set_stylebox("panel", "Panel", panel)

	return t
