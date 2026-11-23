# Level end: Stars fill in one by one, then the score, time and a "New best!" tag (D-008).
# Buttons go to the next Level, play again, or back to Level select.
extends ScreenBase  # Shared background, margins and column.

var _result: Dictionary  # The finished play, from Game.last_result.
var _stars: Array[TextureRect] = []  # The three big Stars.
var _new_best: PanelContainer  # The "New best!" tag.
var _trophy_banner: PanelContainer = null  # The "Trophy earned!" banner, only when this play earned a Trophy (D-023).


# Builds the screen and starts the Star animation. Called once by ScreenBase when the screen opens.
func _build() -> void:
	_result = Game.last_result  # The finished play.
	if _result.is_empty():  # Opened without a play (for example, run alone in the editor) ...
		_result = {"correct": 0, "total": 10, "stars": 0, "score": 0, "time": 0.0, "passed": false, "new_best": false}  # ... show an empty result.
	var passed: bool = _result.passed  # Did the learner pass?
	if passed:  # Passed ...
		Audio.play_music("win", "select")  # ... win jingle, then the selection music (D-020).
	else:  # Not passed ...
		Audio.play_music("select")  # ... the selection music (D-020).
	add_spacer(0.5)  # Space at the top.
	column.add_child(UiKit.label("Level passed!" if passed else "Try again!", 110, Palette.YELLOW if passed else Palette.WHITE, 26))  # Big heading.
	column.add_child(UiKit.label("Episode %d · %s · Level %d" % [Game.episode, Difficulty.name_of(Game.difficulty), Game.level], 42, Palette.WHITE, 10))  # Which Level.
	column.add_child(_build_stars())  # The three Stars.
	_new_best = _build_new_best()  # The "New best!" tag (hidden for now).
	column.add_child(_new_best)  # Add it.
	column.add_child(_build_numbers())  # Correct answers, score, time and bests.
	var trophies: Array = _result.get("new_trophies", [])  # Trophies this play earned, if any.
	if not trophies.is_empty():  # At least one ...
		_trophy_banner = _build_trophy_banner(trophies)  # ... gets the banner (hidden for now),
		column.add_child(_trophy_banner)  # ... under the numbers.
	add_spacer(1.0)  # Push the buttons down.
	_build_buttons(passed)  # Next / Play again / Levels.
	_animate_stars()  # Start filling the Stars.


# Builds the row of three big empty Stars.
func _build_stars() -> HBoxContainer:
	var row := HBoxContainer.new()  # Stars side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred.
	row.add_theme_constant_override("separation", 20)  # Space between Stars.
	for i in range(3):  # Three Stars.
		var star := TextureRect.new()  # One Star picture.
		star.texture = SpriteSheet.star()[0]  # Starts empty (frame 0).
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
		star.custom_minimum_size = Vector2(240, 240) if i == 1 else Vector2(200, 200)  # Middle Star bigger.
		star.size_flags_vertical = Control.SIZE_SHRINK_END if i == 1 else Control.SIZE_SHRINK_CENTER  # Middle Star sits higher in the row.
		UiKit.center_pivot(star)  # Bounce from the middle.
		row.add_child(star)  # Add it.
		_stars.append(star)  # Keep it.
	return row  # Hand back the row.


# Builds the "New best!" tag. It stays see-through until the Stars have filled.
func _build_new_best() -> PanelContainer:
	var tag := PanelContainer.new()  # The tag.
	tag.add_theme_stylebox_override("panel", UiKit.box(Palette.PINK, 48))  # Pink, rounded, outlined.
	tag.add_child(UiKit.label("New best!", 56, Palette.WHITE, 12))  # Its text.
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	tag.rotation = deg_to_rad(-6.0)  # Tilted for fun.
	tag.modulate.a = 0.0  # Hidden at first.
	return tag  # Hand it back.


# Builds the white card with correct answers, score, time and the Level's bests.
func _build_numbers() -> PanelContainer:
	var card := PanelContainer.new()  # The card.
	card.add_theme_stylebox_override("panel", UiKit.box(Palette.WHITE, 60))  # Rounded, outlined.
	var lines := VBoxContainer.new()  # Lines stacked.
	lines.add_theme_constant_override("separation", 6)  # Small gaps.
	lines.add_child(UiKit.label("%d of %d correct" % [_result.correct, _result.total], 60, Palette.INK))  # Accuracy (Stars count this).
	lines.add_child(UiKit.label("Score %d   ·   Time %.1f s" % [_result.score, _result.time], 48, Palette.BLUE))  # Points and time.
	var best := Save.progress.best(Game.episode, Game.difficulty, Game.level)  # The Level's saved bests.
	var best_time := "%.1f s" % best.time if best.time >= 0.0 else "--"  # No best time until a pass.
	lines.add_child(UiKit.label("Best: %d points · %s" % [best.score, best_time], 40, Palette.INK))  # Bests line.
	card.add_child(lines)  # Put the lines on the card.
	return card  # Hand it back.


