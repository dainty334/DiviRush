# Trophies screen (D-023, D-030), with two tabs:
#   Trophies  all 26 Trophies, each with its own picture (D-031). Earned ones show in colour; ones not
#             yet earned show their picture in grey with a small lock, and their goal. Tapping one opens
#             its card: its name, its goal, and the day it was earned, or how far along the learner is.
#             They come 12 to a page, turned with the arrows and "1 / 3" under the grid (D-032).
#   Records   the learner's game records (before D-030, the My Records screen).
extends ScreenBase  # Shared background, margins and column.

const CARD_SIZE := Vector2(310, 280)  # Each Trophy card, so three fit side by side and four rows fit the screen (D-032).
const PER_PAGE := 12  # Trophies on one page: three columns and four rows (D-032).
const TAB_NAMES: Array[String] = ["Trophies", "Records"]  # The two tabs, in order.
const TAB_SIZE := Vector2(440, 120)  # Each tab button.

var _cards: Array[Button] = []  # The twelve Trophy cards, in the order of Trophies.ALL.
var _tabs: Array[Button] = []  # The Trophies and Records tab buttons.
var _pages: Array[Control] = []  # What each tab shows: the Trophy grid, then the Records.
var _trophy_card: Control  # The card of the Trophy tapped last; made when a Trophy is tapped.
var _trophy_ok: Button  # The OK button that closes that card.
var _grids: Array[GridContainer] = []  # One grid of up to 12 Trophies per page (D-032).
var _pager: Pager  # The arrows and "1 / 3" under the grid.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	add_header("Trophies", "%d of %d earned" % [Save.records.trophies.size(), Trophies.ALL.size()])  # Back button, title and count.
	column.add_child(_make_tab_row())  # The Trophies and Records tabs.
	_pages.append(_make_trophy_page())  # The twelve Trophies.
	_pages.append(_make_page(RecordsView.new()))  # The game records.
	show_tab(0)  # Open on the Trophies.


# Makes the row of two tab buttons, Trophies and Records.
func _make_tab_row() -> HBoxContainer:
	var row := HBoxContainer.new()  # The tabs side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.add_theme_constant_override("separation", 24)  # Space between them.
	for i in range(TAB_NAMES.size()):  # Each tab ...
		var tab := UiKit.button(TAB_NAMES[i], Palette.WHITE, TAB_SIZE, 56)  # ... a chunky button,
		tab.pressed.connect(show_tab.bind(i))  # ... that shows its page,
		row.add_child(tab)  # ... in the row,
		_tabs.append(tab)  # ... remembered.
	return row  # Hand back the row.


# Shows one tab's page and hides the other; the open tab is yellow, the other white.
func show_tab(index: int) -> void:
	for i in range(_pages.size()):  # Each page ...
		_pages[i].visible = i == index  # ... shows only when its tab is open.
		UiKit.style_button(_tabs[i], Palette.YELLOW if i == index else Palette.WHITE)  # The open tab is yellow.


