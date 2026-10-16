extends Control

## The run's patron, watching the table from the bottom-right corner, who speaks
## up whenever the board refuses a move and names the rule that refused it.
##
## Why a portrait and not a toast: a refused move used to be a 200ms shake and
## nothing else, so a player who did not already know the rule learned nothing —
## the Spider deal that stops while a column is empty read as a broken button.
## The patron is already the run's framing device (they stock the shop and carry
## the story), so the explanation arrives in a voice the game has established
## rather than as a system message.
##
## Mounted as a sibling of the felt rather than a child of it: _rebuild() frees
## every child of the felt on each move, and the coach has to outlive that.
## A plain Control reports no minimum size of its own, so nothing here can push
## the board's layout around.

const PORTRAIT_W := 168.0
const PORTRAIT_H := 208.0
const BUBBLE_MAX_W := 560.0
## The How to play briefing is a paragraph, not a line, so it gets its own width.
const BRIEFING_W := 760.0
## The shop stands where the portrait does, so it is sized to sit comfortably in
## the same corner rather than to fill the felt.
const SHOP_W := 330.0
const EDGE := 18.0          # gap kept from the felt's bottom-right corner
const FADE := 0.18
## How long a line stays up: a floor, plus reading time per character, capped so
## a long line cannot sit over the table forever.
const DWELL_MIN := 3.2
const DWELL_PER_CHAR := 0.045
const DWELL_MAX := 7.0

## Variants whose briefing the player has already been handed, on the profile so
## it is remembered across runs and sessions.
const SEEN_BRIEFINGS := "seen_variant_briefings"

