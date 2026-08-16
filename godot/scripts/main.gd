extends Control

## Import verification screen.
##
## This is scaffolding, not gameplay. Run the project (F5) after opening it for
## the first time: it loads every asset listed in AssetPaths and reports what
## resolved. A green list means the import step worked and you can start porting
## screens; a red line means that file failed to import or is misnamed.
##
## Replace run/main_scene in project.godot with the real title screen once the
## port begins, and delete this file.

const ROW_HEIGHT := 22

var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 32)
	root.add_theme_constant_override("margin_right", 32)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	root.add_child(col)

	col.add_child(_heading())
	col.add_child(_font_preview())
	col.add_child(_texture_preview())
	col.add_child(_audio_row())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	var report := VBoxContainer.new()
	report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report.add_theme_constant_override("separation", 2)
	scroll.add_child(report)

	_run_check(report)


func _heading() -> Control:
	var label := Label.new()
	label.text = "The Solitaire Tower of Doom — asset import check"
	var font := load(AssetPaths.FONTS["display"]) as Font
	if font:
		var variation := FontVariation.new()
		variation.base_font = font
		variation.variation_opentype = {"wght": 700}
		label.add_theme_font_override("font", variation)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("d4a84b"))
	return label


## Renders one line per font so you can eyeball that each family imported and
## that variable-weight axes are actually being applied.
func _font_preview() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	for key in AssetPaths.FONTS:
		var path: String = AssetPaths.FONTS[key]
		var line := Label.new()
		var font := load(path) as Font
		if font == null:
			line.text = "%s — FAILED TO LOAD (%s)" % [key, path]
			line.add_theme_color_override("font_color", Color("ff6b6b"))
		else:
			line.text = "%s — The Tower waits. Floor 7. 1,040 pts." % key
			line.add_theme_font_override("font", font)
			line.add_theme_font_size_override("font_size", 20)
		box.add_child(line)
	return box


## Shows the four selectable card backs at card aspect (750x1050).
func _texture_preview() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id in AssetPaths.CARDBACKS:
		var tex := load(AssetPaths.CARDBACKS[id]) as Texture2D
		var rect := TextureRect.new()
		rect.custom_minimum_size = Vector2(90, 126)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture = tex
		rect.tooltip_text = "%s\n%s" % [id, AssetPaths.CARDBACKS[id]]
		row.add_child(rect)
	return row


func _audio_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for sfx_name in AssetPaths.SFX:
		var button := Button.new()
		button.text = "Play %s" % sfx_name
		button.pressed.connect(_play_sfx.bind(AssetPaths.SFX[sfx_name]))
		row.add_child(button)
	return row


func _play_sfx(path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("SFX failed to load: %s" % path)
		return
	_sfx_player.stream = stream
	_sfx_player.play()


func _run_check(report: VBoxContainer) -> void:
	var paths := AssetPaths.required_assets()
	var failures := 0

	for path in paths:
		# Check existence first: calling load() on a missing path spams the
		# Output panel with engine errors and obscures the report.
		var ok := ResourceLoader.exists(path) and ResourceLoader.load(path) != null
		if not ok:
			failures += 1
		report.add_child(_status_line(ok, path))

	# Video is optional until the ffmpeg conversion step has been run.
	for key in AssetPaths.VIDEO:
		var video_path: String = AssetPaths.VIDEO[key]
		if ResourceLoader.exists(video_path):
			report.add_child(_status_line(true, video_path))
		else:
			var line := Label.new()
			line.text = "  ○  %s — not converted yet (see tools/convert_video.sh)" % video_path
			line.add_theme_color_override("font_color", Color("9a8fb0"))
			line.custom_minimum_size.y = ROW_HEIGHT
			report.add_child(line)

	var summary := Label.new()
	summary.add_theme_font_size_override("font_size", 18)
	if failures == 0:
		summary.text = "\nAll %d required assets imported cleanly." % paths.size()
		summary.add_theme_color_override("font_color", Color("6bcf7f"))
	else:
		summary.text = "\n%d of %d assets failed to load — see the red lines above." % [failures, paths.size()]
		summary.add_theme_color_override("font_color", Color("ff6b6b"))
	report.add_child(summary)

	print("Asset check: %d/%d loaded" % [paths.size() - failures, paths.size()])


func _status_line(ok: bool, path: String) -> Label:
	var line := Label.new()
	line.text = "  %s  %s" % ["✓" if ok else "✗", path]
	line.add_theme_color_override("font_color", Color("6bcf7f") if ok else Color("ff6b6b"))
	line.custom_minimum_size.y = ROW_HEIGHT
	return line
