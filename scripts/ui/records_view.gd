# The Records tab of the Trophies screen (D-023, D-030, D-032): the learner's game records as six
# big colour tiles (an icon, a big number and a short name each), and "Stars in each Episode", one
# row per Episode in its world colour. They are records of play, not grades, so there are no
# percentages or marks (Chapter 1). Before D-030 this was the My Records screen.
class_name RecordsView  # Lets the Trophies screen write RecordsView.new().
extends VBoxContainer  # The tiles above the Episode card.

const EPISODE_STARS := 45  # Stars in one Episode: 3 Difficulties x 5 Levels x 3 Stars.
const TILE_SIZE := Vector2(310, 280)  # Each tile, so three fit side by side.
const EPISODE_COLOURS := [Color("#4FA8F5"), Color("#4CB050"), Color("#EE5A7A"), Color("#3F2A9C")]  # Each Episode's sky colour (D-020): day, meadow, sunset, night.

var tiles: Array[PanelContainer] = []  # The six tiles, in order.


# Builds the tiles and the Episode card from the learner's saved progress and records.
func _init() -> void:
	add_theme_constant_override("separation", 32)  # Space between the tiles and the card.
	size_flags_horizontal = Control.SIZE_EXPAND_FILL  # As wide as the column.
	var records: Records = Save.records  # The learner's records.
	var grid := GridContainer.new()  # Two rows of three tiles.
	grid.columns = 3  # Three across.
	grid.add_theme_constant_override("h_separation", 24)  # Space between the columns.
	grid.add_theme_constant_override("v_separation", 24)  # Space between the rows.
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	add_child(grid)  # Show it.
	_add_tile(grid, UiKit.Icon.STAR, str(Save.progress.total_stars()), "of %d" % Progress.MAX_STARS, "Stars", Palette.YELLOW)  # Stars earned.
	_add_tile(grid, UiKit.Icon.CHART, str(Save.progress.levels_passed()), "of %d" % Progress.LEVEL_TOTAL, "Levels passed", Palette.GREEN)  # Levels passed.
	_add_tile(grid, UiKit.Icon.PLAY, str(records.levels_played), "", "Levels played", Palette.SKY_TOP)  # Levels played.
	_add_tile(grid, UiKit.Icon.TICK, str(records.correct_total), "", "Right answers", Color("#FF9EBB"))  # Right answers, on soft pink.
	_add_tile(grid, UiKit.Icon.FLAME, str(records.best_streak), "in a row", "Best streak", Palette.ORANGE)  # Best streak.
	_add_tile(grid, UiKit.Icon.CLOCK, _time_text(records.seconds_played), "", "Time played", Color("#C6B6FF"))  # Time played, on soft lavender.
	add_child(_make_episode_card())  # Stars in each Episode.


# Adds one colour tile: the icon, the big number, an optional small line under it (such as
# "of 180"), and the tile's name.
func _add_tile(grid: GridContainer, which: int, value: String, under: String, what: String, colour: Color) -> void:
	var tile := PanelContainer.new()  # The tile.
	var style := UiKit.box(colour, 44)  # Its colour, round and outlined.
	style.set_content_margin_all(14)  # Room inside.
	tile.add_theme_stylebox_override("panel", style)  # Use this look.
	tile.custom_minimum_size = TILE_SIZE  # Its size.
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	var lines := VBoxContainer.new()  # Icon, number and name, top to bottom.
	lines.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	lines.add_theme_constant_override("separation", 0)  # Close together.
	tile.add_child(lines)  # Put them on the tile.
	var picture := UiKit.icon(which, 76)  # The icon.
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	lines.add_child(picture)  # Add it.
	lines.add_child(UiKit.label(value, 76, Palette.INK))  # The big number.
	if under != "":  # A small line goes under the number ...
		lines.add_child(UiKit.label(under, 30, Palette.INK))  # ... such as "of 180".
	var name_label := UiKit.label(what, 34, Palette.INK)  # The tile's name.
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Long names wrap.
	name_label.custom_minimum_size.x = TILE_SIZE.x - 40.0  # As wide as the tile's inside.
	lines.add_child(name_label)  # Add it.
	grid.add_child(tile)  # Show the tile.
	tiles.append(tile)  # Remember it.


# Makes the white "Stars in each Episode" card: one row per Episode.
func _make_episode_card() -> PanelContainer:
	var card := PanelContainer.new()  # The card.
	var style := UiKit.box(Palette.WHITE, 48)  # White, round and outlined.
	style.set_content_margin_all(28)  # Room inside.
	card.add_theme_stylebox_override("panel", style)  # Use this look.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	var lines := VBoxContainer.new()  # The title and the rows.
	lines.add_theme_constant_override("separation", 18)  # Space between rows.
	card.add_child(lines)  # Put them on the card.
	lines.add_child(UiKit.label("Stars in each Episode", 46, Palette.INK))  # The title.
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		lines.add_child(_episode_row(episode))  # ... gets a row.
	return card  # Hand back the card.


# Makes one Episode row: a badge with its number in its world colour, a Star bar, and "5/45" with a Star.
func _episode_row(episode: int) -> HBoxContainer:
	var stars := 0  # Stars in this Episode ...
	for difficulty: int in Difficulty.Kind.values():  # ... over Easy, Medium and Hard.
		stars += Save.progress.stars_in(episode, difficulty)  # Add each Difficulty's Stars.
	var row := HBoxContainer.new()  # Badge, bar and count side by side.
	row.add_theme_constant_override("separation", 20)  # Space between them.
	var badge := PanelContainer.new()  # The Episode badge.
	var badge_style := UiKit.box(EPISODE_COLOURS[episode - 1], 24, 6)  # In the Episode's colour.
	badge_style.set_content_margin_all(4)  # A little room inside.
	badge.add_theme_stylebox_override("panel", badge_style)  # Use this look.
	badge.custom_minimum_size = Vector2(86, 86)  # A square badge.
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	badge.add_child(UiKit.label(str(episode), 52, Palette.WHITE, 10))  # The Episode number, white with a dark outline.
	row.add_child(badge)  # On the left.
	var bar := ProgressBar.new()  # The bar.
	bar.max_value = EPISODE_STARS  # Full at 45 Stars.
	bar.value = stars  # Filled to this Episode's Stars.
	bar.show_percentage = false  # Records, not percentages.
	bar.custom_minimum_size = Vector2(0, 46)  # Its height.
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Centred up and down.
	bar.add_theme_stylebox_override("background", UiKit.box(Palette.LOCKED, 22, 4))  # Grey track.
	bar.add_theme_stylebox_override("fill", UiKit.box(Palette.YELLOW, 22, 4))  # Gold fill, like the Stars.
	row.add_child(bar)  # In the middle.
	var count := UiKit.label("%d/%d" % [stars, EPISODE_STARS], 42, Palette.BLUE)  # For example "5/45".
	count.custom_minimum_size.x = 130.0  # Same width for every Episode, so the bars line up.
	row.add_child(count)  # Add it.
	row.add_child(UiKit.icon(UiKit.Icon.STAR, 52))  # A Star after the count.
	return row  # Hand back the row.


# Turns seconds into short words: "45 s" under a minute, then whole minutes ("12 min").
func _time_text(seconds: float) -> String:
	if seconds < 60.0:  # Under a minute ...
		return "%d s" % int(seconds)  # ... in seconds.
	return "%d min" % int(seconds / 60.0)  # Whole minutes.