var _frame: PanelContainer
var _portrait: TextureRect
var _name_label: Label
var _tail: BubbleTail
var _bubble: PanelContainer
var _label: Label
var _tween: Tween
var _hide_timer: SceneTreeTimer
var _patron := ""
var _row: HBoxContainer
var _help_button: Button
var _mute_button: Button
var _shop_button: Button
## The shop stands in the portrait's place rather than beside it: the patron IS
## the shop, and the corner has no room for both.
var _shop_panel: VBoxContainer
var _shop_open := false
## A briefing stays up until it is dismissed; a reaction retires on its own.
var _sticky := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	set_patron(RunState.patron)
	# The language picker can be reached mid-run through the pause menu, and the
	# two button labels are the only text here that is not rebuilt on each line.
	Locale.changed.connect(_relabel)
	# Gold arrives while the stall is open, so what is affordable changes under
	# the player's eyes. Only redraws when the stall is actually showing.
	RunState.state_changed.connect(func():
		if _shop_open:
			_rebuild_shop())
	Locale.changed.connect(func():
		if _shop_open:
			_rebuild_shop())
	_show_mute_state(is_muted())


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_row = row
	# A corner preset bakes the offsets from the size the row has at the moment
	# it is applied, so applying it here (empty, zero-sized) would pin a zero-
	# sized rect to the corner and nothing would ever draw. It is re-applied
	# whenever the content or the felt changes size instead — see _place().
	row.minimum_size_changed.connect(_place)
	resized.connect(_place)

	# ── The bubble, to the left of the portrait, its tail pointing back at it ──
	_tail = BubbleTail.new()
	_tail.dir = "right"
	_tail.offset = 30.0
	_tail.apply_margin()
	_tail.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Transparent to the board while a reaction is up, clickable while a briefing
	# is: the panel covers part of the felt, so it must be dismissable by the
	# obvious gesture and not only by the button that opened it.
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tail.gui_input.connect(_on_bubble_input)
	_tail.modulate.a = 0.0
	_tail.visible = false
	row.add_child(_tail)

	_bubble = PanelContainer.new()
	var bubble_box := StyleBoxFlat.new()
	bubble_box.bg_color = Color.WHITE
	bubble_box.border_width_left = 3
	bubble_box.border_width_top = 3
	bubble_box.border_width_right = 3
	bubble_box.border_width_bottom = 3
	bubble_box.border_color = Color.BLACK
	bubble_box.shadow_color = Color(0, 0, 0, 0.55)
	bubble_box.shadow_size = 5
	# The hard comic shadow falls away from the tail, not across it: a shadow
	# offset to the right would be painted over the triangle (the bubble draws
	# after the tail it sits in) and split the tail off the bubble.
	bubble_box.shadow_offset = Vector2(-5, 5)
	bubble_box.content_margin_left = 20
	bubble_box.content_margin_right = 20
	bubble_box.content_margin_top = 16
	bubble_box.content_margin_bottom = 16
	_bubble.add_theme_stylebox_override("panel", bubble_box)
	_bubble.custom_minimum_size.x = BUBBLE_MAX_W
	_tail.add_child(_bubble)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("font", UITheme.font("body"))  # spoken prose → Inter
	_label.add_theme_font_size_override("font_size", 21)
	_label.add_theme_color_override("font_color", Color.BLACK)
	_bubble.add_child(_label)

	# ── The portrait, framed like the rest of the Windows-95 chrome ──
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.size_flags_vertical = Control.SIZE_SHRINK_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	# Two controls sit above the portrait: the briefing on demand, and the switch
	# that silences everything the patron says unasked.
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)

	_help_button = _corner_button("HOW TO PLAY")
	_help_button.pressed.connect(_on_help_pressed)
	buttons.add_child(_help_button)

	_shop_button = _corner_button("SHOP")
	_shop_button.toggle_mode = true
	_shop_button.toggled.connect(_on_shop_toggled)
	buttons.add_child(_shop_button)

	_mute_button = _corner_button("MUTE")
	# The W95 theme draws a held-down toggle sunken, but at this size that alone
	# is too quiet to read as state, so the label names the state too and the
	# portrait dims with it.
	_mute_button.toggle_mode = true
	_mute_button.button_pressed = is_muted()
	_mute_button.toggled.connect(_on_mute_toggled)
	buttons.add_child(_mute_button)

	_frame = PanelContainer.new()
	_frame.add_theme_stylebox_override("panel",
		UITheme.bevel_raised(UITheme.W95_BG, Vector2(4, 4)))
	column.add_child(_frame)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(PORTRAIT_W, PORTRAIT_H)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_portrait)

	_shop_panel = VBoxContainer.new()
	_shop_panel.add_theme_constant_override("separation", 6)
	_shop_panel.custom_minimum_size.x = SHOP_W
	_shop_panel.visible = false
	_frame.add_child(_shop_panel)

	var strip := PanelContainer.new()
	var strip_box := StyleBoxFlat.new()
	strip_box.bg_color = UITheme.W95_TITLEBAR1
	strip_box.border_width_left = 2
	strip_box.border_width_right = 2
	strip_box.border_width_bottom = 2
	strip_box.border_color = UITheme.W95_DARKER
	strip_box.content_margin_left = 6
	strip_box.content_margin_right = 6
	strip_box.content_margin_top = 3
	strip_box.content_margin_bottom = 3
	strip.add_theme_stylebox_override("panel", strip_box)
	column.add_child(strip)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_override("font", UITheme.font("pixel"))
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.add_theme_color_override("font_color", UITheme.GOLD)
	strip.add_child(_name_label)

	_place.call_deferred()


## Opens or closes the patron's stall. The portrait steps aside for it, and the
## briefing bubble is put away — the two compete for the same corner and for the
## player's attention.
func _on_shop_toggled(open: bool) -> void:
	_shop_open = open
	if open:
		hide_line()
	_portrait.visible = not open
	_shop_panel.visible = open
	if open:
		_rebuild_shop()
	_place.call_deferred()


