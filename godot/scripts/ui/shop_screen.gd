extends Control

## Between-floor shop, ported from renderShop + the `.shop-*` CSS in index.html.
## Three gold-framed "cabinet" windows — time-credit breakdown, the item stock,
## and the inventory — stacked in a centred 780px column over the occult felt.

# ── Palette lifted straight from the .shop-* / .gold-* CSS rules ──
const WIN_BG := Color(0.059, 0.039, 0.118, 0.9)          # rgba(15,10,30,.9)
const WIN_BORDER := Color(0.831, 0.659, 0.294, 0.25)     # rgba(212,168,75,.25)
const TITLEBAR_BG := Color(0.33, 0.19, 0.06, 1.0)        # brown gradient, flattened
const STAT_BG := Color(0.078, 0.055, 0.157, 0.7)         # rgba(20,14,40,.7)
const STAT_BORDER := Color(0.831, 0.659, 0.294, 0.2)     # rgba(212,168,75,.2)
const INV_BG := Color(0.078, 0.055, 0.157, 0.8)          # rgba(20,14,40,.8)
const INV_BORDER := Color(0.831, 0.659, 0.294, 0.25)     # rgba(212,168,75,.25)
const EARNED := Color("4dff91")
const LOCKED := Color("555555")
const BUY_BG := Color(0.831, 0.659, 0.294, 0.1)          # rgba(212,168,75,.1)
const BUY_BORDER := Color(0.831, 0.659, 0.294, 0.4)      # rgba(212,168,75,.4)
const DESC_DIM := Color("666666")
const BEST_DIM := Color("808080")

# tier foreground colours: t0 #4dff91, t1 #6db3f2, t2 gold, t3 #ff6b6b
const TIER_FG := [Color("4dff91"), Color("6db3f2"), UITheme.GOLD, Color("ff6b6b")]

@onready var _column: VBoxContainer = $Scroll/Pad/Center/Column


func _ready() -> void:
	RunState.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _column.get_children():
		_column.remove_child(child)
		child.queue_free()

	_build_credits_window()
	_build_items_window()
	_build_inventory_window()
	_build_continue_row()


# ── Window chrome ────────────────────────────────────────────────────────────

## A gold-framed cabinet window with a Cinzel titlebar. Returns the padded body
## VBox for callers to fill.
func _make_window(title: String) -> VBoxContainer:
	var win := PanelContainer.new()
	win.add_theme_stylebox_override("panel", _window_style())
	win.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	win.add_child(col)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _titlebar_style())
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_override("font", UITheme.font_at("display", 600))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", UITheme.GOLD)
	bar.add_child(lbl)
	col.add_child(bar)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	col.add_child(pad)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	pad.add_child(body)

	_column.add_child(win)
	return body


func _window_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = WIN_BG
	s.set_border_width_all(1)
	s.border_color = WIN_BORDER
	s.set_corner_radius_all(6)
	return s


func _titlebar_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = TITLEBAR_BG
	s.border_width_bottom = 1
	s.border_color = STAT_BORDER
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


# ── Time-credit breakdown ────────────────────────────────────────────────────

func _build_credits_window() -> void:
	var floor_num := RunState.floor_index
	var body := _make_window("⏳  Floor %d Cleared — Time Credits Awarded" % floor_num)

	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)

	for row in RunState.shop_gold_breakdown:
		var earned: bool = row["earned"]
		var amount := int(row["amount"])
		var val := ("+%d ⏳" % amount) if earned else "—"
		grid.add_child(_gold_stat(String(row["label"]), val, EARNED if earned else LOCKED))

	grid.add_child(_gold_stat("TOTAL EARNED", "+%d ⏳" % RunState.shop_gold_earned, UITheme.GOLD))
	grid.add_child(_gold_stat("YOUR BALANCE", "%d ⏳" % RunState.gold, UITheme.GOLD))


func _gold_stat(label: String, value: String, value_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stat_style())
	panel.custom_minimum_size = Vector2(120, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", UITheme.font("pixel"))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_override("font", UITheme.font("pixel"))
	val.add_theme_font_size_override("font_size", 22)
	val.add_theme_color_override("font_color", value_color)
	col.add_child(val)

	return panel


func _stat_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = STAT_BG
	s.set_border_width_all(1)
	s.border_color = STAT_BORDER
	s.set_corner_radius_all(4)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


# ── Item shop ────────────────────────────────────────────────────────────────

func _build_items_window() -> void:
	var body := _make_window("🏪  John Dee's Cabinet of Curiosities — %d Items Available" % RunState.shop_items.size())

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)

	for item in RunState.shop_items:
		grid.add_child(_build_item_card(item))


