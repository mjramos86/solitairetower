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
	# painted lettering. The art is close to square, so it is scaled to cover the
	# screen width and pinned to the TOP — the full "THE SOLITAIRE TOWER OF DOOM"
	# lettering stays visible and only the bottom edge is cropped, behind the menu.
	_keyart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_keyart.stretch_mode = TextureRect.STRETCH_SCALE
	_frame_keyart()
	get_viewport().size_changed.connect(_frame_keyart)

	# Load Game is only meaningful once at least one slot holds a save.
	_load_button.disabled = not SaveManager.any_slot_exists()
	_load_button.pressed.connect(_on_load)
	_new_button.pressed.connect(_on_new)
	_scores_button.pressed.connect(_on_scores)
	_exit_button.pressed.connect(_on_exit)

	# Bigger, clearly readable menu buttons — the key art leaves plenty of room.
	for button in [_load_button, _new_button, _scores_button, _exit_button]:
		button.custom_minimum_size = Vector2(220, 56)
		button.add_theme_font_override("font", UITheme.font("pixel"))
		button.add_theme_font_size_override("font_size", 26)
	_exit_button.add_theme_color_override("font_color", UITheme.MAROON)


## Scales the key art to cover the screen width and anchors it to the top, so
## the title lettering is never cropped. Recomputed whenever the window resizes.
func _frame_keyart() -> void:
	var tex := _keyart.texture
	if tex == null:
		return
	var view := get_viewport_rect().size
	var tex_size := Vector2(tex.get_width(), tex.get_height())
	# Cover scale: fill both axes, cropping the overflow rather than letterboxing.
	var scale := maxf(view.x / tex_size.x, view.y / tex_size.y)
	var draw_size := tex_size * scale
	_keyart.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_keyart.size = draw_size
	# Centre horizontally; pin to the top so the title stays on screen.
	_keyart.position = Vector2((view.x - draw_size.x) * 0.5, 0.0)


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
