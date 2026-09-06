extends Control

## Tower map. The centre is the tower with its floor nodes (tower_map.gd); this
## script fills the left info panel and the right high-score list, matching the
## layout of renderMap in index.html: a descent from floor 10 down to floor 1.
##
## The styling reproduces the web build's occult look: gold-bordered side
## sections with Cinzel small-caps labels, a Playfair title with a soft glow, and
## a gold-framed high-score panel with a header band.

const AudioSettings := preload("res://scripts/ui/audio_settings.gd")

@onready var _title: Label = $Head/Title
@onready var _sub: Label = $Head/Sub
@onready var _tagline: Label = $Head/Tagline
@onready var _side: VBoxContainer = $Body/SidePanel/Side
@onready var _tower = $Body/Tower
@onready var _scores_frame: PanelContainer = $Body/ScoresPad/ScoresFrame
@onready var _scores_title: Label = $Body/ScoresPad/ScoresFrame/ScoresPanel/ScoresTitle
@onready var _scores: VBoxContainer = $Body/ScoresPad/ScoresFrame/ScoresPanel/ScoresScroll/Scores

# --- occult palette bits reused from the web map CSS ---
const SECTION_BG := Color(0.039, 0.024, 0.086, 0.7)   # rgba(10,6,22,.7)
const SCORE_BG := Color(0.039, 0.024, 0.086, 0.85)
const HEART := Color("e74c3c")                         # --life

## The online top scores, refreshed when the leaderboard fetch returns. The
## panel shows local + online merged, so this is folded in with SaveManager's
## local list each time it is rebuilt.
var _online: Array = []


func _ready() -> void:
	# The title carries a soft gold glow, as .map-title does with its text-shadow.
	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 56)
	_title.add_theme_color_override("font_color", UITheme.GOLD)
	_title.add_theme_color_override("font_outline_color", UITheme.GOLD_GLOW)
	_title.add_theme_constant_override("outline_size", 12)

	_sub.add_theme_font_override("font", UITheme.font_at("body", 500))
	_sub.add_theme_font_size_override("font_size", 26)
	_sub.add_theme_color_override("font_color", UITheme.TEXT)

	_tagline.add_theme_font_override("font", UITheme.font_at("display", 500))
	_tagline.add_theme_font_size_override("font_size", 22)
	_tagline.add_theme_color_override("font_color", UITheme.GOLD)

	_style_scores_panel()
	_build_music_credits()

	_tower.game_chosen.connect(func(type, floor_index): RunState.start_game(type, floor_index))

	# Show local + online combined: seed with anything already fetched, then pull
	# the latest and push up any local scores that never synced.
	_online = Leaderboard.online_scores.duplicate()
	Leaderboard.online_scores_updated.connect(_on_online_scores)
	Leaderboard.fetch_online()
	Leaderboard.sync_pending()

	RunState.state_changed.connect(_refresh)
	_refresh()


func _on_online_scores(scores: Array) -> void:
	_online = scores
	_refresh_scores()


# ══════════════════════════════════════════════════════════════════════════════
#  Music credits (pinned bottom-left, as .map-music-credits in the web build)
# ══════════════════════════════════════════════════════════════════════════════

const MUSIC_CREDITS := [
	"« Creepy Dark Atmosphere » by Universfield",
	"« A Dark and Stormy Night » by Tim Kulig",
	"« Spooky Piano » and « Horror Creepy » by Nikita Kondrashev",
]
const CREDITS_BODY := Color("d2d6e2")

var _credits: VBoxContainer


func _build_music_credits() -> void:
	_credits = VBoxContainer.new()
	# top_level keeps it out of the root VBox's layout so it can float in the
	# bottom-RIGHT corner, clear of the left menu it used to overlap.
	_credits.top_level = true
	_credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credits.alignment = BoxContainer.ALIGNMENT_END
	_credits.add_theme_constant_override("separation", 1)

	var head := _credit_line("Royalty-free music from Pixabay.com", UITheme.GOLD)
	_credits.add_child(head)
	for line in MUSIC_CREDITS:
		_credits.add_child(_credit_line(line, CREDITS_BODY))
	add_child(_credits)

	resized.connect(_place_credits)
	_place_credits.call_deferred()


