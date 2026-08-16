extends Control

## The compendium: patron biographies, lore entries, and the connections between
## them, bought with banked Time Energy. Ported from the compendium section of
## index.html.
##
## Entries are PATRONS + LORE. An entry can be:
##   locked     silhouette only, shown as a "?" with its year
##   unlocked   name, portrait and bio readable
##   revealed   the true name replaces the alias (Mary, Queen of Scots)
##
## Two purchases exist, both paid from the profile's banked credits, which now
## persist locally for every player rather than only for signed-in accounts:
##   connection_cost      reveals an entry's `lore` — its link to Solitaire
##   patron_unlock_cost   unlocks an in-development patron entirely

@onready var _list: VBoxContainer = $Panel/Layout/Nav/Scroll/List
@onready var _page: VBoxContainer = $Panel/Layout/Page/Scroll/Content
@onready var _credits: Label = $Panel/Header/Credits
@onready var _close_button: Button = $Panel/Header/Close

var _entries: Array = []
var _selected := 0


func _ready() -> void:
	_entries = []
	for p in Narrative.PATRONS:
		_entries.append(p)
	for l in Narrative.LORE:
		_entries.append(l)
	# Chronological, as the web build's timeline presented them.
	_entries.sort_custom(func(a, b): return int(a.get("year", 0)) < int(b.get("year", 0)))

	_close_button.pressed.connect(func(): RunState.set_screen("map"))
	_refresh()


func _entry_unlocked(entry: Dictionary) -> bool:
	if bool(entry.get("unlocked", false)):
		return true
	return SaveManager.has_seen("unlocked_patrons", String(entry["id"]))


func _entry_revealed(entry: Dictionary) -> bool:
	if bool(entry.get("revealed", false)):
		return true
	return SaveManager.is_patron_revealed(String(entry["id"]))


func _lore_unlocked(entry: Dictionary) -> bool:
	return SaveManager.has_seen("unlocked_connections", String(entry["id"]))


func _display_name(entry: Dictionary) -> String:
	if _entry_revealed(entry) and entry.has("true_name"):
		return String(entry["true_name"])
	return String(entry["name"])


## John Dee's link to Solitaire only becomes purchasable after his third
## transmission, matching connectionAvailable in the web build.
func _connection_available(entry: Dictionary) -> bool:
	if String(entry["id"]) == "johndee":
		return bool(SaveManager.profile.get("dee_dialogue3_done", false))
	return true


func _refresh() -> void:
	_credits.text = "⚡ %d Time Energy" % int(SaveManager.profile.get("banked_credits", 0))

	for child in _list.get_children():
		child.queue_free()

	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var button := Button.new()
		if _entry_unlocked(entry):
			button.text = "%d  %s" % [int(entry.get("year", 0)), _display_name(entry)]
		else:
			button.text = "%d  ???" % int(entry.get("year", 0))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func():
			_selected = i
			_refresh())
		if i == _selected:
			button.add_theme_color_override("font_color", UITheme.GOLD)
		_list.add_child(button)

	_build_page()


func _build_page() -> void:
	for child in _page.get_children():
		child.queue_free()

	if _selected < 0 or _selected >= _entries.size():
		return
	var entry: Dictionary = _entries[_selected]

	var title := Label.new()
	title.add_theme_font_override("font", UITheme.font_at("display", 700))
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", UITheme.GOLD)

	if not _entry_unlocked(entry):
		title.text = "Unknown — %d" % int(entry.get("year", 0))
		_page.add_child(title)
		_add_paragraph("This figure has not yet surfaced in your descent.")
		_maybe_offer_patron_unlock(entry)
		return

	title.text = _display_name(entry)
	_page.add_child(title)

	if entry.has("img"):
		var portrait := TextureRect.new()
		portrait.texture = load(String(entry["img"]))
		portrait.custom_minimum_size = Vector2(0, 260)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_page.add_child(portrait)

	for para in entry.get("bio", []):
		_add_paragraph(String(para))

	# Lore entries carry an extra titled section rather than a connection.
	if entry.has("strategy"):
		_add_heading(String(entry.get("strategy_title", "Strategy")))
		for para in entry["strategy"]:
			_add_paragraph(String(para))

	if entry.has("lore"):
		_add_connection_section(entry)

	_maybe_offer_patron_unlock(entry)


func _add_heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", UITheme.GOLD)
	_page.add_child(label)


func _add_paragraph(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UITheme.font("body"))
	label.add_theme_font_size_override("font_size", 18)
	_page.add_child(label)


func _add_connection_section(entry: Dictionary) -> void:
	_add_heading("Connection to Solitaire")

	if _lore_unlocked(entry):
		for para in entry["lore"]:
			_add_paragraph(String(para))
		return

	if not _connection_available(entry):
		_add_paragraph("This thread is not yet visible to you. Keep descending.")
		return

	var cost := int(entry.get("connection_cost", 500))
	_add_paragraph("This thread can be uncovered for %d Time Energy." % cost)

	var button := Button.new()
	var banked := int(SaveManager.profile.get("banked_credits", 0))
	button.text = "UNCOVER (%d ⚡)" % cost if banked >= cost \
		else "NEED %d MORE ⚡" % (cost - banked)
	button.disabled = banked < cost
	button.pressed.connect(func():
		if SaveManager.spend_banked_credits(cost):
			SaveManager.mark_seen("unlocked_connections", String(entry["id"]))
			SaveManager.save_game()
			RunState.toast.emit("A thread comes loose.")
			_refresh())
	_page.add_child(button)


## In-development patrons can be bought outright, which also reveals their name.
func _maybe_offer_patron_unlock(entry: Dictionary) -> void:
	if _entry_unlocked(entry) and _entry_revealed(entry):
		return
	if not entry.has("patron_unlock_cost"):
		return

	var cost := int(entry["patron_unlock_cost"])
	var banked := int(SaveManager.profile.get("banked_credits", 0))
	_add_paragraph("This patron can be brought forward for %d Time Energy." % cost)

	var button := Button.new()
	button.text = "UNCOVER PATRON (%d ⚡)" % cost if banked >= cost \
		else "NEED %d MORE ⚡" % (cost - banked)
	button.disabled = banked < cost
	button.pressed.connect(func():
		if SaveManager.spend_banked_credits(cost):
			SaveManager.mark_seen("unlocked_patrons", String(entry["id"]))
			SaveManager.reveal_patron(String(entry["id"]))
			SaveManager.save_game()
			RunState.toast.emit("A name surfaces.")
			_refresh())
	_page.add_child(button)
