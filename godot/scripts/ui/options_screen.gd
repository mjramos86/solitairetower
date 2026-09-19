extends Control

## Options: choose the text language and adjust Music / Sound-effects volume.
## Reached from the title screen. Rebuilds itself when the language changes so the
## labels switch immediately.

const AudioSettings := preload("res://scripts/ui/audio_settings.gd")

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

	_panel = VBoxContainer.new()
	_panel.custom_minimum_size.x = 460
	_panel.add_theme_constant_override("separation", 22)
	frame.add_child(_panel)

	_rebuild()


func _rebuild() -> void:
	for child in _panel.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = Locale.t("OPTIONS")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.font_at("title", 900))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	_panel.add_child(title)

	# ── Language ──
	_panel.add_child(_section_label(Locale.t("Language")))
	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.add_theme_constant_override("separation", 12)
	for code in Locale.LANGUAGES:
		var btn := Button.new()
		btn.text = String(Locale.LANGUAGES[code])
		btn.custom_minimum_size = Vector2(180, 48)
		btn.add_theme_font_override("font", UITheme.font("pixel"))
		btn.add_theme_font_size_override("font_size", 22)
		btn.disabled = code == Locale.lang  # the active language reads as selected
		btn.pressed.connect(_on_language.bind(String(code)))
		lang_row.add_child(btn)
	_panel.add_child(lang_row)

	# ── Audio ──
	_panel.add_child(_section_label(Locale.t("Audio")))
	var audio := AudioSettings.build_controls(true)
	audio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.add_child(audio)

	# ── Back ──
	var back := Button.new()
	back.text = Locale.t("◂ Back")
	back.custom_minimum_size = Vector2(200, 52)
	back.add_theme_font_override("font", UITheme.font("pixel"))
	back.add_theme_font_size_override("font_size", 24)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): RunState.set_screen("title"))
	_panel.add_child(back)


func _on_language(code: String) -> void:
	Locale.set_language(code)
	_rebuild()  # relabel this screen in the newly chosen language


func _section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", UITheme.font_at("display", 600))
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", UITheme.GOLD)
	return l


func _frame_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.039, 0.024, 0.086, 0.92)
	s.set_border_width_all(2)
	s.border_color = UITheme.GOLD_DIM
	s.set_corner_radius_all(8)
	s.content_margin_left = 40
	s.content_margin_right = 40
	s.content_margin_top = 32
	s.content_margin_bottom = 32
	return s