# Puts a page's content in a scroll area under the tabs, so short phones can scroll, and returns it.
func _make_page(content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()  # Scrolls up and down.
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Take the rest of the screen.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # Only up and down.
	column.add_child(scroll)  # Show it.
	scroll.add_child(content)  # Put the content in it.
	return scroll  # Hand it back.


# Makes the Trophies page (D-032): the Trophies 12 at a time, in a grid of three columns and four
# rows, with the arrows and "1 / 3" under it. All the cards are made at once; the arrows show one grid.
func _make_trophy_page() -> VBoxContainer:
	var page := VBoxContainer.new()  # The grids above the arrows.
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Take the rest of the screen.
	page.add_theme_constant_override("separation", 24)  # Space above the arrows.
	column.add_child(page)  # Show it.
	var centre := CenterContainer.new()  # Keeps the grid in the middle.
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL  # The arrows sit at the bottom.
	page.add_child(centre)  # Add it.
	var page_count := ceili(Trophies.ALL.size() / float(PER_PAGE))  # 26 Trophies make 3 pages.
	for p in range(page_count):  # Each page ...
		var grid := GridContainer.new()  # ... its own grid,
		grid.columns = 3  # ... of three columns,
		grid.add_theme_constant_override("h_separation", 24)  # ... with space between the columns,
		grid.add_theme_constant_override("v_separation", 24)  # ... and between the rows.
		grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # Stay at the top when a page is short.
		centre.add_child(grid)  # All grids share the same place; one shows at a time.
		_grids.append(grid)  # Remember it.
	for i in range(Trophies.ALL.size()):  # Each Trophy, in order ...
		var trophy: Dictionary = Trophies.ALL[i]  # ... its id, name and goal,
		var card := _make_card(trophy, Save.records.has_trophy(trophy.id))  # ... earned or not,
		card.pressed.connect(_open_trophy.bind(i))  # ... opens its card when tapped,
		_grids[floori(i / float(PER_PAGE))].add_child(card)  # ... shown in its page's grid,
		_cards.append(card)  # ... and remembered.
		UiKit.pop_in(card, 0.04 * (i % PER_PAGE))  # Cards pop in one after another on each page.
	_pager = Pager.new(page_count)  # The arrows and "1 / 3".
	_pager.page_changed.connect(_show_trophy_page)  # Show the page they choose.
	page.add_child(_pager)  # Under the grid.
	_show_trophy_page(0)  # Start on page 1.
	return page  # Hand back the page.


# Shows one page of Trophies and hides the others.
func _show_trophy_page(index: int) -> void:
	for p in range(_grids.size()):  # Each page's grid ...
		_grids[p].visible = p == index  # ... shows only when chosen.


# Makes one Trophy card button: earned = white with a gold Trophy; not yet earned = grey with a lock.
# Both show the name and the goal.
func _make_card(trophy: Dictionary, earned: bool) -> Button:
	var card := UiKit.card_button(Palette.WHITE if earned else Palette.LOCKED, CARD_SIZE, 40)  # White when earned, grey when not.
	var lines := VBoxContainer.new()  # Picture, name and goal, top to bottom.
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the card ...
	lines.offset_left = 14  # ... with room at the left,
	lines.offset_right = -14  # ... and at the right.
	lines.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	lines.add_theme_constant_override("separation", 4)  # Close together.
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the card.
	card.add_child(lines)  # Put them on the card.
	var picture := UiKit.trophy_picture(trophy.id, 104, earned)  # Its own picture; grey with a lock until earned (D-031).
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	lines.add_child(picture)  # Add it.
	lines.add_child(_wrapped(trophy.name, 38, Palette.INK, CARD_SIZE.x - 36.0))  # The Trophy's name.
	lines.add_child(_wrapped(trophy.goal, 28, Palette.BLUE if earned else Palette.INK, CARD_SIZE.x - 36.0))  # Its goal.
	return card  # Hand back the card.


# Opens the card of one Trophy (D-030): the big Trophy or lock, its goal, and the day it was earned,
# or, for a Trophy not yet earned, how far along the learner is (for example "23 of 50 Stars").
func _open_trophy(index: int) -> void:
	var trophy: Dictionary = Trophies.ALL[index]  # The tapped Trophy.
	var earned := Save.records.has_trophy(trophy.id)  # Earned or not.
	var picture := UiKit.trophy_picture(trophy.id, 220, earned)  # Its own picture, big; grey with a lock until earned (D-031).
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	var goal := _wrapped(trophy.goal, 52, Palette.BLUE, 700.0)  # What earns it.
	var status_text := Trophies.date_text(Save.records.earned_date(trophy.id)) if earned else Trophies.progress_text(trophy.id, Save.progress, Save.records)  # The day, or how far along.
	var status := _wrapped(status_text, 48, Palette.GREEN.darkened(0.25) if earned else Palette.INK, 700.0)  # Green for earned, dark for not yet.
	_trophy_ok = UiKit.button("OK", Palette.GREEN, Vector2(500, 140))  # Closes the card.
	_trophy_ok.pressed.connect(close_trophy_card)  # Tapping OK closes it.
	if _trophy_card != null:  # A card from an earlier tap ...
		_trophy_card.queue_free()  # ... goes.
	_trophy_card = make_card(trophy.name, [picture, goal, status, _trophy_ok], 84)  # The same card look as the Exit card.
	add_child(_trophy_card)  # On top of the screen.
	_trophy_card.visible = true  # Show it.


# Returns true while a Trophy's card is showing.
func is_trophy_card_open() -> bool:
	return _trophy_card != null and _trophy_card.visible  # Made and showing.


# Hides the Trophy's card. Called by OK, and by Back while the card is open.
func close_trophy_card() -> void:
	if _trophy_card != null:  # A card was made ...
		_trophy_card.visible = false  # ... so hide it.


# Makes a centred label that wraps onto more lines when the words are long, to fit a card.
func _wrapped(text: String, size: int, colour: Color, width: float) -> Label:
	var node := UiKit.label(text, size, colour)  # The label.
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap between words.
	node.custom_minimum_size.x = width  # As wide as the card's inside.
	return node  # Hand it back.


# Android Back closes a Trophy's card first; otherwise it leaves the screen.
func back_pressed() -> void:
	if is_trophy_card_open():  # A card is showing ...
		close_trophy_card()  # ... so close it and stay.
	else:  # No card ...
		super.back_pressed()  # ... so go back as usual.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
