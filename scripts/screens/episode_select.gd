# Episode select: the four Episodes, with a lock on the ones not opened yet (D-008).
extends ScreenBase  # Shared background, margins and column.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Menu music.
	add_header("Episodes", "Choose an Episode")  # Back button and title.
	add_spacer(0.2)  # A little space.
	for number in range(1, Progress.EPISODE_COUNT + 1):  # Episodes 1 to 4 ...
		var card := _episode_card(number)  # ... each a card,
		column.add_child(card)  # ... shown in the column,
		UiKit.pop_in(card, 0.07 * number)  # ... bouncing in one after another.
	add_spacer(1.0)  # Push the hint line down.
	add_hint_line()  # For "locked" and "coming soon" messages.


# Makes one Episode card: name, facts, and a badge (Stars, lock or "Soon").
func _episode_card(number: int) -> Button:
	var data := Game.episode_data(number)  # Its item bank.
	var is_open := Save.progress.is_episode_open(number)  # Opened yet?
	var badge: Control  # What shows on the right.
	if not is_open:  # Locked ...
		badge = UiKit.icon(UiKit.Icon.LOCK, 96)  # ... a lock.
	elif not Game.is_playable(number, Difficulty.Kind.EASY):  # Open but not built yet ...
		badge = UiKit.label("Soon", 44, Palette.BLUE)  # ... "Soon".
	else:  # Open and playable ...
		var stars := 0  # ... count its Stars,
		for kind in range(3):  # ... over Easy, Medium and Hard.
			stars += Save.progress.stars_in(number, kind)  # Add this Difficulty's Stars.
		badge = make_stars_badge(stars, 45)  # 3 Difficulties x 5 Levels x 3 Stars = 45.
	var colour := Palette.WHITE if is_open else Palette.LOCKED  # White when open, grey when locked.
	var card := make_choice_card("Episode %d · %s" % [number, data.title], data.facts, colour, badge)  # The card.
	card.pressed.connect(_on_episode.bind(number, card))  # What a tap does.
	return card  # Hand it back.


# Runs when an Episode card is tapped.
func _on_episode(number: int, card: Button) -> void:
	if not Save.progress.is_episode_open(number):  # Still locked ...
		UiKit.shake(card)  # ... shake the card,
		Audio.play_sfx("wrong")  # ... buzz,
		show_hint("Pass Easy Level 5 of Episode %d to open Episode %d." % [number - 1, number])  # ... and say how to open it.
		return  # Stay here.
	if not Game.is_playable(number, Difficulty.Kind.EASY):  # Open but not built yet ...
		show_hint("Episode %d is coming soon!" % number)  # ... say so.
		return  # Stay here.
	Game.episode = number  # Remember the choice.
	Game.go_to("difficulty_select")  # Next screen.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
