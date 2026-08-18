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

# ── Windows-95 chrome (--w95-*), values exactly as the stylesheet ──
const W95_BG := Color("c0c0c0")
const W95_WHITE := Color("ffffff")
const W95_DARK := Color("808080")
const W95_DARKER := Color("404040")   # --w95-darker:#404040
const W95_HOVER := Color("d4d0c8")    # .btn:hover / .rules-strip background
const W95_TITLE := Color("000080")
## Title-bar gradient endpoints (--w95-titlebar1/2). Godot draws it as a blend.
const W95_TITLEBAR1 := Color("1a1208")
const W95_TITLEBAR2 := Color("2e2010")
const MAROON := Color("800000")       # .btn-d danger buttons

# ── Card table felt (--felt) ──
const FELT := Color("1a0d2e")
const FELT_TINT := Color(0.156, 0.125, 0.04, 0.18)  # radial highlight over the felt

# ── Gold "time credits" pill (.gold-display) ──
const GOLD_PILL_BG := Color("ffff80")
const GOLD_PILL_TEXT := Color("886600")
const ITEM_BANNER_BG := Color("ffff00")
const ITEM_ARMED := Color("ffff80")

# ── Card face, matching the web card exactly ──
const CARD_FACE := Color("e8ddb8")    # .card background
const CARD_BORDER := Color("7a6a44")  # .card border
const CARD_RED := Color("8b1a0a")     # .card.red text
const CARD_BLACK := Color("1a1408")   # .card.blk text
const CARD_BACK_BG := Color("1a0000")

## Card aspect matches the CSS --cw/--ch (116x160) and the card-back art.
const CARD_ASPECT := 116.0 / 160.0


static func font(key: String) -> FontFile:
	return load(AssetPaths.FONTS[key]) as FontFile


## Variable-font instance at a given weight. Cinzel, EB Garamond and Playfair
## all ship as single variable files, so this is how any weight is selected.
static func font_at(key: String, weight: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = font(key)
	v.variation_opentype = {"wght": weight}
	return v


## Raised Windows-95 bevel: light top-left, dark bottom-right. `pad` sets the
## content margin so button text is inset like the CSS padding.
static func bevel_raised(bg: Color = W95_BG, pad := Vector2(12, 4), width := 2.0) -> BevelStyleBox:
	var s := BevelStyleBox.new(bg, width, false)
	s.content_margin_left = pad.x
	s.content_margin_right = pad.x
	s.content_margin_top = pad.y
	s.content_margin_bottom = pad.y
	return s


static func bevel_sunken(bg: Color = W95_BG, pad := Vector2(12, 4), width := 2.0) -> BevelStyleBox:
	var s := BevelStyleBox.new(bg, width, true)
	s.content_margin_left = pad.x
	s.content_margin_right = pad.x
	s.content_margin_top = pad.y
	s.content_margin_bottom = pad.y
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

	# Buttons wear the authentic Windows-95 chrome (VT323, two-tone bevel), like
	# the web build's .btn.
	var pixel := font("pixel")
	t.set_font("font", "Button", pixel)
	t.set_font_size("font_size", "Button", 18)
	t.set_color("font_color", "Button", Color.BLACK)
	t.set_color("font_hover_color", "Button", Color.BLACK)
	t.set_color("font_pressed_color", "Button", Color.BLACK)
	t.set_color("font_disabled_color", "Button", W95_DARK)
	t.set_stylebox("normal", "Button", bevel_raised())
	t.set_stylebox("hover", "Button", bevel_raised(W95_HOVER))
	t.set_stylebox("pressed", "Button", bevel_sunken())
	t.set_stylebox("disabled", "Button", bevel_raised(Color("b0b0b0")))

	t.set_color("font_color", "Label", TEXT)

	var panel := StyleBoxFlat.new()
	panel.bg_color = BG_PANEL
	t.set_stylebox("panel", "Panel", panel)

	return t
