extends Control

## Title screen. Three choices, matching the requested menu:
##   Load Game   — pick one of the four save slots to resume
##   New Game    — pick a slot, name the player, and begin
##   High Scores — the local leaderboard
##
## The web build gated saving behind a cloud account; here it is four local save
## slots, so it works offline and for every player.

@onready var _load_button: Button = $Center/Panel/Buttons/Load
@onready var _new_button: Button = $Center/Panel/Buttons/New
@onready var _scores_button: Button = $Center/Panel/Buttons/Scores
@onready var _keyart: TextureRect = $Keyart
@onready var _title: Label = $Center/Panel/Title
@onready var _subtitle: Label = $Center/Panel/Subtitle


func _ready() -> void:
	_keyart.texture = load(AssetPaths.UI["title_keyart"])

	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", UITheme.GOLD)
	_title.text = "The Solitaire Tower of Doom"

	_subtitle.add_theme_font_override("font", UITheme.font_at("display", 600))
	_subtitle.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_subtitle.text = "A roguelike solitaire descent through 10 floors of card chaos."

	# Load Game is only meaningful once at least one slot holds a save.
	_load_button.disabled = not SaveManager.any_slot_exists()
	_load_button.pressed.connect(_on_load)
	_new_button.pressed.connect(_on_new)
	_scores_button.pressed.connect(_on_scores)


func _on_load() -> void:
	RunState.slot_mode = "load"
	RunState.set_screen("slots")


func _on_new() -> void:
	RunState.slot_mode = "new"
	RunState.set_screen("slots")


func _on_scores() -> void:
	RunState.set_screen("highscores")