func _credit_line(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_override("font", UITheme.font("body"))
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	# A soft shadow keeps it legible over the tower art.
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _place_credits() -> void:
	if not is_instance_valid(_credits):
		return
	_credits.reset_size()
	# Bottom-right, so it never overlaps the menu on the left.
	_credits.position = Vector2(
		size.x - _credits.size.x - 16, size.y - _credits.size.y - 12)


func _refresh() -> void:
	_build_side()
	_refresh_scores()


# ══════════════════════════════════════════════════════════════════════════════
#  Left info panel
# ══════════════════════════════════════════════════════════════════════════════

func _build_side() -> void:
	for child in _side.get_children():
		child.queue_free()

	var pname: String = SaveManager.player_name if SaveManager.player_name != "" else "—"
	var hearts := ""
	for i in RunState.lives:
		hearts += "♥ "
	if hearts == "":
		hearts = "—"
	# Short stats share two-column rows so the whole menu fits without scrolling.
	_add_pair("Player", _text_value(pname, UITheme.GOLD, 26),
		"Lives", _text_value(hearts.strip_edges(), HEART, 26))

	_add_section("Time Patron", _patron_badge())

	_add_pair(
		"Time Credits", _text_value("⏳ %d" % RunState.gold, UITheme.GOLD, 26),
		"Time Energy", _text_value("⚡ %d" % int(SaveManager.profile.get("banked_credits", 0)), UITheme.GOLD, 26))

	_add_section("🎒 Inventory", _inventory_slots())

	_add_section("Lore", _compendium_button())
	_add_section("Customize", _panel_button("🂠 Cardback", func():
		RunState.cardback_return = "map"
		RunState.set_screen("cardback-select")))
	_side.add_child(_panel_button("🔊 Sound", func(): AudioSettings.open_popup(self)))
	_side.add_child(_panel_button("▶ Watch Intro", func():
		RunState.intro_replay = true
		RunState.set_screen("patron-dialogue")))
	# New Run gives up the whole descent — same as losing every life — and goes
	# through the game-over / score-entry flow.
	var new_run_btn := _panel_button("⚑ New Run", _confirm_new_run)
	new_run_btn.add_theme_color_override("font_color", UITheme.DANGER)
	_side.add_child(new_run_btn)


func _confirm_new_run() -> void:
	Modal.confirm(self, "New Run",
		"Start a New Run?\n\nThis ends your current descent — the rest of your lives are forfeit and your run is scored now.",
		func(): RunState.forfeit_run(),
		"New Run", "Cancel", true)


## A gold small-caps label over its value/content, the .map-side-label block.
func _labeled(label_text: String, content: Control) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)

	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(label)
	box.add_child(content)
	return box


## Each side entry is a gold-bordered card with a Cinzel small-caps label, like
## .map-side-section / .map-side-label.
func _add_section(label_text: String, content: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _section_box())
	panel.add_child(_labeled(label_text, content))
	_side.add_child(panel)


## Two labelled values sharing one row, to keep the menu short enough to fit.
func _add_pair(l1: String, c1: Control, l2: String, c2: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _section_box())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_labeled(l1, c1))
	row.add_child(_labeled(l2, c2))
	panel.add_child(row)
	_side.add_child(panel)


func _section_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = SECTION_BG
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = UITheme.GOLD_DIM
	s.set_corner_radius_all(5)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _text_value(text: String, color: Color, font_size := 22) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Portrait over the patron's name, matching .patron-badge.
func _patron_badge() -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)

	var portrait := TextureRect.new()
	portrait.texture = load(AssetPaths.PATRONS.get(RunState.patron, AssetPaths.PATRONS["johndee"]))
	portrait.custom_minimum_size = Vector2(68, 68)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(portrait)

	var name := Label.new()
	name.text = _patron_name(RunState.patron)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_override("font", UITheme.font_at("display", 600))
	name.add_theme_font_size_override("font_size", 22)
	name.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(name)
	return box


func _patron_name(id: String) -> String:
	for p in Narrative.PATRONS:
		if String(p.get("id", "")) == id:
			return String(p.get("name", id))
	return "John Dee"


func _inventory_slots() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	for i in GameData.INVENTORY_SLOTS:
		var label := Label.new()
		if i < RunState.inventory.size():
			var item: Dictionary = RunState.inventory[i]
			label.text = "%s %s" % [item["icon"], item["name"]]
			label.add_theme_color_override("font_color", UITheme.TEXT)
		else:
			label.text = "[ empty ]"
			label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		label.add_theme_font_override("font", UITheme.font("pixel"))
		label.add_theme_font_size_override("font_size", 22)
		box.add_child(label)
	return box


## Transparent, gold-outlined button in the pixel font, as .map-watch-intro-btn.
func _panel_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", Color(UITheme.GOLD, 0.85))
	button.add_theme_color_override("font_hover_color", UITheme.GOLD)
	button.add_theme_stylebox_override("normal", _ghost_button_box(0.35))
	button.add_theme_stylebox_override("hover", _ghost_button_box(0.8))
	button.add_theme_stylebox_override("pressed", _ghost_button_box(0.8))
	button.pressed.connect(action)
	return button


