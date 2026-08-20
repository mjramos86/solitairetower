extends Control

## The tower with floor nodes climbing it — the centrepiece of the map.
##
## Ported from buildTowerPath in index.html. Ten nodes are placed on the tower
## at fixed points in a 1000x1333 design space; nodes are revealed from the top
## down to the current floor and joined by a glowing path. Cleared floors show a
## tick, the current floor shows its two game choices (or FreeCell on the final
## boss floor), and floors below the current one stay hidden until reached.
##
## The tower art is shown at its true aspect (not cropped) so the node
## coordinates land where they should; everything is recomputed on resize.

signal game_chosen(type: String, floor_index: int)

## Node anchor points in the web build's 1000x1333 tower space.
const NODE_POINTS := [
	Vector2(566, 120), Vector2(624, 250), Vector2(544, 372), Vector2(620, 494),
	Vector2(550, 616), Vector2(626, 738), Vector2(554, 860), Vector2(616, 982),
	Vector2(566, 1104), Vector2(590, 1226),
]
const VIEWBOX := Vector2(1000.0, 1333.0)
const TOWER_ASPECT := 700.0 / 933.0  # matches the tower frames

const NODE_RADIUS := 13.0
const CURRENT_RADIUS := 16.0

## The climbing path, .tower-path-line: a bright gold stroke with a soft glow.
const PATH_BRIGHT := Color("ffd83a")
const PATH_GLOW := Color(1.0, 0.847, 0.227, 0.35)

## Node fills as [outer, mid, inner] to fake the CSS radial-gradients, plus a
## glow colour. Done nodes are aged gold; the current node is bright; the boss
## node burns red.
const DONE_FILL := [Color("7a5f28"), Color("b9902f"), Color("e8c766")]
const DONE_GLOW := Color(0.831, 0.659, 0.294, 0.5)
const CUR_FILL := [Color("c9960a"), Color("ffd21e"), Color("fff2a8")]
const CUR_BORDER := Color("fff3b0")
const CUR_GLOW := Color(1.0, 0.847, 0.227, 0.7)
const BOSS_FILL := [Color("a01818"), Color("ff5a1e"), Color("ffd0a8")]
const BOSS_BORDER := Color("ffd0b0")
const PENDING_RING := Color(1.0, 0.847, 0.227, 0.55)

var _tower: Control
var _overlay: Control
var _tower_rect := Rect2()
var _options := VBoxContainer.new()
var _pulse := 0.0


func _ready() -> void:
	clip_contents = true
	_tower = (load(AssetPaths.TOWER_SCENE) as PackedScene).instantiate() as Control
	add_child(_tower)

	# The nodes and path must draw ON TOP of the tower image, so they live on a
	# sibling overlay added after it rather than on this control (whose own
	# drawing would sit behind its children).
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_overlay.draw.connect(_paint_overlay)

	_options.add_theme_constant_override("separation", 6)
	add_child(_options)

	resized.connect(_relayout)
	RunState.state_changed.connect(_relayout)
	set_process(true)
	_relayout()


func _process(_delta: float) -> void:
	# A slow pulse on the current node.
	_pulse = fmod(_pulse + _delta, TAU)
	if _overlay:
		_overlay.queue_redraw()


## Places the tower centred at its true aspect, then lays the nodes over it.
func _relayout() -> void:
	if not is_inside_tree() or _tower == null:
		return
	var avail := size
	# Fit the tower to the available height, then width from the aspect; if that
	# overflows the width, fit to width instead.
	var h := avail.y
	var w := h * TOWER_ASPECT
	if w > avail.x:
		w = avail.x
		h = w / TOWER_ASPECT
	var pos := Vector2((avail.x - w) * 0.5, (avail.y - h) * 0.5)
	_tower_rect = Rect2(pos, Vector2(w, h))
	_tower.position = pos
	_tower.custom_minimum_size = Vector2(w, h)
	_tower.size = Vector2(w, h)

	_build_options()
	if _overlay:
		_overlay.queue_redraw()


func _node_center(floor_index: int) -> Vector2:
	var p: Vector2 = NODE_POINTS[floor_index]
	return _tower_rect.position + (p / VIEWBOX) * _tower_rect.size


