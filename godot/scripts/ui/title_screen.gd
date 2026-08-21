extends Control

## Title screen. Three choices, matching the requested menu:
##   Load Game   — pick one of the four save slots to resume
##   New Game    — pick a slot, name the player, and begin
##   High Scores — the local leaderboard
##
## The web build gated saving behind a cloud account; here it is four local save
## slots, so it works offline and for every player.

@onready var _load_button: Button = $Center/Buttons/Load
@onready var _new_button: Button = $Center/Buttons/New
@onready var _scores_button: Button = $Center/Buttons/Scores
@onready var _exit_button: Button = $Center/Buttons/Exit
@onready var _keyart: TextureRect = $Keyart


func _ready() -> void:
	_keyart.texture = load(AssetPaths.UI["title_keyart"])

	# The key art carries the title itself; the menu sits below it, clear of the
	# painted lettering.

	# Load Game is only meaningful once at least one slot holds a save.
	_load_button.disabled = not SaveManager.any_slot_exists()
	_load_button.pressed.connect(_on_load)
	_new_button.pressed.connect(_on_new)
	_scores_button.pressed.connect(_on_scores)
	_exit_button.pressed.connect(_on_exit)
	_exit_button.add_theme_color_override("font_color", UITheme.MAROON)


func _on_load() -> void:
	RunState.slot_mode = "load"
	RunState.set_screen("slots")


func _on_new() -> void:
	RunState.slot_mode = "new"
	RunState.set_screen("slots")


func _on_scores() -> void:
	RunState.set_screen("highscores")


## Closes the game completely, back to Steam / the desktop.
func _on_exit() -> void:
	SaveManager.save_game()
	get_tree().quit()
