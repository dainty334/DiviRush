# Difficulty select: Easy, Medium and Hard for the chosen Episode, locked until opened (D-008).
extends ScreenBase  # Shared background, margins and column.

const LOCK_HINTS := [  # Why each Difficulty is locked, in Kind order.
	"Pass Easy Level 5 of the Episode before to open this.",  # Lock hint for one Difficulty.
	"Pass Easy Level 5 to open Medium.",  # Lock hint for one Difficulty.
	"Pass Medium Level 5 to open Hard.",  # Lock hint for one Difficulty.
]  # End of the list.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("select")  # Selection music (D-020).
	var data := Game.episode_data()  # The chosen Episode.
	add_header("Episode %d" % Game.episode, data.title)  # Back button and title.
	add_spacer(0.2)  # A little space.
	for kind in range(3):  # Easy, Medium, Hard ...
		var card := _difficulty_card(kind)  # ... each a card,
		column.add_child(card)  # ... shown in the column,
		UiKit.pop_in(card, 0.08 * (kind + 1))  # ... bouncing in.
	add_spacer(1.0)  # Push the hint line down.
	add_hint_line()  # For "locked" and "coming soon" messages.


# Makes one Difficulty card: name, what it changes, and a badge (Stars, lock or "Soon").
func _difficulty_card(kind: int) -> Button:
	var is_open := Save.progress.is_difficulty_open(Game.episode, kind)  # Opened yet?
	var badge: Control  # What shows on the right.
	if not is_open:  # Locked ...
		badge = UiKit.icon(UiKit.Icon.LOCK, 96)  # ... a lock.
	elif not Game.is_playable(Game.episode, kind):  # Open but its items are not built yet ...
		badge = UiKit.label("Soon", 44, Palette.BLUE)  # ... "Soon".
	else:  # Open and playable ...
		badge = make_stars_badge(Save.progress.stars_in(Game.episode, kind), 15)  # ... its Stars out of 15.
	var details := "%d bubbles · %d s per item" % [Difficulty.bubble_count(kind), int(Difficulty.time_limit(kind))]  # What it changes (D-008).
	var colour := Palette.WHITE if is_open else Palette.LOCKED  # White when open, grey when locked.
	var card := make_choice_card(Difficulty.name_of(kind), details, colour, badge)  # The card.
	card.pressed.connect(_on_difficulty.bind(kind, card))  # What a tap does.
	return card  # Hand it back.


# Runs when a Difficulty card is tapped.
func _on_difficulty(kind: int, card: Button) -> void:
	if not Save.progress.is_difficulty_open(Game.episode, kind):  # Still locked ...
		UiKit.shake(card)  # ... shake the card,
		Audio.play_sfx("wrong")  # ... buzz,
		show_hint(LOCK_HINTS[kind])  # ... and say how to open it.
		return  # Stay here.
	if not Game.is_playable(Game.episode, kind):  # Open but not built yet ...
		show_hint("%s is coming soon!" % Difficulty.name_of(kind))  # ... say so.
		return  # Stay here.
	Game.difficulty = kind  # Remember the choice.
	Game.go_to("level_select")  # Next screen.


# Back returns to Episode select.
func go_back() -> void:
	Game.go_to("episode_select")  # Episode select.


# The selection screens have their own teal sky with stars and ÷ signs (D-020).
func sky_look() -> int:
	return SkyBackground.Look.SELECT  # Selection look.
