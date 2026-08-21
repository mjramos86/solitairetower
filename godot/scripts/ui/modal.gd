class_name Modal
extends RefCounted

## Web-style Windows-95 modal dialog. A dimmed backdrop over a centred, bevelled
## window with a blue title bar — the look of the web build's modal boxes, in
## place of Godot's default AcceptDialog / ConfirmationDialog chrome.
##
## Everything lives in a CanvasLayer added to the scene tree root so the modal
## floats above the whole screen and is never clipped by its caller's layout.

const DIM := Color(0, 0, 0, 0.55)


## OK / Cancel confirmation. `on_confirm` runs only when the player accepts.
static func confirm(host: Node, title: String, message: String, on_confirm: Callable,
		ok_text := "OK", cancel_text := "Cancel", danger := false) -> void:
	var buttons := [
		{"text": cancel_text},
		{"text": ok_text, "action": on_confirm, "danger": danger, "primary": true},
	]
	custom(host, title, _message_body(message), buttons)


## Single-button notice. Returns the CanvasLayer so callers can auto-dismiss it
## (e.g. the timed peek preview closes itself after a few seconds).
static func alert(host: Node, title: String, message: String, on_close := Callable(),
		ok_text := "OK") -> CanvasLayer:
	var buttons := [{"text": ok_text, "action": on_close, "primary": true}]
	return custom(host, title, _message_body(message), buttons)


## Full control: an arbitrary body Control and a list of button specs
## `{text, action?: Callable, danger?: bool, primary?: bool, keep_open?: bool}`.
## Pressing a button closes the modal (unless keep_open) then runs its action.
static func custom(host: Node, title: String, body: Control, buttons: Array) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.build()
	layer.add_child(root)

	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(centre)

	var window := PanelContainer.new()
	window.custom_minimum_size = Vector2(420, 0)
	window.add_theme_stylebox_override("panel", UITheme.bevel_raised(UITheme.W95_BG, Vector2(0, 0), 2.0))
	centre.add_child(window)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	window.add_child(stack)

	stack.add_child(_titlebar(title))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 20)
	pad.add_theme_constant_override("margin_right", 20)
	pad.add_theme_constant_override("margin_top", 18)
	pad.add_theme_constant_override("margin_bottom", 16)
	stack.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	pad.add_child(col)

	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)

	for spec in buttons:
		var button := Button.new()
		button.text = String(spec.get("text", "OK"))
		button.custom_minimum_size = Vector2(96, 0)
		if bool(spec.get("danger", false)):
			button.add_theme_color_override("font_color", UITheme.MAROON)
		var action: Callable = spec.get("action", Callable())
		var keep_open: bool = bool(spec.get("keep_open", false))
		button.pressed.connect(func():
			if not keep_open and is_instance_valid(layer):
				layer.queue_free()
			if action.is_valid():
				action.call())
		row.add_child(button)

	host.get_tree().root.add_child(layer)
	return layer


static func _message_body(message: String) -> Control:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 380
	label.add_theme_font_override("font", UITheme.font("pixel"))
	label.add_theme_font_size_override("font_size", 23)
	label.add_theme_color_override("font_color", UITheme.W95_DARKER)
	return label


## Blue Windows-95 title bar with white text and decorative window buttons.
static func _titlebar(title: String) -> Control:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.W95_TITLE
	style.content_margin_left = 8
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)

	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", UITheme.font("pixel"))
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.W95_WHITE)
	row.add_child(label)

	for glyph in ["_", "□", "✕"]:
		var btn := Label.new()
		btn.text = glyph
		btn.custom_minimum_size = Vector2(20, 18)
		btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_theme_font_override("font", UITheme.font("pixel"))
		btn.add_theme_color_override("font_color", UITheme.W95_DARKER)
		btn.add_theme_stylebox_override("normal", UITheme.bevel_raised(UITheme.W95_BG, Vector2(0, 0), 2.0))
		row.add_child(btn)

	return bar
