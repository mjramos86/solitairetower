extends Control

## Lifetime statistics for the active save slot, ported from the web build's
## "Account & Stats" panel. Reached from the tower map. Reads everything from
## SaveManager.profile: run tallies, aggregate game tallies (summed from the
## per-variant record), and a per-variant table.

var _panel: VBoxContainer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _frame_box())
	centre.add_child(frame)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)

	# Right margin keeps the right-aligned values clear of the vertical scrollbar.
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 18)
	scroll.add_child(pad)

	_panel = VBoxContainer.new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.custom_minimum_size.x = 522
	_panel.add_theme_constant_override("separation", 12)
	pad.add_child(_panel)

	_build()


func _build() -> void:
	var p: Dictionary = SaveManager.profile

	var title := Label.new()
	title.text = Locale.t("STATISTICS")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.font_at("title", 900))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	_panel.add_child(title)

	var who := String(SaveManager.player_name)
	if who != "":
		_panel.add_child(_line(who, 18, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# ── Run Stats (a full descent, floor 10 → floor 1) ──
	var runs_played := int(p.get("runs_played", 0))
	var runs_won := int(p.get("runs_won", 0))
	_panel.add_child(_section(Locale.t("Run Stats")))
	var run_grid := _grid()
	_stat(run_grid, Locale.t("Runs Played"), str(runs_played))
	_stat(run_grid, Locale.t("Runs Won"), str(runs_won))
	_stat(run_grid, Locale.t("Win Rate"), _pct(runs_won, runs_played))
	_stat(run_grid, Locale.t("Best Score"), _grouped(int(p.get("best_score", 0))))
	_stat(run_grid, Locale.t("Best Time"), _time(float(p.get("best_time", 0.0))))
	_stat(run_grid, Locale.t("Total Score"), _grouped(int(p.get("total_score", 0))))
	_panel.add_child(run_grid)

	# ── Game Stats (each shuffle of one variant), summed from the per-variant log ──
	var stats: Dictionary = p.get("game_stats", {})
	var games_played := 0
	var games_won := 0
	for type in stats:
		games_played += int((stats[type] as Dictionary).get("played", 0))
		games_won += int((stats[type] as Dictionary).get("won", 0))
	_panel.add_child(_section(Locale.t("Game Stats")))
	var game_grid := _grid()
	_stat(game_grid, Locale.t("Games Played"), str(games_played))
	_stat(game_grid, Locale.t("Games Won"), str(games_won))
	_stat(game_grid, Locale.t("Win Rate"), _pct(games_won, games_played))
	_panel.add_child(game_grid)

	# ── By Variant ──
	_panel.add_child(_section(Locale.t("By Variant")))
	_panel.add_child(_variant_row(Locale.t("Variant"), Locale.t("Played"),
		Locale.t("Won"), Locale.t("Win %"), true))
	for type in GameData.NAMES:
		var row: Dictionary = stats.get(type, {})
		var played := int(row.get("played", 0))
		var won := int(row.get("won", 0))
		var label := "%s %s" % [GameData.ICONS.get(type, ""), Locale.t(String(GameData.NAMES[type]))]
		_panel.add_child(_variant_row(label, str(played), str(won), _pct(won, played), false))

	# ── Back ──
	_panel.add_child(_spacer(14))
	var back := Button.new()
	back.text = Locale.t("◂ Back")
	back.custom_minimum_size = Vector2(200, 52)
	back.add_theme_font_override("font", UITheme.font("pixel"))
	back.add_theme_font_size_override("font_size", 24)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): RunState.set_screen("map"))
	_panel.add_child(back)


# ── Building blocks ──

func _section(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_spacer(8))
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", UITheme.font_at("display", 600))
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(l)
	return box


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 20)
	g.add_theme_constant_override("v_separation", 6)
	return g


func _stat(grid: GridContainer, label: String, value: String) -> void:
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", UITheme.font("body"))
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_font_override("font", UITheme.font_at("display", 600))
	v.add_theme_font_size_override("font_size", 18)
	v.add_theme_color_override("font_color", UITheme.GOLD)
	grid.add_child(l)
	grid.add_child(v)


func _variant_row(name: String, played: String, won: String, pct: String, header: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var color := UITheme.TEXT_DIM if header else UITheme.TEXT
	var name_cell := _cell(name, color, 0)
	name_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cells := [name_cell, _cell(played, color, 80), _cell(won, color, 80),
		_cell(pct, UITheme.GOLD if not header else color, 90)]
	for i in range(1, cells.size()):
		(cells[i] as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for c in cells:
		if header:
			c.add_theme_font_override("font", UITheme.font_at("display", 700))
			c.add_theme_font_size_override("font_size", 14)
		row.add_child(c)
	return row


func _cell(text: String, color: Color, min_w: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", UITheme.font("body"))
	l.add_theme_font_size_override("font_size", 17)
	if min_w > 0:
		l.custom_minimum_size.x = min_w
	return l


func _line(text: String, size: int, color: Color, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", UITheme.font("body"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


# ── Formatting ──

## Whole-percent win rate, guarding division by zero, like the web's pct().
func _pct(part: int, whole: int) -> String:
	if whole <= 0:
		return "—"
	return "%d%%" % roundi(100.0 * float(part) / float(whole))


## Thousands separators, matching the web's toLocaleString on the score.
func _grouped(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


func _time(seconds: float) -> String:
	if seconds <= 0.0:
		return "—"
	var total := int(seconds)
	@warning_ignore("integer_division")
	return "%d:%02d" % [total / 60, total % 60]


func _frame_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.039, 0.024, 0.086, 0.92)
	s.set_border_width_all(2)
	s.border_color = UITheme.GOLD_DIM
	s.set_corner_radius_all(8)
	s.content_margin_left = 40
	s.content_margin_right = 40
	s.content_margin_top = 28
	s.content_margin_bottom = 28
	return s
