# Level select: the 5 Levels of the chosen Difficulty, each with its best Stars, locked until opened (D-008).
extends ScreenBase  # Shared background, margins and column.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Menu music.
	var data := Game.episode_data()  # The chosen Episode.
	add_header("%s Levels" % Difficulty.name_of(Game.difficulty), "Episode %d · %s" % [Game.episode, data.title])  # Back button and title.
	add_spacer(0.3)  # A little space.
	var grid := GridContainer.new()  # Levels in rows of three.
	grid.columns = 3  # Three per row.
	grid.add_theme_constant_override("h_separation", 40)  # Space across.
	grid.add_theme_constant_override("v_separation", 40)  # Space down.
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	column.add_child(grid)  # Show the grid.
	for number in range(1, Progress.LEVEL_COUNT + 1):  # Levels 1 to 5 ...
		var card := _level_card(number, data.levels[number - 1])  # ... each a card,
		grid.add_child(card)  # ... in the grid,
		UiKit.pop_in(card, 0.06 * number)  # ... bouncing in.
	add_spacer(1.0)  # Push the hint line down.
	add_hint_line()  # For "locked" messages.


# Makes one Level card: its number, its facts, and its best Stars or a lock.
func _level_card(number: int, level: LevelData) -> Button:
	var is_open := Save.progress.is_level_open(Game.episode, Game.difficulty, number)  # Opened yet?
	var card := UiKit.card_button(Palette.YELLOW if is_open else Palette.LOCKED, Vector2(280, 330), 70)  # Yellow when open, grey when locked.
	var stack := VBoxContainer.new()  # Number, facts and Stars stacked.
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the card.
	stack.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the card.
	stack.add_theme_constant_override("separation", 0)  # Tight stack.
	stack.add_child(UiKit.label(str(number), 120, Palette.INK))  # Big Level number.
	stack.add_child(UiKit.label(_facts_of(level), 40, Palette.BLUE))  # Which facts it practises.
	if is_open:  # Open ...
		stack.add_child(_star_row(Save.progress.best(Game.episode, Game.difficulty, number).stars))  # ... best Stars.
	else:  # Locked ...
		var lock := UiKit.icon(UiKit.Icon.LOCK, 72)  # ... a lock,
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # ... centred.
		stack.add_child(lock)  # Add it.
	card.add_child(stack)  # Put everything on the card.
	card.pressed.connect(_on_level.bind(number, card))  # What a tap does.
	return card  # Hand it back.


# Returns a short label for a Level's facts: "÷2" if it uses one divisor, otherwise "Mix".
func _facts_of(level: LevelData) -> String:
	var divisors := {}  # Divisors found.
	for item in level.items:  # Each item ...
		divisors[item.divisor] = true  # ... adds its divisor.
	if divisors.size() == 1:  # Only one divisor ...
		return "÷%d" % divisors.keys()[0]  # ... show it.
	return "Mix"  # Mixed review Level.


# Makes a row of 3 Star icons: gold for earned, grey for not yet.
func _star_row(earned: int) -> HBoxContainer:
	var row := HBoxContainer.new()  # Stars side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the card.
	row.add_theme_constant_override("separation", 2)  # Close together.
	for i in range(3):  # Three Stars ...
		row.add_child(UiKit.icon(UiKit.Icon.STAR if i < earned else UiKit.Icon.STAR_EMPTY, 64))  # ... gold or grey.
	return row  # Hand back the row.


# Runs when a Level card is tapped.
func _on_level(number: int, card: Button) -> void:
	if not Save.progress.is_level_open(Game.episode, Game.difficulty, number):  # Still locked ...
		UiKit.shake(card)  # ... shake the card,
		Audio.play_sfx("wrong")  # ... buzz,
		show_hint("Pass Level %d to open Level %d." % [number - 1, number])  # ... and say how to open it.
		return  # Stay here.
	Game.level = number  # Remember the choice.
	Game.go_to("play_screen")  # Start playing.


# Back returns to Difficulty select.
func go_back() -> void:
	Game.go_to("difficulty_select")  # Difficulty select.
