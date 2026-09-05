class_name AssetPaths
extends RefCounted

## Central registry of every art / audio / font asset in the game.
##
## The original web build referenced files by loose string literals scattered
## through index.html. Keeping them in one place here means a renamed or missing
## file is a single edit, and scenes/main.tscn can verify the whole set loads.
##
## Web -> Godot filename mapping lives in godot/ASSET_MAP.md.

# ── Card backs ────────────────────────────────────────────────────────────────
# 750x1050 each. Keys match the `id` values used by the web build's CARDBACKS
# array so save data stays compatible.
const CARDBACKS := {
	"classic": "res://assets/cards/backs/cardback_tower.png",
	"cult": "res://assets/cards/backs/cardback_cult.jpg",
	"dee": "res://assets/cards/backs/cardback_dee.png",
	"marie": "res://assets/cards/backs/cardback_mary.png",
}

const DEFAULT_CARDBACK := "classic"

# ── Patron / compendium portraits ─────────────────────────────────────────────
const PATRONS := {
	"johndee": "res://assets/patrons/john_dee.jpg",
	"marie": "res://assets/patrons/mary_stuart_portrait.png",
	# The web build points this entry at "Cardback_cult2.png", which was deleted
	# from the repo and never replaced, so the compendium renders a broken image.
	# The cult leader card back is the intended stand-in.
	"cult": "res://assets/patrons/cult_of_patience.jpg",
}

# ── Intro cutscene stills ─────────────────────────────────────────────────────
# Ordered as they appear in the intro beat list.
const INTRO := {
	"click_1": "res://assets/intro/intro_click_1.png",
	"click_2": "res://assets/intro/intro_click_2.png",
	"click_3": "res://assets/intro/intro_click_3.png",
	"bounce": "res://assets/intro/intro_bounce.png",
	"face_glimpse": "res://assets/intro/intro_face_glimpse.jpg",
	"eyes_zoom": "res://assets/intro/intro_eyes_zoom.jpg",
	"eyes_pixel": "res://assets/intro/intro_eyes_pixel.png",
	"mouth_pixel": "res://assets/intro/intro_mouth_pixel.png",
	"office_worker_1": "res://assets/intro/intro_office_worker_1.png",
	"office_worker_2": "res://assets/intro/intro_office_worker_2.png",
	"cult": "res://assets/intro/intro_cult.jpg",
}

# ── UI / branding ─────────────────────────────────────────────────────────────
const UI := {
	"logo_sigil": "res://assets/ui/logo_sigil.png",
	"title_keyart": "res://assets/ui/title_keyart.jpg",
	"tower_static": "res://assets/ui/tower_static.jpg",
}

# ── Animated tower (map screen) ───────────────────────────────────────────────
# The frames of "Tower Menu Animation 1400.mp4", decoded ahead of time because
# Godot cannot play MP4. 76 frames at 15 fps reproduce the original 5.07 s loop.
# The individual frames live in assets/tower/frames/ and are referenced by this
# SpriteFrames resource, so this one path is enough to pull in the whole loop.
const TOWER := {
	"animation": "res://assets/tower/tower_animation.tres",
}

const TOWER_SCENE := "res://scenes/tower_menu.tscn"

# ── Music ─────────────────────────────────────────────────────────────────────
const MUSIC_INTRO := "res://audio/music/intro_ambience.mp3"
const MUSIC_MAP := "res://audio/music/map_dark_and_stormy_night.mp3"

## One of these is picked per card game, avoiding an immediate repeat.
const MUSIC_GAME := [
	"res://audio/music/game_horror_creepy.mp3",
	"res://audio/music/game_spooky_piano.mp3",
	"res://audio/music/game_horror_piano.mp3",
]

# ── Sound effects ─────────────────────────────────────────────────────────────
const SFX := {
	"taken": "res://audio/sfx/card_taken.mp3",
	"moved": "res://audio/sfx/card_moved.mp3",
}

# ── Fonts ─────────────────────────────────────────────────────────────────────
# Cinzel / EB Garamond / Playfair Display ship as variable fonts: load the file
# once and wrap it in a FontVariation to select a weight, e.g.
#
#     var f := FontVariation.new()
#     f.base_font = load(AssetPaths.FONTS["display"])
#     f.variation_opentype = { "wght": 700 }
#
# Readability was chosen over the period look: every text role now resolves to
# Inter, a clean humanist sans that stays legible at small sizes and in the
# pixel-font UI chrome. The keys are kept so existing call sites (and their
# weights, via font_at) keep working — hierarchy now comes from weight, not
# from switching families. Inter is variable, so 400/500/600/700/900 all work.
const _INTER := "res://fonts/Inter-Variable.ttf"
const FONTS := {
	"display": _INTER,       # headings (use weights 600/700)
	"body": _INTER,          # prose (400/500)
	"body_italic": _INTER,   # Inter has no separate italic file; falls back to upright
	"title": _INTER,         # big titles (700/900)
	"pixel": _INTER,         # former Win95/VT323 chrome, now clean sans
	"mono": _INTER,          # former ShareTechMono
}

## Every asset expected to exist after a clean import, for the verification
## screen. The project ships no video, so there is nothing conditional here —
## every path below must resolve.
static func required_assets() -> Array[String]:
	var out: Array[String] = []
	for d in [CARDBACKS, PATRONS, INTRO, UI, TOWER, SFX, FONTS]:
		for k in d:
			var path: String = d[k]
			out.append(path)
	out.append(MUSIC_INTRO)
	out.append(MUSIC_MAP)
	for p in MUSIC_GAME:
		var path: String = p
		out.append(path)
	return out