func _build_item_card(item: Dictionary) -> Control:
	var owned := false
	for held in RunState.inventory:
		if held["id"] == item["id"]:
			owned = true
	var full := RunState.inventory.size() >= GameData.INVENTORY_SLOTS
	var afford := RunState.gold >= int(item["price"])

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _item_style())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if owned:
		panel.modulate = Color(1, 1, 1, 0.3)
	elif not afford:
		panel.modulate = Color(1, 1, 1, 0.4)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var icon := Label.new()
	icon.text = String(item["icon"])
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 42)
	col.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = String(item["name"])
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", UITheme.font_at("display", 600))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", UITheme.GOLD)
	col.add_child(name_lbl)

	col.add_child(_tier_badge(int(item["tier"])))

	var price := Label.new()
	price.text = "%d ⏳" % int(item["price"])
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_override("font", UITheme.font("pixel"))
	price.add_theme_font_size_override("font_size", 20)
	price.add_theme_color_override("font_color", UITheme.GOLD)
	col.add_child(price)

	var desc := Label.new()
	desc.text = String(item["desc"])
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_override("font", UITheme.font("pixel"))
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(desc)

	var use := Label.new()
	use.text = "📋 %s" % String(item["use"])
	use.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	use.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	use.add_theme_font_override("font", UITheme.font("pixel"))
	use.add_theme_font_size_override("font_size", 12)
	use.add_theme_color_override("font_color", DESC_DIM)
	col.add_child(use)

	var best := Label.new()
	best.text = "Best for: %s" % String(item.get("best_for", ""))
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	best.add_theme_font_override("font", UITheme.font("pixel"))
	best.add_theme_font_size_override("font_size", 11)
	best.add_theme_color_override("font_color", BEST_DIM)
	col.add_child(best)

	var buy := Button.new()
	if owned:
		buy.text = "[ ALREADY OWNED ]"
	elif full:
		buy.text = "[ INVENTORY FULL ]"
	elif not afford:
		buy.text = "[ NEED %d MORE ⏳ ]" % (int(item["price"]) - RunState.gold)
	else:
		buy.text = "[ BUY ]"
	buy.disabled = owned or full or not afford
	_style_buy_button(buy)
	buy.pressed.connect(func(): _buy(item))
	col.add_child(buy)

	return panel


func _item_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = STAT_BG
	s.set_border_width_all(1)
	s.border_color = STAT_BORDER
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s


func _tier_badge(tier: int) -> Control:
	var fg: Color = TIER_FG[clampi(tier, 0, TIER_FG.size() - 1)]
	var badge := PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var s := StyleBoxFlat.new()
	s.bg_color = Color(fg.r, fg.g, fg.b, 0.08)
	s.set_border_width_all(1)
	s.border_color = Color(fg.r, fg.g, fg.b, 0.3)
	s.set_corner_radius_all(3)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", s)

	var lbl := Label.new()
	lbl.text = GameData.TIER_NAMES[clampi(tier, 0, GameData.TIER_NAMES.size() - 1)]
	lbl.add_theme_font_override("font", UITheme.font("pixel"))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", fg)
	badge.add_child(lbl)
	return badge


func _style_buy_button(buy: Button) -> void:
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.add_theme_font_override("font", UITheme.font("pixel"))
	buy.add_theme_font_size_override("font_size", 16)
	buy.add_theme_color_override("font_color", UITheme.GOLD)
	buy.add_theme_color_override("font_hover_color", UITheme.GOLD)
	buy.add_theme_color_override("font_pressed_color", UITheme.GOLD)
	buy.add_theme_color_override("font_disabled_color", LOCKED)

	buy.add_theme_stylebox_override("normal", _buy_style(BUY_BG, BUY_BORDER))
	buy.add_theme_stylebox_override("hover", _buy_style(Color(0.831, 0.659, 0.294, 0.25), BUY_BORDER))
	buy.add_theme_stylebox_override("pressed", _buy_style(Color(0.831, 0.659, 0.294, 0.25), BUY_BORDER))
	buy.add_theme_stylebox_override("disabled", _buy_style(Color(0.2, 0.2, 0.2, 0.3), Color("333333")))


func _buy_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(4)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


# ── Inventory ────────────────────────────────────────────────────────────────

func _build_inventory_window() -> void:
	var body := _make_window("🎒  Your Inventory (%d/%d slots)" % [RunState.inventory.size(), GameData.INVENTORY_SLOTS])

	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)

	for item in RunState.inventory:
		grid.add_child(_inv_card(item))
	for i in range(RunState.inventory.size(), GameData.INVENTORY_SLOTS):
		grid.add_child(_inv_empty())

	if RunState.inventory.size() >= GameData.INVENTORY_SLOTS:
		var warn := Label.new()
		warn.text = "⚠ Inventory full! Use or drop items in-game."
		warn.add_theme_font_override("font", UITheme.font("pixel"))
		warn.add_theme_font_size_override("font_size", 14)
		warn.add_theme_color_override("font_color", UITheme.MAROON)
		body.add_child(warn)


func _inv_card(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 0)
	var s := StyleBoxFlat.new()
	s.bg_color = INV_BG
	s.set_border_width_all(1)
	s.border_color = INV_BORDER
	s.set_corner_radius_all(4)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", s)

	var lbl := Label.new()
	lbl.text = "%s  %s" % [item["icon"], item["name"]]
	lbl.add_theme_font_override("font", UITheme.font("pixel"))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", UITheme.TEXT)
	panel.add_child(lbl)
	return panel


func _inv_empty() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 36)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.set_border_width_all(1)
	s.border_color = Color(0.831, 0.659, 0.294, 0.2)
	s.set_corner_radius_all(4)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", s)

	var lbl := Label.new()
	lbl.text = "[ empty ]"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", UITheme.font("pixel"))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", LOCKED)
	panel.add_child(lbl)
	return panel


# ── Continue row ─────────────────────────────────────────────────────────────

func _build_continue_row() -> void:
	var win := PanelContainer.new()
	win.add_theme_stylebox_override("panel", _window_style())
	win.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	win.add_child(margin)
	margin.add_child(row)

	var btn := Button.new()
	btn.text = "⚔  Continue to the Tower"
	_style_buy_button(btn)
	btn.custom_minimum_size = Vector2(260, 0)
	btn.pressed.connect(func(): RunState.set_screen("map"))
	row.add_child(btn)

	_column.add_child(win)


# ── Purchase ─────────────────────────────────────────────────────────────────

func _buy(item: Dictionary) -> void:
	if RunState.gold < int(item["price"]):
		return
	if RunState.inventory.size() >= GameData.INVENTORY_SLOTS:
		return
	RunState.gold -= int(item["price"])
	RunState.inventory.append(item)
	RunState.toast.emit("Acquired %s" % item["name"])
	RunState.state_changed.emit()
