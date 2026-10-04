extends RefCounted

## The interface-size picker, shared by the options screen and the in-game pause
## menu. Built in one place because the two copies must agree: the row shows
## which size is active by disabling that button, so a divergence would show the
## player the wrong current setting.
##
## Follows AudioSettings.build_controls, which is shared between the same two
## hosts for the same reason.

const SECTION_SIZE := 18
const BUTTON_SIZE := Vector2(120, 48)


## A labelled row of size buttons. `on_change` is called after the scale has been
## applied, so the host can rebuild itself at the new size — every control on
## screen has just changed dimensions, including this row.
static func build(on_change: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = Locale.t("Interface Size").to_upper()
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", SECTION_SIZE)
	label.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	for value in SaveManager.UI_SCALES:
		var button := Button.new()
		button.text = "%d%%" % roundi(float(value) * 100.0)
		button.custom_minimum_size = BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", UITheme.font("pixel"))
		button.add_theme_font_size_override("font_size", 22)
		# The active size reads as selected, the way the language row does.
		button.disabled = is_equal_approx(float(value), SaveManager.ui_scale())
		button.pressed.connect(func():
			SaveManager.set_ui_scale(float(value))
			if on_change.is_valid():
				on_change.call())
		row.add_child(button)
	box.add_child(row)
	return box
