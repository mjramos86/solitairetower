extends RefCounted

## Reusable Music / Sound-effects volume sliders.
##
## Callers reach this via `preload("res://scripts/ui/audio_settings.gd")` rather
## than a global `class_name`, so the identifier always resolves at parse time —
## a global class name is only registered after an editor rescan, which caused a
## spurious "Identifier not declared" error on fresh checkouts.
##
## The volume backend already lives in AudioManager (two buses, Music and SFX,
## driven by the profile's `music_volume` / `sfx_volume`). This just builds the
## UI that edits those values live and persists them:
##   * build_controls(on_dark) → a VBox of two labelled sliders, for embedding
##     (e.g. the in-game pause overlay).
##   * open_popup(host)        → the same controls in a Modal, for menu screens.

const MUSIC_KEY := "music_volume"
const SFX_KEY := "sfx_volume"


## The two sliders. `on_dark` picks label colours: gold/parchment for the dark
## occult panels, near-black for the light Windows-95 modal.
static func build_controls(on_dark: bool = true) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 340
	box.add_theme_constant_override("separation", 16)
	box.add_child(_slider_row("♪  Music", MUSIC_KEY, on_dark, false))
	box.add_child(_slider_row("🔊  Sound Effects", SFX_KEY, on_dark, true))
	return box


## Shows the sliders centred in a Windows-95 modal — used from menu screens.
static func open_popup(host: Node) -> void:
	Modal.custom(host, "🔊  Sound", build_controls(false),
		[{"text": "Done"}])


static func _slider_row(label_text: String, key: String, on_dark: bool, sample_sfx: bool) -> Control:
	var label_color := UITheme.GOLD if on_dark else UITheme.W95_DARKER
	var value_color := UITheme.TEXT if on_dark else UITheme.W95_DARK

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var header := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", label_color)
	header.add_child(label)

	var start := float(SaveManager.profile.get(key, 0.7))
	var pct := Label.new()
	pct.text = "%d%%" % roundi(start * 100.0)
	pct.custom_minimum_size.x = 52
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_override("font", UITheme.font_at("display", 600))
	pct.add_theme_font_size_override("font_size", 18)
	pct.add_theme_color_override("font_color", value_color)
	header.add_child(pct)
	row.add_child(header)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = start
	slider.custom_minimum_size = Vector2(0, 26)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_slider(slider)

	slider.value_changed.connect(func(v: float):
		SaveManager.profile[key] = v
		SaveManager.mark_dirty()
		AudioManager.apply_volumes()
		pct.text = "%d%%" % roundi(v * 100.0))
	# Persist to disk and (for the SFX slider) play a sample once the drag ends,
	# rather than on every intermediate value.
	slider.drag_ended.connect(func(_changed: bool):
		SaveManager.save_game()
		if sample_sfx:
			AudioManager.card_moved())
	row.add_child(slider)
	return row


## Gold groove and filled track over a dark inset, so the level reads at a glance
## on both the light modal and the dark pause panel.
static func _style_slider(slider: HSlider) -> void:
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color("2a2333")
	groove.set_corner_radius_all(4)
	groove.set_border_width_all(1)
	groove.border_color = UITheme.GOLD_DIM
	groove.content_margin_top = 4
	groove.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", groove)

	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.GOLD
	fill.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area", fill)

	var fill_hi := StyleBoxFlat.new()
	fill_hi.bg_color = Color("ffe98a")
	fill_hi.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_hi)