## The Compendium button, with a red "new content" badge in its top-right
## corner when the player has discoverable lore they have not yet seen —
## the .compendium-badge on the map button in index.html.
func _compendium_button() -> Button:
	var button := _panel_button("📖 Compendium",
		func(): RunState.set_screen("compendium"))
	var unseen := SaveManager.compendium_unseen_count()
	if unseen > 0:
		var badge := Label.new()
		badge.text = str(unseen)
		badge.add_theme_font_override("font", UITheme.font("pixel"))
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(20, 20)
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color("c0392b")  # the badge's crimson
		pill.set_corner_radius_all(10)
		pill.content_margin_left = 5
		pill.content_margin_right = 5
		badge.add_theme_stylebox_override("normal", pill)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.position = Vector2(-8, -8)
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		button.add_child(badge)
	return button


func _ghost_button_box(border_alpha: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(UITheme.GOLD, border_alpha)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


# ══════════════════════════════════════════════════════════════════════════════
#  High scores
# ══════════════════════════════════════════════════════════════════════════════

## Frames the score list like .map-lb-panel: a gold border, rounded, with a
## tinted header band under the title.
func _style_scores_panel() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = SCORE_BG
	frame.set_border_width_all(1)
	frame.border_color = UITheme.GOLD_DIM
	frame.set_corner_radius_all(6)
	frame.content_margin_bottom = 8
	_scores_frame.add_theme_stylebox_override("panel", frame)

	var band := StyleBoxFlat.new()
	band.bg_color = Color(UITheme.GOLD, 0.1)
	band.border_width_bottom = 1
	band.border_color = UITheme.GOLD_DIM
	band.content_margin_left = 14
	band.content_margin_right = 14
	band.content_margin_top = 8
	band.content_margin_bottom = 8
	_scores_title.add_theme_stylebox_override("normal", band)
	_scores_title.add_theme_font_override("font", UITheme.font_at("display", 700))
	_scores_title.add_theme_font_size_override("font_size", 22)
	_scores_title.add_theme_color_override("font_color", UITheme.GOLD)


## The font applied to every high-score row, so ranks, names and points read
## at the same comfortable size as the rest of the panel.
func _score_font(label: Label, color: Color) -> void:
	label.add_theme_font_override("font", UITheme.font_at("body", 500))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)


func _refresh_scores() -> void:
	for child in _scores.get_children():
		child.queue_free()

	# Local and online scores merged into one board (deduped, sorted).
	var merged := Leaderboard.merge_scores(SaveManager.highscores, _online, 16)

	if merged.is_empty():
		var none := Label.new()
		none.text = "No runs recorded yet."
		_score_font(none, UITheme.TEXT_DIM)
		none.add_theme_constant_override("margin_left", 12)
		_scores.add_child(_pad_row(none, false))
		return

	for i in merged.size():
		var e: Dictionary = merged[i]
		var all_floors := bool(e.get("all_floors", false))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var rank := Label.new()
		rank.text = "%d." % (i + 1)
		rank.custom_minimum_size.x = 36
		_score_font(rank, UITheme.GOLD if all_floors else UITheme.TEXT_DIM)
		row.add_child(rank)

		var who := Label.new()
		# A crown marks a run that cleared all ten floors — escaped the Tower.
		who.text = ("👑 " if all_floors else "") + str(e.get("name", "—"))
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		who.clip_text = true
		_score_font(who, Color("ffe98a") if all_floors else UITheme.TEXT)
		row.add_child(who)

		var pts := Label.new()
		pts.text = "%d" % int(e.get("score", 0))
		_score_font(pts, Color("ffe98a") if all_floors else UITheme.GOLD)
		row.add_child(pts)

		_scores.add_child(_pad_row(row, all_floors))


## Wraps a row in padding. All-floors runs get a gold-tinted band with a left
## accent so a completed descent stands out from the rest of the board.
func _pad_row(inner: Control, highlight: bool) -> Control:
	if highlight:
		var panel := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(UITheme.GOLD, 0.14)
		box.border_width_left = 3
		box.border_color = UITheme.GOLD
		box.set_corner_radius_all(3)
		box.content_margin_left = 11
		box.content_margin_right = 14
		box.content_margin_top = 3
		box.content_margin_bottom = 3
		panel.add_theme_stylebox_override("panel", box)
		panel.add_child(inner)
		return panel

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.add_child(inner)
	return margin