## Painted on the overlay so it sits above the tower art. All draw_* calls go to
## `_overlay`, the CanvasItem whose `draw` signal invoked this.
func _paint_overlay() -> void:
	var current: int = mini(RunState.floor_index, 9)
	var font := UITheme.font("pixel")

	# The climbing path through every revealed node: a soft glow under a bright
	# gold stroke, like the SVG polyline's drop-shadow.
	if current >= 1:
		var pts := PackedVector2Array()
		for f in range(0, current + 1):
			pts.append(_node_center(f))
		_overlay.draw_polyline(pts, PATH_GLOW, 7.0, true)
		_overlay.draw_polyline(pts, PATH_BRIGHT, 3.0, true)

	for f in range(0, current + 1):
		var c := _node_center(f)
		if RunState.done.has(f) and f != RunState.floor_index:
			_draw_dot(c, NODE_RADIUS, DONE_FILL, DONE_GLOW, DONE_FILL[2], NODE_RADIUS + 4.0)
			var check := "✓"
			var sz := font.get_string_size(check, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
			_overlay.draw_string(font, c - sz * 0.5 + Vector2(0, sz.y * 0.35), check,
				HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color("3a2a00"))
		elif f == RunState.floor_index:
			# Glowing current node with an expanding pulse ring.
			var glow := 0.5 + 0.5 * sin(_pulse * 2.0)
			var boss := f == 9
			var fill: Array = BOSS_FILL if boss else CUR_FILL
			var border: Color = BOSS_BORDER if boss else CUR_BORDER
			_draw_dot(c, CURRENT_RADIUS, fill, CUR_GLOW, border, CURRENT_RADIUS + 8.0 + 4.0 * glow)
			_overlay.draw_arc(c, CURRENT_RADIUS + 5.0 + 3.0 * glow, 0, TAU, 32,
				Color(PENDING_RING, 0.5 * (1.0 - glow) + 0.2), 2.0)
			if boss:
				var crown := "♛"
				var sz := font.get_string_size(crown, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
				_overlay.draw_string(font, c - sz * 0.5 + Vector2(0, sz.y * 0.35), crown,
					HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color("3a0000"))


## Draws a node as concentric fills (outer→inner) to fake the CSS radial
## gradient, wrapped in a soft glow and a bright rim.
func _draw_dot(c: Vector2, r: float, fill: Array, glow: Color, rim: Color, glow_r: float) -> void:
	_overlay.draw_circle(c, glow_r, Color(glow, 0.3))
	_overlay.draw_circle(c, r, fill[0])
	_overlay.draw_circle(c, r * 0.68, fill[1])
	_overlay.draw_circle(c, r * 0.36, fill[2])
	_overlay.draw_arc(c, r, 0, TAU, 28, rim, 2.0)


## The current floor's game-choice buttons, floated just beside its node.
func _build_options() -> void:
	for child in _options.get_children():
		child.queue_free()

	var f := RunState.floor_index
	if f > 9:
		return
	var center := _node_center(f)

	var types := []
	if f == 9:
		types = ["freecell"]
	else:
		var choice: Dictionary = RunState.choices[f] if f < RunState.choices.size() else {}
		if choice.has("left"):
			types.append(choice["left"])
		if choice.has("right") and choice["right"] != choice.get("left"):
			types.append(choice["right"])

	for type in types:
		var button := Button.new()
		button.text = "%s %s" % [GameData.ICONS.get(type, ""), GameData.NAMES.get(type, type)]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(96, 0)
		button.add_theme_font_override("font", UITheme.font_at("display", 600))
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", Color("ffe98a"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _opt_box(Color("ffd83a")))
		button.add_theme_stylebox_override("hover", _opt_box(Color.WHITE, Color("3a2600")))
		button.add_theme_stylebox_override("pressed", _opt_box(Color.WHITE, Color("3a2600")))
		button.pressed.connect(func(): game_chosen.emit(type, f))
		_options.add_child(button)

	# Position the stack to the node's right, nudged left near the right edge so
	# it never leaves the tower frame.
	_options.reset_size()
	await get_tree().process_frame
	if not is_instance_valid(_options):
		return
	var box := _options.size
	var x := center.x + CURRENT_RADIUS + 12.0
	if x + box.x > size.x:
		x = center.x - CURRENT_RADIUS - 12.0 - box.x
	var y := clampf(center.y - box.y * 0.5, 4.0, size.y - box.y - 4.0)
	_options.position = Vector2(x, y)


## The .tnode-opt look: near-black fill, bright gold rounded border, Cinzel text.
func _opt_box(border: Color, bg := Color(0.070, 0.043, 0.012, 0.96)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.set_corner_radius_all(8)
	s.content_margin_left = 9
	s.content_margin_right = 9
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	s.shadow_color = Color(0, 0, 0, 0.7)
	s.shadow_size = 4
	return s
