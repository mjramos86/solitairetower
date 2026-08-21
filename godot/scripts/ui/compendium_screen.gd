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

## Page prose colour, matching .compendium-page { color:#f0ede5 }.
const PAGE_TEXT := Color("f0ede5")

@onready var _list: VBoxContainer = $Margin/Center/Frame/Col/Layout/Nav/Scroll/List
@onready var _page: VBoxContainer = $Margin/Center/Frame/Col/Layout/Page/Scroll/Content
@onready var _credits: Label = $Margin/Center/Frame/Col/Credits/CreditsLabel
@onready var _title: Label = $Margin/Center/Frame/Col/TitleBar/Bar/Title
@onready var _close_button: Button = $Margin/Center/Frame/Col/TitleBar/Bar/Close
@onready var _frame: PanelContainer = $Margin/Center/Frame
@onready var _titlebar: PanelContainer = $Margin/Center/Frame/Col/TitleBar
@onready var _credits_panel: PanelContainer = $Margin/Center/Frame/Col/Credits
@onready var _nav: PanelContainer = $Margin/Center/Frame/Col/Layout/Nav

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

	_style_chrome()
	_close_button.pressed.connect(func(): RunState.set_screen("map"))
	_refresh()


## Gold-framed occult panel with a Playfair gradient titlebar, banked-credits
## strip and right-divided nav — ported from the .compendium-* CSS.
func _style_chrome() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = UITheme.BG_PANEL
	frame.set_border_width_all(2)
	frame.border_color = UITheme.GOLD_DIM
	frame.set_corner_radius_all(6)
	_frame.add_theme_stylebox_override("panel", frame)

	var bar := StyleBoxFlat.new()
	bar.bg_color = UITheme.W95_TITLEBAR2  # #2e2010, the gradient's light end
	bar.border_width_bottom = 2
	bar.border_color = UITheme.GOLD_DIM
	bar.corner_radius_top_left = 6
	bar.corner_radius_top_right = 6
	bar.content_margin_left = 20
	bar.content_margin_right = 16
	bar.content_margin_top = 12
	bar.content_margin_bottom = 12
	_titlebar.add_theme_stylebox_override("panel", bar)

	_title.add_theme_font_override("font", UITheme.font_at("title", 700))
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", UITheme.GOLD)

	_close_button.add_theme_stylebox_override("normal", _ghost_style(Color(0, 0, 0, 0), UITheme.GOLD_DIM))
	_close_button.add_theme_stylebox_override("hover", _ghost_style(Color(0.831, 0.659, 0.294, 0.1), UITheme.GOLD))
	_close_button.add_theme_stylebox_override("pressed", _ghost_style(Color(0.831, 0.659, 0.294, 0.1), UITheme.GOLD))
	_close_button.add_theme_color_override("font_color", UITheme.GOLD)
	_close_button.add_theme_color_override("font_hover_color", UITheme.GOLD)

	var cred := StyleBoxFlat.new()
	cred.bg_color = Color(0, 0, 0, 0)
	cred.border_width_bottom = 1
	cred.border_color = Color(0.831, 0.659, 0.294, 0.18)
	cred.content_margin_top = 10
	cred.content_margin_bottom = 10
	_credits_panel.add_theme_stylebox_override("panel", cred)
	_credits.add_theme_font_override("font", UITheme.font("pixel"))
	_credits.add_theme_font_size_override("font_size", 15)
	_credits.add_theme_color_override("font_color", UITheme.GOLD)

	var nav := StyleBoxFlat.new()
	nav.bg_color = Color(0, 0, 0, 0)
	nav.border_width_right = 1
	nav.border_color = Color(0.831, 0.659, 0.294, 0.18)
	nav.content_margin_left = 10
	nav.content_margin_right = 10
	nav.content_margin_top = 14
	nav.content_margin_bottom = 14
	_nav.add_theme_stylebox_override("panel", nav)


func _ghost_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(5)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


func _entry_unlocked(entry: Dictionary) -> bool:
	# The web build shows an entry (not the silhouette) when it is flagged
	# unlocked OR revealed: `if(!p.revealed && !p.unlocked) locked`.
	return bool(entry.get("unlocked", false)) or _entry_revealed(entry)


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
		_style_nav_item(button, i == _selected)
		_list.add_child(button)

	_build_page()


## Cinzel nav entry: transparent normally, gold-outlined when active — the
## .compendium-nav-item / .active rules.
func _style_nav_item(button: Button, active: bool) -> void:
	button.add_theme_font_override("font", UITheme.font_at("display", 500))
	button.add_theme_font_size_override("font_size", 14)
	var fg := UITheme.GOLD if active else UITheme.TEXT
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_hover_color", UITheme.GOLD)
	button.add_theme_color_override("font_pressed_color", UITheme.GOLD)

	var normal := _nav_item_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0))
	if active:
		normal = _nav_item_style(Color(0.831, 0.659, 0.294, 0.14), UITheme.GOLD)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _nav_item_style(Color(0.831, 0.659, 0.294, 0.1), Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("pressed", _nav_item_style(Color(0.831, 0.659, 0.294, 0.14), UITheme.GOLD))


func _nav_item_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _build_page() -> void:
	for child in _page.get_children():
		child.queue_free()

	if _selected < 0 or _selected >= _entries.size():
		return
	var entry: Dictionary = _entries[_selected]

	var title := Label.new()
	title.add_theme_font_override("font", UITheme.font_at("title", 700))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", UITheme.GOLD)

	if not _entry_unlocked(entry):
		title.text = "Unknown Patron"
		_page.add_child(title)
		_add_paragraph("This Time Patron has not yet revealed themselves to you.")
		return

	title.text = _display_name(entry)
	_page.add_child(title)

	if bool(entry.get("in_development", false)):
		_add_dev_note()

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
	label.add_theme_color_override("font_color", PAGE_TEXT)
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
	_style_unlock_button(button)
	_page.add_child(button)


## Gold-outlined "uncover" button, the .compendium-unlock-btn rule.
func _style_unlock_button(button: Button) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", UITheme.GOLD)
	button.add_theme_color_override("font_hover_color", UITheme.GOLD)
	button.add_theme_color_override("font_pressed_color", UITheme.GOLD)
	button.add_theme_color_override("font_disabled_color", Color("555555"))
	button.add_theme_stylebox_override("normal", _unlock_style(Color(0.831, 0.659, 0.294, 0.1), Color(0.831, 0.659, 0.294, 0.4)))
	button.add_theme_stylebox_override("hover", _unlock_style(Color(0.831, 0.659, 0.294, 0.2), UITheme.GOLD))
	button.add_theme_stylebox_override("pressed", _unlock_style(Color(0.831, 0.659, 0.294, 0.2), UITheme.GOLD))
	button.add_theme_stylebox_override("disabled", _unlock_style(Color(0.2, 0.2, 0.2, 0.3), Color("333333")))


func _unlock_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(4)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


## In-development patrons show a note and cannot be selected or bought. Ported
## from the web build's devHTML — patron_unlock_cost exists in the data but its
## purchase flow was never implemented (tryUnlockPatron bails on inDevelopment),
## so there is deliberately no unlock button here.
func _add_dev_note() -> void:
	var note := Label.new()
	note.text = "⚙ This Time Patron is still in development and cannot yet be selected."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_page.add_child(note)