# Adds the buttons: Next Level (only after a pass, when there is one), Play again, and Levels.
func _build_buttons(passed: bool) -> void:
	var next_open := Game.level < Progress.LEVEL_COUNT and Save.progress.is_level_open(Game.episode, Game.difficulty, Game.level + 1)  # Is there an open next Level?
	if passed and next_open:  # Passed and a next Level exists ...
		var next := UiKit.button("Next Level", Palette.GREEN, Vector2(760, 150), 64)  # ... offer it.
		next.pressed.connect(_on_next)  # Go to it.
		column.add_child(next)  # Show it.
		UiKit.pop_in(next, 1.6)  # Pops in after the Stars.
	var again := UiKit.button("Play again", Palette.YELLOW, Vector2(760, 140), 60)  # Replay this Level.
	again.pressed.connect(_on_again)  # Restart it.
	column.add_child(again)  # Show it.
	UiKit.pop_in(again, 1.7)  # Pops in after the Stars.
	var levels := UiKit.button("Levels", Palette.WHITE, Vector2(760, 140), 60)  # Back to Level select.
	levels.pressed.connect(go_back)  # Go there.
	column.add_child(levels)  # Show it.
	UiKit.pop_in(levels, 1.8)  # Pops in last.


# Fills the earned Stars one by one, each with a sound, then shows "New best!" if a record was set.
func _animate_stars() -> void:
	var tween := create_tween()  # One tween for the whole sequence.
	tween.tween_interval(0.5)  # Short pause after the screen opens.
	for i in range(_result.stars):  # Each earned Star ...
		tween.tween_callback(Audio.play_sfx.bind("star", 1.0 + 0.12 * i))  # ... plays a sound, higher each time,
		tween.tween_method(_set_star_frame.bind(i), 0.0, 5.99, 0.3)  # ... fills from empty to full,
		tween.tween_callback(_bounce_star.bind(i))  # ... and bounces.
		tween.tween_interval(0.15)  # Small gap before the next Star.
	if _result.new_best:  # A new record ...
		tween.tween_callback(_show_new_best)  # ... gets the tag.
	if _trophy_banner != null:  # A Trophy was earned ...
		tween.tween_interval(0.4)  # ... after a short pause,
		tween.tween_callback(_show_trophy_banner)  # ... the banner shows.


# Builds the gold "Trophy earned!" banner: a Trophy picture, the heading, and each new Trophy's name.
# It starts hidden; the Star animation shows it at the end (D-023).
func _build_trophy_banner(trophies: Array) -> PanelContainer:
	var banner := PanelContainer.new()  # The banner.
	var style := UiKit.box(Palette.YELLOW, 48)  # Gold, round and outlined.
	style.set_content_margin_all(18)  # Room inside.
	style.content_margin_left = 30  # A bit more at the ends ...
	style.content_margin_right = 36  # ... so it looks balanced.
	banner.add_theme_stylebox_override("panel", style)  # Use this look.
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred, as wide as its words.
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	banner.modulate.a = 0.0  # Hidden at first.
	var row := HBoxContainer.new()  # Picture beside the words.
	row.add_theme_constant_override("separation", 20)  # Space between them.
	banner.add_child(row)  # Put it on the banner.
	row.add_child(UiKit.icon(UiKit.Icon.TROPHY, 96))  # The gold Trophy.
	var words := VBoxContainer.new()  # Heading above the names.
	words.add_theme_constant_override("separation", 0)  # Close together.
	row.add_child(words)  # Add it.
	words.add_child(UiKit.label("Trophy earned!", 48, Palette.INK))  # The heading.
	for id: String in trophies:  # Each new Trophy ...
		words.add_child(UiKit.label(Trophies.name_of(id), 38, Palette.BLUE))  # ... by name.
	return banner  # Hand back the hidden banner.


# Shows the Trophy banner with a pop and a bright Star sound.
func _show_trophy_banner() -> void:
	_trophy_banner.modulate.a = 1.0  # Make it visible.
	UiKit.pop_in(_trophy_banner)  # Bounce it in.
	Audio.play_sfx("star", 1.5)  # A high, happy ring.


# Shows one fill frame of Star `index`. Called by the tween with values from 0 to 5.99.
func _set_star_frame(value: float, index: int) -> void:
	_stars[index].texture = SpriteSheet.star()[int(value)]  # Frame 0 (empty) to 5 (full).


# Makes Star `index` jump bigger and settle back.
func _bounce_star(index: int) -> void:
	var star := _stars[index]  # The Star.
	star.scale = Vector2(1.3, 1.3)  # Jump bigger.
	star.create_tween().tween_property(star, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)  # Wobble back.


# Shows the "New best!" tag with a pop.
func _show_new_best() -> void:
	_new_best.modulate.a = 1.0  # Make it visible.
	UiKit.pop_in(_new_best)  # Bounce it in.


# Next Level: plays the following Level.
func _on_next() -> void:
	Game.level += 1  # The next Level.
	Game.go_to("play_screen")  # Play it.


# Play again: replays the same Level (items shuffled again).
func _on_again() -> void:
	Game.go_to("play_screen")  # Play it again.


# Back and the Levels button return to Level select.
func go_back() -> void:
	Game.go_to("level_select")  # Level select.


# This screen shows the chosen Episode's world: day, meadow, sunset or night (D-020).
func sky_look() -> int:
	return SkyBackground.for_episode(Game.episode)  # The chosen Episode's look.
