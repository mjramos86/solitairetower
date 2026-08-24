extends Control

## The leaderboard, reached from the title menu. Two views, toggled by the player:
##   • Local — the best finished runs saved on this machine (shared across slots).
##   • Local + Online — those merged with the global Firestore board.
##
## Local scores upload themselves the moment they're set (see SaveManager →
## Leaderboard); "Sync now" retries anything that failed while offline and
## refreshes the global list.

@onready var _title: Label = $Center/Col/Title
@onready var _frame: PanelContainer = $Center/Col/Frame
@onready var _rows: VBoxContainer = $Center/Col/Frame/Scroll/Rows
@onready var _back: Button = $Center/Col/Back

var _mode := "local"  # "local" | "combined"
var _local_button: Button
var _combined_button: Button
var _sync_button: Button
var _status: Label


func _ready() -> void:
	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", UITheme.GOLD)

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.039, 0.024, 0.086, 0.85)
	frame.set_border_width_all(1)
	frame.border_color = UITheme.GOLD_DIM
	frame.set_corner_radius_all(6)
	frame.content_margin_left = 18
	frame.content_margin_right = 18
	frame.content_margin_top = 14
	frame.content_margin_bottom = 14
	_frame.add_theme_stylebox_override("panel", frame)

	_build_controls()

	Leaderboard.online_scores_updated.connect(func(_s): _build_rows())
	Leaderboard.sync_state_changed.connect(func(_s): _refresh_status())

	_back.pressed.connect(func(): RunState.set_screen("title"))
	_refresh_status()
	_build_rows()


## A tab row (Local / Local + Online) above the table and a sync row below it,
## both inserted into the existing column so the .tscn stays simple.
func _build_controls() -> void:
	var col: VBoxContainer = $Center/Col

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	_local_button = _tab("Local", func(): _set_mode("local"))
	_combined_button = _tab("Local + Online", func(): _set_mode("combined"))
	tabs.add_child(_local_button)
	tabs.add_child(_combined_button)
	col.add_child(tabs)
	col.move_child(tabs, 1)  # directly under the title

	var sync_row := HBoxContainer.new()
	sync_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sync_row.add_theme_constant_override("separation", 12)
	_sync_button = Button.new()
	_sync_button.text = "⟳ Sync now"
	_sync_button.add_theme_font_override("font", UITheme.font("pixel"))
	_sync_button.add_theme_font_size_override("font_size", 13)
	_sync_button.pressed.connect(_on_sync)
	_status = Label.new()
	_status.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sync_row.add_child(_sync_button)
	sync_row.add_child(_status)
	col.add_child(sync_row)
	col.move_child(sync_row, 3)  # under the table frame

	_style_tabs()


func _tab(label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", UITheme.font("pixel"))
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(on_press)
	return b


func _set_mode(mode: String) -> void:
	if _mode == mode:
		return
	_mode = mode
	_style_tabs()
	if mode == "combined":
		# Pull the latest global board (and quietly retry any unsynced locals).
		Leaderboard.sync_pending()
	_refresh_status()
	_build_rows()


func _style_tabs() -> void:
	_local_button.button_pressed = _mode == "local"
	_combined_button.button_pressed = _mode == "combined"
	for b in [_local_button, _combined_button]:
		var active: bool = b.button_pressed
		b.add_theme_color_override("font_color", UITheme.GOLD if active else UITheme.TEXT_DIM)


func _on_sync() -> void:
	Leaderboard.sync_pending()
	_refresh_status()


func _refresh_status() -> void:
	if _status == null:
		return
	var pending: int = SaveManager.unsynced_scores().size()
	var text := ""
	match Leaderboard.status:
		"syncing":
			text = "Syncing…"
		"offline":
			text = "Offline — online scores unavailable"
		"error":
			text = "Sync failed — will retry"
		_:
			text = "Online ✓" if _mode == "combined" else ""
	if pending > 0:
		text += ("  •  " if text != "" else "") + "%d not yet uploaded" % pending
	_status.text = text


func _build_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()

	var entries: Array = SaveManager.highscores
	var local_keys := {}
	if _mode == "combined":
		for e in SaveManager.highscores:
			local_keys[_key(e)] = true
		entries = Leaderboard.merge_scores(SaveManager.highscores, Leaderboard.online_scores)

	if entries.is_empty():
		var none := Label.new()
		none.text = "No runs recorded yet." if _mode == "local" else "No scores to show yet."
		none.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_rows.add_child(none)
		return

	_rows.add_child(_row("#", "Player", "Time", "Score", UITheme.TEXT_DIM, true))

	for i in entries.size():
		var e: Dictionary = entries[i]
		var who := str(e.get("name", "—"))
		# In the combined view, flag rows that live only on the global board.
		if _mode == "combined" and not local_keys.has(_key(e)):
			who = "🌐 " + who
		_rows.add_child(_row(
			"%d." % (i + 1),
			who,
			_format_time(float(e.get("time", 0.0))),
			"%d" % int(e.get("score", 0)),
			UITheme.TEXT))


func _key(e: Dictionary) -> String:
	return "%s|%d|%.3f" % [String(e.get("name", "")), int(e.get("score", 0)),
		float(e.get("time", 0.0))]


func _row(rank: String, who: String, time: String, score: String, color: Color, header := false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var rank_label := _cell(rank, color, 40)
	var who_label := _cell(who, color, 0)
	who_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var time_label := _cell(time, color, 90)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var score_label := _cell(score, UITheme.GOLD if not header else color, 90)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	for c in [rank_label, who_label, time_label, score_label]:
		if header:
			c.add_theme_font_override("font", UITheme.font_at("display", 700))
			c.add_theme_font_size_override("font_size", 13)
		row.add_child(c)
	return row


func _cell(text: String, color: Color, min_w: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	if min_w > 0:
		l.custom_minimum_size.x = min_w
	return l


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	@warning_ignore("integer_division")
	return "%d:%02d" % [total / 60, total % 60]
