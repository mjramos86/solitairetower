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
	"title_keyart": "res://assets/ui/title_keyart.png",
	"tower_static": "res://assets/ui/tower_static.jpg",
}

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
const FONTS := {
	"display": "res://fonts/Cinzel-Variable.ttf",           # headings (400/600/700)
	"body": "res://fonts/EBGaramond-Variable.ttf",          # prose (400/500)
	"body_italic": "res://fonts/EBGaramond-Italic-Variable.ttf",
	"title": "res://fonts/PlayfairDisplay-Variable.ttf",    # title screen (700/900)
	"pixel": "res://fonts/VT323-Regular.ttf",               # Win95 chrome, --pixel
	"mono": "res://fonts/ShareTechMono-Regular.ttf",
}

# ── Video ─────────────────────────────────────────────────────────────────────
# Godot's VideoStreamPlayer only accepts Ogg Theora (.ogv). The source .mp4 /
# .MOV masters live in the repo root; run godot/tools/convert_video.sh to
# produce these. Absent until you do — check with ResourceLoader.exists().
const VIDEO := {
	"tower_menu": "res://assets/video/tower_menu_animation.ogv",
	"winning_cinematic": "res://assets/video/winning_cinematic.ogv",
}

## Every asset expected to exist after a clean import, for the verification
## screen. Video is excluded because it requires the manual ffmpeg step.
static func required_assets() -> Array[String]:
	var out: Array[String] = []
	for d in [CARDBACKS, PATRONS, INTRO, UI, SFX, FONTS]:
		for k in d:
			var path: String = d[k]
			out.append(path)
	out.append(MUSIC_INTRO)
	out.append(MUSIC_MAP)
	for p in MUSIC_GAME:
		var path: String = p
		out.append(path)
	return out
