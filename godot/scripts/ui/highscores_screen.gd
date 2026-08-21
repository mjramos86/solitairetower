extends Control

## The local leaderboard, reached from the title menu. Shared across all save
## slots — one table of the best finished runs. Replaces the web build's online
## Firestore board.

@onready var _title: Label = $Center/Col/Title
@onready var _frame: PanelContainer = $Center/Col/Frame
@onready var _rows: VBoxContainer = $Center/Col/Frame/Scroll/Rows
@onready var _back: Button = $Center/Col/Back


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

	_back.pressed.connect(func(): RunState.set_screen("title"))
	_build_rows()


func _build_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()

	if SaveManager.highscores.is_empty():
		var none := Label.new()
		none.text = "No runs recorded yet."
		none.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_rows.add_child(none)
		return

	# Header row.
	_rows.add_child(_row("#", "Player", "Time", "Score", UITheme.TEXT_DIM, true))

	for i in SaveManager.highscores.size():
		var e: Dictionary = SaveManager.highscores[i]
		_rows.add_child(_row(
			"%d." % (i + 1),
			str(e.get("name", "—")),
			_format_time(float(e.get("time", 0.0))),
			"%d" % int(e.get("score", 0)),
			UITheme.TEXT))


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