## Redraws the stall from RunState. Called on open and after every purchase or
## reroll, because both change what is on offer and what the player can afford.
func _rebuild_shop() -> void:
	for child in _shop_panel.get_children():
		child.queue_free()
	if not _shop_open:
		return

	var purse := Label.new()
	purse.text = Locale.t("⏳ %d · %d left") % [RunState.gold, RunState.shop_buys_left()]
	purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purse.add_theme_font_override("font", UITheme.font("pixel"))
	purse.add_theme_font_size_override("font_size", 16)
	purse.add_theme_color_override("font_color", UITheme.GOLD_PILL_TEXT)
	_shop_panel.add_child(purse)

	if RunState.shop_buys_left() <= 0 or RunState.shop_items.is_empty():
		var done := Label.new()
		done.text = Locale.t("The patron has nothing left for you this floor.")
		done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		done.add_theme_font_override("font", UITheme.font("body"))
		done.add_theme_font_size_override("font_size", 15)
		done.add_theme_color_override("font_color", UITheme.W95_DARKER)
		_shop_panel.add_child(done)
		return

	for item in RunState.shop_items:
		_shop_panel.add_child(_offer_button(item))

	var reroll := Button.new()
	reroll.text = Locale.t("⟳ Reroll (%d)") % GameData.REROLL_COST
	reroll.focus_mode = Control.FOCUS_NONE
	reroll.add_theme_font_override("font", UITheme.font("pixel"))
	reroll.add_theme_font_size_override("font_size", 15)
	reroll.disabled = RunState.gold < GameData.REROLL_COST
	reroll.pressed.connect(func():
		if RunState.shop_reroll():
			AudioManager.card_taken()
			_rebuild_shop()
			_place.call_deferred())
	_shop_panel.add_child(reroll)


## One offer: its glyph, its name and its price, as a single button. Disabled —
## rather than hidden — when it cannot be afforded, so the player can see what
## they are saving toward.
func _offer_button(item: Dictionary) -> Button:
	var price := int(item.get("price", 0))
	var button := Button.new()
	button.text = "%s %s\n⏳ %d" % [item.get("icon", ""),
		Locale.t(String(item.get("name", ""))), price]
	button.focus_mode = Control.FOCUS_NONE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 16)
	button.tooltip_text = Locale.t(String(item.get("desc", "")))
	button.disabled = RunState.gold < price \
		or RunState.inventory.size() >= GameData.INVENTORY_SLOTS
	button.pressed.connect(func():
		if RunState.shop_buy(item):
			AudioManager.card_moved()
			_rebuild_shop()
			_place.call_deferred())
	return button


## The three cues that the patron is silenced: a sunken switch, a label naming
## the state rather than the action, and a portrait that has stepped back.
func _show_mute_state(muted: bool) -> void:
	_mute_button.text = Locale.t("MUTED") if muted else Locale.t("MUTE")
	_portrait.modulate = Color(1, 1, 1, 0.55) if muted else Color.WHITE


## Re-applies the button labels in the current language.
func _relabel() -> void:
	_help_button.text = Locale.t("HOW TO PLAY")
	_show_mute_state(is_muted())
	# set_patron short-circuits on an unchanged id, so clear it to force the name
	# strip (one patron is known by a translated alias) through the new map.
	_patron = ""
	set_patron(RunState.patron)


## A small Windows-95 button sized for the corner; the theme supplies the bevel.
func _corner_button(label: String) -> Button:
	var button := Button.new()
	button.text = Locale.t(label)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	return button


## Whether the patron's unasked commentary is switched off. Stored on the
## profile, so it survives the run and the session.
func is_muted() -> bool:
	return bool(SaveManager.profile.get("patron_coach_muted", false))


func _on_mute_toggled(pressed: bool) -> void:
	SaveManager.profile["patron_coach_muted"] = pressed
	SaveManager.mark_dirty()
	_show_mute_state(pressed)
	# Silence takes effect at once, but never swallows a briefing the player
	# asked for and is still reading.
	if pressed and not _sticky:
		hide_line()


## Opens the briefing unasked, the first time a profile meets a variant. The
## always-on rules strip above the board used to teach this passively; with it
## gone, a player who has never seen Spider should be handed the rules rather
## than left to notice a small button in the corner.
##
## A muted patron stays quiet — an unasked briefing is exactly what muting is
## for — and the variant is left unseen, so the briefing is still waiting if the
## player switches the patron back on.
func offer_briefing(type: String) -> void:
	if type.is_empty() or is_muted() or SaveManager.has_seen(SEEN_BRIEFINGS, type):
		return
	var text := Coach.how_to_play(type)
	if text.is_empty():
		return
	SaveManager.mark_seen(SEEN_BRIEFINGS, type)
	_speak(text, true)


