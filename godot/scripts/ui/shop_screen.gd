extends Control

## Between-floor shop. Shows the time credits earned for the floor just cleared,
## three purchasable items, and the inventory. Ported from renderShop.

@onready var _breakdown: VBoxContainer = $Scroll/Body/Credits/Rows
@onready var _items: HBoxContainer = $Scroll/Body/Items/Grid
@onready var _inventory: HBoxContainer = $Scroll/Body/Inventory/Slots
@onready var _balance: Label = $Scroll/Body/Credits/Balance
@onready var _continue_button: Button = $Scroll/Body/Continue


func _ready() -> void:
	_continue_button.pressed.connect(func(): RunState.set_screen("map"))
	RunState.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _breakdown.get_children():
		child.queue_free()
	for row in RunState.shop_gold_breakdown:
		var line := HBoxContainer.new()
		var label := Label.new()
		label.text = String(row["label"])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
		var value := Label.new()
		var earned: bool = row["earned"]
		value.text = ("+%d ⏳" % int(row["amount"])) if earned else "—"
		value.add_theme_color_override("font_color", UITheme.GOLD if earned else UITheme.TEXT_DIM)
		line.add_child(value)
		_breakdown.add_child(line)

	_balance.text = "Earned +%d ⏳     Balance %d ⏳" % [RunState.shop_gold_earned, RunState.gold]

	for child in _items.get_children():
		child.queue_free()
	for item in RunState.shop_items:
		_items.add_child(_build_item_card(item))

	for child in _inventory.get_children():
		child.queue_free()
	for item in RunState.inventory:
		var owned := Label.new()
		owned.text = "%s %s" % [item["icon"], item["name"]]
		_inventory.add_child(owned)
	for i in range(RunState.inventory.size(), GameData.INVENTORY_SLOTS):
		var empty := Label.new()
		empty.text = "[ empty ]"
		empty.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_inventory.add_child(empty)


func _build_item_card(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.occult_panel())
	panel.custom_minimum_size = Vector2(260, 0)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	var title := Label.new()
	title.text = "%s  %s" % [item["icon"], item["name"]]
	title.add_theme_font_override("font", UITheme.font_at("display", 700))
	title.add_theme_color_override("font_color", UITheme.GOLD)
	col.add_child(title)

	var tier := Label.new()
	tier.text = "%s · %d ⏳" % [GameData.TIER_NAMES[item["tier"]], int(item["price"])]
	tier.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	col.add_child(tier)

	var desc := Label.new()
	desc.text = String(item["desc"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc)

	var owned := false
	for held in RunState.inventory:
		if held["id"] == item["id"]:
			owned = true

	var full := RunState.inventory.size() >= GameData.INVENTORY_SLOTS
	var afford := RunState.gold >= int(item["price"])

	var buy := Button.new()
	if owned:
		buy.text = "[ OWNED ]"
	elif full:
		buy.text = "[ INVENTORY FULL ]"
	elif not afford:
		buy.text = "[ NEED %d MORE ]" % (int(item["price"]) - RunState.gold)
	else:
		buy.text = "[ BUY ]"
	buy.disabled = owned or full or not afford
	buy.pressed.connect(func(): _buy(item))
	col.add_child(buy)

	return panel


func _buy(item: Dictionary) -> void:
	if RunState.gold < int(item["price"]):
		return
	if RunState.inventory.size() >= GameData.INVENTORY_SLOTS:
		return
	RunState.gold -= int(item["price"])
	RunState.inventory.append(item)
	RunState.toast.emit("Acquired %s" % item["name"])
	RunState.state_changed.emit()
