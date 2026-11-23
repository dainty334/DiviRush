# My Records: the learner's game records (D-023), as plain numbers and bars. They are records of
# play, not grades, so there are no percentages or marks (Chapter 1).
extends ScreenBase  # Shared background, margins and column.

const EPISODE_STARS := 45  # Stars in one Episode: 3 Difficulties x 5 Levels x 3 Stars.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	add_header("My Records", "Your game so far")  # Back button and title.
	add_spacer(0.2)  # A little space under the title.
	var records: Records = Save.records  # The learner's records.
	var rows := _make_card()  # The first white card.
	_add_row(rows, UiKit.Icon.STAR, "Stars earned", "%d of %d" % [Save.progress.total_stars(), Progress.MAX_STARS])  # Stars.
	_add_row(rows, UiKit.Icon.CHART, "Levels passed", "%d of %d" % [Save.progress.levels_passed(), Progress.LEVEL_TOTAL])  # Levels passed.
	_add_row(rows, UiKit.Icon.PLAY, "Levels played", str(records.levels_played))  # Levels played.
	_add_row(rows, UiKit.Icon.HELP, "Correct answers", str(records.correct_total))  # Correct answers.
	_add_row(rows, UiKit.Icon.TROPHY, "Best streak", "%d in a row" % records.best_streak)  # Best streak.
	_add_row(rows, UiKit.Icon.CLOCK, "Time played", _time_text(records.seconds_played))  # Time played.
	var bars := _make_card()  # The second white card.
	bars.add_child(UiKit.label("Stars in each Episode", 44, Palette.INK))  # Its title.
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		_add_bar(bars, episode)  # ... gets a bar.
	add_spacer(1.0)  # Space at the bottom.


# Adds a white card to the column and returns the list inside it, for rows to go in.
func _make_card() -> VBoxContainer:
	var card := PanelContainer.new()  # The card.
	var style := UiKit.box(Palette.WHITE, 48)  # White, round and outlined.
	style.set_content_margin_all(30)  # Room inside the card.
	card.add_theme_stylebox_override("panel", style)  # Use this look.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	column.add_child(card)  # Show it.
	UiKit.pop_in(card, 0.05)  # Bounce in.
	var lines := VBoxContainer.new()  # The rows, top to bottom.
	lines.add_theme_constant_override("separation", 14)  # Space between rows.
	card.add_child(lines)  # Put them on the card.
	return lines  # Hand back the list.


# Adds one record row: an icon, what it is, and its value on the right.
func _add_row(lines: VBoxContainer, which: int, what: String, value: String) -> void:
	var row := HBoxContainer.new()  # Icon, words and value side by side.
	row.add_theme_constant_override("separation", 20)  # Space between them.
	row.add_child(UiKit.icon(which, 64))  # The icon.
	var name_label := UiKit.label(what, 44, Palette.INK)  # What the record is.
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Lined up on the left.
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	row.add_child(name_label)  # Add it.
	var value_label := UiKit.label(value, 44, Palette.BLUE)  # The record itself.
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT  # Lined up on the right.
	row.add_child(value_label)  # Add it.
	lines.add_child(row)  # Add the row to the card.


# Adds one Episode's Stars as a bar: "Episode 1", a yellow bar, and "5/45".
func _add_bar(lines: VBoxContainer, episode: int) -> void:
	var stars := 0  # Stars in this Episode ...
	for difficulty: int in Difficulty.Kind.values():  # ... over Easy, Medium and Hard.
		stars += Save.progress.stars_in(episode, difficulty)  # Add each Difficulty's Stars.
	var row := HBoxContainer.new()  # Name, bar and count side by side.
	row.add_theme_constant_override("separation", 20)  # Space between them.
	var name_label := UiKit.label("Episode %d" % episode, 40, Palette.INK)  # Which Episode.
	name_label.custom_minimum_size.x = 210.0  # Same width for every Episode, so the bars line up.
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Lined up on the left.
	row.add_child(name_label)  # Add it.
	var bar := ProgressBar.new()  # The bar.
	bar.max_value = EPISODE_STARS  # Full at 45 Stars.
	bar.value = stars  # Filled to this Episode's Stars.
	bar.show_percentage = false  # Records, not percentages.
	bar.custom_minimum_size = Vector2(0, 40)  # Its height.
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Centred up and down.
	bar.add_theme_stylebox_override("background", UiKit.box(Palette.LOCKED, 20, 4))  # Grey track.
	bar.add_theme_stylebox_override("fill", UiKit.box(Palette.YELLOW, 20, 4))  # Gold fill, like the Stars.
	row.add_child(bar)  # Add it.
	var count := UiKit.label("%d/%d" % [stars, EPISODE_STARS], 40, Palette.BLUE)  # For example "5/45".
	count.custom_minimum_size.x = 120.0  # Same width for every Episode.
	row.add_child(count)  # Add it.
	lines.add_child(row)  # Add the row to the card.


# Turns seconds into short words: "45 s" under a minute, then whole minutes ("12 min").
func _time_text(seconds: float) -> String:
	if seconds < 60.0:  # Under a minute ...
		return "%d s" % int(seconds)  # ... in seconds.
	return "%d min" % int(seconds / 60.0)  # Whole minutes.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
