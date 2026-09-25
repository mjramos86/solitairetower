extends Control

## Credits and legal notices. Reached from the title screen. Lists authorship,
## the licensed music, the engine and libraries the build ships, the bundled
## fonts (all under the SIL Open Font License), and the copyright / trademark
## notice. Rebuilt on a language change so the labels switch immediately.

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

	# A scroll view keeps the credits readable on short windows without clipping.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)

	_panel = VBoxContainer.new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.custom_minimum_size.x = 540
	_panel.add_theme_constant_override("separation", 14)
	scroll.add_child(_panel)

	_rebuild()


func _rebuild() -> void:
	for child in _panel.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = Locale.t("CREDITS")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.font_at("title", 900))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	_panel.add_child(title)

	_panel.add_child(_spacer(6))

	# ── Authorship ──
	_panel.add_child(_section(Locale.t("Game Design, Art & Writing")))
	_panel.add_child(_line("Mario Jorge Ramos", 22, UITheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	_panel.add_child(_line(Locale.t("aka Emjayhar"), 16, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_panel.add_child(_spacer(4))
	_panel.add_child(_line(
		Locale.t("AI tools were used to assist with the game's source code."),
		15, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# ── Music ──
	_panel.add_child(_section(Locale.t("Music")))
	_panel.add_child(_line(Locale.t("Royalty-free music from Pixabay.com"),
		15, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_panel.add_child(_spacer(2))
	for credit in [
		"« Creepy dark atmosphere » — Universfield",
		"« A dark and stormy night » — Tim Kulig",
		"« Spooky piano » & « Horror creepy » — Nikita Kondrashev",
	]:
		_panel.add_child(_line(credit, 16, UITheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))

	# ── Engine & libraries ──
	_panel.add_child(_section(Locale.t("Made With")))
	_panel.add_child(_line("Godot Engine — © Juan Linietsky, Ariel Manzur & contributors (MIT)",
		14, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_panel.add_child(_line("GodotSteam — © Gramps (MIT)",
		14, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# ── Fonts ──
	_panel.add_child(_section(Locale.t("Fonts")))
	_panel.add_child(_line("Cinzel · EB Garamond · Inter · Playfair Display · Share Tech Mono · VT323",
		14, UITheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	_panel.add_child(_line(Locale.t("Licensed under the SIL Open Font License"),
		13, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# ── Copyright / trademark ──
	_panel.add_child(_spacer(14))
	var rule := HSeparator.new()
	_panel.add_child(rule)
	_panel.add_child(_spacer(6))
	var year: int = Time.get_datetime_dict_from_system()["year"]
	_panel.add_child(_line("© %d Mario Jorge Ramos" % year, 14, UITheme.TEXT,
		HORIZONTAL_ALIGNMENT_CENTER))
	_panel.add_child(_line(Locale.t("All rights reserved."), 13, UITheme.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_CENTER))
	_panel.add_child(_line(Locale.t("Solitaire Tower of Doom™ is a trademark of Mario Jorge Ramos."),
		12, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# ── Back ──
	_panel.add_child(_spacer(14))
	var back := Button.new()
	back.text = Locale.t("◂ Back")
	back.custom_minimum_size = Vector2(200, 52)
	back.add_theme_font_override("font", UITheme.font("pixel"))
	back.add_theme_font_size_override("font_size", 24)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): RunState.set_screen("title"))
	_panel.add_child(back)


func _section(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_spacer(10))
	var l := Label.new()
	l.text = text.to_upper()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font_at("display", 600))
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(l)
	return box


func _line(text: String, size: int, color: Color, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", UITheme.font("body"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


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
