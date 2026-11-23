# Trophies screen: all twelve Trophies (D-023). Earned ones show in colour with a gold Trophy;
# ones not yet earned show grey with a lock and their goal, so the learner knows what to aim for.
extends ScreenBase  # Shared background, margins and column.

const CARD_SIZE := Vector2(310, 300)  # Each Trophy card, so three fit side by side.

var _cards: Array[PanelContainer] = []  # The twelve cards, in the order of Trophies.ALL.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	add_header("Trophies", "%d of %d earned" % [Save.records.trophies.size(), Trophies.ALL.size()])  # Back button, title and count.
	var scroll := ScrollContainer.new()  # Lets short phones scroll to the last row.
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Take the rest of the screen.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # Only up and down.
	column.add_child(scroll)  # Show it.
	var centre := CenterContainer.new()  # Keeps the grid in the middle.
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # As wide as the screen.
	scroll.add_child(centre)  # Put it in the scroll area.
	var grid := GridContainer.new()  # Three cards per row.
	grid.columns = 3  # Three columns.
	grid.add_theme_constant_override("h_separation", 24)  # Space between the columns.
	grid.add_theme_constant_override("v_separation", 24)  # Space between the rows.
	centre.add_child(grid)  # Put the grid in the middle.
	for i in range(Trophies.ALL.size()):  # Each Trophy, in order ...
		var trophy: Dictionary = Trophies.ALL[i]  # ... its id, name and goal,
		var card := _make_card(trophy, Save.records.has_trophy(trophy.id))  # ... earned or not,
		grid.add_child(card)  # ... shown in the grid,
		_cards.append(card)  # ... and remembered.
		UiKit.pop_in(card, 0.04 * i)  # Cards pop in one after another.


# Makes one Trophy card: earned = white with a gold Trophy; not yet earned = grey with a lock.
# Both show the name and the goal.
func _make_card(trophy: Dictionary, earned: bool) -> PanelContainer:
	var card := PanelContainer.new()  # The card.
	var style := UiKit.box(Palette.WHITE if earned else Palette.LOCKED, 40, 8)  # White when earned, grey when not.
	style.set_content_margin_all(14)  # Room inside the card.
	card.add_theme_stylebox_override("panel", style)  # Use this look.
	card.custom_minimum_size = CARD_SIZE  # Its size.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Cards are not buttons.
	var lines := VBoxContainer.new()  # Picture, name and goal, top to bottom.
	lines.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	lines.add_theme_constant_override("separation", 4)  # Close together.
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	card.add_child(lines)  # Put them on the card.
	var picture := UiKit.icon(UiKit.Icon.TROPHY if earned else UiKit.Icon.LOCK, 100)  # A gold Trophy, or a lock.
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	lines.add_child(picture)  # Add it.
	lines.add_child(_wrapped(trophy.name, 38, Palette.INK))  # The Trophy's name.
	lines.add_child(_wrapped(trophy.goal, 28, Palette.BLUE if earned else Palette.INK))  # Its goal.
	return card  # Hand back the card.


# Makes a centred label that wraps onto more lines when the words are long, to fit a card.
func _wrapped(text: String, size: int, colour: Color) -> Label:
	var node := UiKit.label(text, size, colour)  # The label.
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap between words.
	node.custom_minimum_size.x = CARD_SIZE.x - 36.0  # As wide as the card's inside.
	return node  # Hand it back.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