## The whole rulebook for the variant in play. Asked for, so it ignores the mute
## switch; pressing again puts it away.
## A click anywhere on an open briefing puts it away.
func _on_bubble_input(event: InputEvent) -> void:
	if _sticky and event is InputEventMouseButton and event.pressed:
		hide_line()


func _on_help_pressed() -> void:
	if _sticky:
		hide_line()
		return
	var type := String(RunState.gs.get("type", ""))
	_speak(Coach.how_to_play(type), true)


## Re-pins the portrait (and whatever bubble is open) to the felt's bottom-right
## corner at its current size. Deferred by its callers so the row has already
## recomputed its minimum size when the offsets are taken from it.
func _place() -> void:
	if _row == null:
		return
	_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT,
		Control.PRESET_MODE_MINSIZE, int(EDGE))


## Points the frame at a patron by id. Falls back to the first portrait in the
## compendium, so a patron added to the data without art still shows a face.
func set_patron(id: String) -> void:
	if id == _patron:
		return
	_patron = id
	var entry := {}
	for p in Narrative.PATRONS:
		if String(p.get("id", "")) == id:
			entry = p
			break
	var img := String(entry.get("img", ""))
	if img.is_empty() or not ResourceLoader.exists(img):
		img = String(Narrative.PATRONS[0]["img"])
		if entry.is_empty():
			entry = Narrative.PATRONS[0]
	_portrait.texture = load(img)
	var shown := String(entry.get("name", ""))
	if entry.has("true_name") and SaveManager.is_patron_revealed(String(entry.get("id", ""))):
		shown = String(entry["true_name"])
	_name_label.text = Locale.t(shown).to_upper()


## A reaction to something the board refused. Silenced by the mute switch. It
## replaces an open briefing rather than queueing behind it: once the player is
## moving cards again, live feedback is worth more than the rulebook they left
## open. Re-saying while a line is up restarts the dwell, so a player mashing an
## illegal move sees one steady bubble rather than a flicker.
func say(text: String) -> void:
	if is_muted():
		return
	_speak(text, false)


## Puts a line in the bubble. `sticky` keeps it there until it is dismissed —
## the briefing — instead of retiring it after a reading pause.
func _speak(text: String, sticky: bool) -> void:
	if text.strip_edges().is_empty():
		hide_line()
		return
	_sticky = sticky
	_bubble.custom_minimum_size.x = BRIEFING_W if sticky else BUBBLE_MAX_W
	_tail.mouse_filter = Control.MOUSE_FILTER_STOP if sticky else Control.MOUSE_FILTER_IGNORE
	set_patron(RunState.patron)
	_label.text = Locale.t(text)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tail.visible = true
	_place.call_deferred()
	_tail.pivot_offset = Vector2(_tail.size.x, _tail.size.y * 0.5)
	_tween = create_tween().set_parallel()
	_tween.tween_property(_tail, "modulate:a", 1.0, FADE)
	_tween.tween_property(_tail, "scale", Vector2.ONE, FADE) \
		.from(Vector2(0.92, 0.92)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if sticky:
		return
	var dwell := clampf(DWELL_MIN + _label.text.length() * DWELL_PER_CHAR, DWELL_MIN, DWELL_MAX)
	_hide_timer = get_tree().create_timer(dwell)
	_hide_timer.timeout.connect(_on_dwell_done.bind(_label.text))


func _on_dwell_done(spoken: String) -> void:
	# Only retire the line that armed this timer; a newer one has its own.
	if _label.text == spoken and not _sticky:
		hide_line()


func hide_line() -> void:
	_sticky = false
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _tail.visible:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_tail, "modulate:a", 0.0, FADE)
	_tween.tween_callback(func():
		_tail.visible = false
		_place.call_deferred())
