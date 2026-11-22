# Play screen: one Level of 10 items, laid out like the approved style sample (D-009):
# top bar, progress dots, timer bar, streak badge, item card and answer bubbles.
# The rules live in LevelRun; this screen only shows them and moves between three states.
# When the app leaves the screen, the Level pauses with its time kept, under a "Paused" card (D-015).
extends ScreenBase  # Shared background, margins and column.

enum State { ASKING, FEEDBACK, FINISHED }  # Waiting for a tap; showing the result; Level over.

const FEEDBACK_SECONDS := 0.9  # How long a tapped answer's result shows.
const TIME_OUT_SECONDS := 1.5  # How long the correct answer shows after a time-out (D-010).
const STREAK_BADGE_FROM := 3  # The streak badge appears at 3 correct in a row (D-010).
const BUBBLE_COLOURS := ["yellow", "green", "pink", "yellow"]  # Resting colours, as in the sample.
const THREE_AREA_HEIGHT := 560.0  # Height of the bubble area for Easy's 3 bubbles in a V.
const SQUARE_GAP := 50.0  # Space between bubbles in Medium and Hard's 2 x 2 square, so they never overlap.

var _state: State = State.ASKING  # The state right now.
var _run: LevelRun  # This play's rules and results.
var _item: DivisionItem  # The item showing now.
var _time_left := 0.0  # Seconds left for this item.
var _shown_score := 0.0  # Score number on screen (counts up to the real score).
var _bubbles: Array[AnswerBubble] = []  # Bubbles of the item showing now.

var _score_label: Label  # Score in the top bar.
var _score_pill: PanelContainer  # Yellow pill around the score, which bounces when points are added.
var _dots: ProgressDots  # The 10 progress dots.
var _item_label: Label  # "Item 4 of 10".
var _timer_bar: TimerBar  # The shrinking coloured bar.
var _seconds_label: Label  # "10 s".
var _streak_badge: PanelContainer  # "×3 Streak!" badge.
var _streak_label: Label  # Text inside the badge.
var _question_label: MathText  # Big "56 ÷ 8", or "56 ÷ ☐" with a drawn box.
var _answer_label: Label  # Small "= ?" (or "= 7" after an answer).
var _card: PanelContainer  # The white item card.
var _bubble_area: Control  # Where the bubbles sit.
var _wait: Timer  # Waits while feedback shows.
var _paused := false  # true while the app has left the screen and the "Paused" card shows (D-015).
var _pause_card: Control  # The "Paused" card that covers the screen while paused.


# Builds the screen and starts the first item. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("play")  # Faster play music.
	_run = LevelRun.new(Game.level_data().items, Game.difficulty)  # New play with shuffled items (D-010).
	column.add_theme_constant_override("separation", 22)  # Tighter spacing to fit the sample layout.
	_build_top_bar()  # Back, labels and score.
	_build_progress()  # Dots and "Item 1 of 10".
	_build_timer()  # Timer bar and seconds.
	_build_streak()  # Streak badge row.
	_build_card()  # The item card.
	add_spacer(1.0)  # Space between card and bubbles grows on tall phones.
	_bubble_area = Control.new()  # Free-placement area for the bubbles.
	_bubble_area.custom_minimum_size = Vector2(COLUMN_WIDTH, _bubble_area_height(Difficulty.bubble_count(_run.difficulty)))  # Room for 3 or 4 bubbles.
	column.add_child(_bubble_area)  # Add it.
	column.add_child(UiKit.label("Tap the right bubble!", 42, Palette.WHITE, 10))  # Hint line, as in the sample.
	_wait = Timer.new()  # A timer for the feedback pause.
	_wait.one_shot = true  # Runs once each time it is started.
	_wait.timeout.connect(_on_feedback_done)  # When it ends, move on.
	add_child(_wait)  # Add it (it is freed with the screen).
	_build_pause_card()  # The hidden "Paused" card, on top of everything (D-015).
	_show_item()  # Start with the first item.


# Builds the top bar: back button, Episode / Difficulty / Level labels, and the score.
func _build_top_bar() -> void:
	var bar := HBoxContainer.new()  # Three parts side by side.
	bar.add_theme_constant_override("separation", 24)  # Space between parts.
	bar.add_child(make_back_button())  # Back arrow (leaves the Level).
	var middle := PanelContainer.new()  # White pill with the labels.
	middle.add_theme_stylebox_override("panel", UiKit.box(Palette.WHITE, 60))  # Rounded, outlined.
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	var names := VBoxContainer.new()  # Two lines.
	names.add_theme_constant_override("separation", -4)  # Lines close together.
	var data := Game.episode_data()  # The Episode being played.
	names.add_child(UiKit.label("EPISODE %d · %s" % [Game.episode, data.title.to_upper()], 32, Palette.INK))  # Top line.
	names.add_child(UiKit.label("%s · Level %d" % [Difficulty.name_of(Game.difficulty), Game.level], 30, Palette.BLUE))  # Second line.
	middle.add_child(names)  # Put the lines in the pill.
	bar.add_child(middle)  # Add the pill.
	_score_pill = PanelContainer.new()  # Yellow pill with the score.
	_score_pill.add_theme_stylebox_override("panel", UiKit.box(Palette.YELLOW, 60))  # Rounded, outlined.
	_score_pill.custom_minimum_size = Vector2(260, 120)  # Room for a 3-digit score.
	var score_row := HBoxContainer.new()  # Star icon and number.
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred.
	score_row.add_child(UiKit.icon(UiKit.Icon.STAR, 60))  # Star icon.
	_score_label = UiKit.label("0", 52, Palette.INK)  # Score number.
	score_row.add_child(_score_label)  # Add it.
	_score_pill.add_child(score_row)  # Put the row in the pill.
	bar.add_child(_score_pill)  # Add the pill.
	UiKit.center_pivot(_score_pill)  # So the score pill can bounce from its middle.
	column.add_child(bar)  # Show the bar.


# Builds the progress dots and the "Item 1 of 10" line.
func _build_progress() -> void:
	_dots = ProgressDots.new()  # The 10 dots.
	_dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	column.add_child(_dots)  # Show them.
	_item_label = UiKit.label("", 34, Palette.WHITE, 10)  # "Item 1 of 10".
	column.add_child(_item_label)  # Show it.


# Builds the timer bar row: the bar, a clock icon and the seconds left.
func _build_timer() -> void:
	var row := HBoxContainer.new()  # Bar and seconds side by side.
	row.add_theme_constant_override("separation", 16)  # Space between them.
	_timer_bar = TimerBar.new()  # The shrinking bar.
	row.add_child(_timer_bar)  # Add it.
	row.add_child(UiKit.icon(UiKit.Icon.CLOCK, 64))  # Clock icon.
	_seconds_label = UiKit.label("15 s", 44, Palette.WHITE, 12)  # Seconds left.
	_seconds_label.custom_minimum_size = Vector2(110, 0)  # Fixed width, so the bar does not jump.
	row.add_child(_seconds_label)  # Add it.
	column.add_child(row)  # Show the row.


# Builds the streak badge row. The row keeps its height, so the layout does not jump when the badge shows.
func _build_streak() -> void:
	var row := Control.new()  # Fixed-height row.
	row.custom_minimum_size = Vector2(COLUMN_WIDTH, 110)  # Room for the tilted badge.
	_streak_badge = PanelContainer.new()  # The pink badge.
	_streak_badge.add_theme_stylebox_override("panel", UiKit.box(Palette.PINK, 48))  # Rounded, outlined.
	_streak_label = UiKit.label("×3 Streak!", 46, Palette.WHITE, 10)  # Badge text.
	_streak_badge.add_child(_streak_label)  # Put the text on the badge.
	_streak_badge.position = Vector2(60, 6)  # Left side, as in the sample.
	_streak_badge.rotation = deg_to_rad(-8.0)  # Tilted for fun, as in the sample.
	_streak_badge.modulate.a = 0.0  # Hidden until a streak starts.
	row.add_child(_streak_badge)  # Add it.
	column.add_child(row)  # Show the row.


# Builds the white item card with the big question and the small "= ?".
func _build_card() -> void:
	_card = PanelContainer.new()  # The card.
	_card.add_theme_stylebox_override("panel", UiKit.box(Palette.WHITE, 70))  # Rounded, outlined.
	_card.custom_minimum_size = Vector2(860, 380)  # Size from the sample.
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	var lines := VBoxContainer.new()  # Question above answer.
	lines.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	lines.add_theme_constant_override("separation", -10)  # Lines close together.
	_question_label = MathText.new(170, Palette.INK)  # Big "56 ÷ 8"; a ☐ is drawn as a thick box.
	lines.add_child(_question_label)  # Add it.
	_answer_label = UiKit.label("", 64, Palette.BLUE)  # Small "= ?".
	lines.add_child(_answer_label)  # Add it.
	_card.add_child(lines)  # Put the lines on the card.
	UiKit.center_pivot(_card)  # So the card can bounce from its middle.
	column.add_child(_card)  # Show the card.


# Shows the next item: card text, dots, timer and fresh bubbles. Moves to the ASKING state.
func _show_item() -> void:
	_item = _run.current_item()  # The item to show.
	_time_left = _run.time_limit()  # Full time (15 s on Easy).
	_set_card_text(_item.question_text(), Palette.BLUE)  # "56 ÷ 8" and "= ?".
	_dots.show_state(_run.results, _run.index)  # Update the dots.
	_item_label.text = "Item %d of %d" % [_run.index + 1, _run.items.size()]  # "Item 4 of 10".
	_update_timer()  # Full bar.
	_card.scale = Vector2(0.9, 0.9)  # Card starts a little small ...
	_card.create_tween().tween_property(_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # ... and bounces to full size.
	_make_bubbles(_run.choices())  # New bubbles with the shuffled numbers.
	_state = State.ASKING  # Wait for a tap.


# Splits "56 ÷ 8 = ?" into the big part "56 ÷ 8" and the small part "= ?", and colours the small part.
func _set_card_text(text: String, answer_colour: Color) -> void:
	var parts := text.split(" = ")  # Two parts around the equals sign.
	_question_label.set_text(parts[0])  # Big part.
	_answer_label.text = "= " + parts[1] if parts.size() > 1 else ""  # Small part.
	_answer_label.label_settings.font_color = answer_colour  # Blue while asking; green or pink after.


# Removes the old bubbles and places new ones for these numbers.
func _make_bubbles(values: Array[int]) -> void:
	for old in _bubbles:  # Each old bubble ...
		old.queue_free()  # ... is removed.
	_bubbles.clear()  # Forget them.
	var spots := _bubble_spots(values.size())  # Where the new ones go.
	for i in range(values.size()):  # Each number ...
		var bubble := AnswerBubble.new()  # ... gets a bubble,
		bubble.setup(values[i], BUBBLE_COLOURS[i])  # ... with its number and colour,
		_bubble_area.add_child(bubble)  # ... added to the area,
		bubble.place(spots[i])  # ... at its spot,
		bubble.appear(0.08 * i)  # ... popping in one after another,
		bubble.tapped.connect(_on_bubble_tapped)  # ... and reporting taps.
		_bubbles.append(bubble)  # Keep it.


# Returns the top-left corner of each bubble: 3 bubbles in a V like the sample, 4 in a square.
func _bubble_spots(count: int) -> Array[Vector2]:
	if count == 3:  # Easy (D-008).
		return [Vector2(20, 30), Vector2(340, 210), Vector2(660, 30)]  # Left high, middle low, right high.
	var step := AnswerBubble.SIZE + SQUARE_GAP  # From one bubble's corner to the next one's: a bubble plus the gap.
	var left := (COLUMN_WIDTH - AnswerBubble.SIZE - step) / 2.0  # Left edge that centres the square in the column.
	return [Vector2(left, 0), Vector2(left + step, 0), Vector2(left, step), Vector2(left + step, step)]  # Medium and Hard: 2 x 2.


# Returns how tall the bubble area must be for this many bubbles. Runs once when the screen is built.
func _bubble_area_height(count: int) -> float:
	if count == 3:  # Easy's V shape ...
		return THREE_AREA_HEIGHT  # ... keeps the height from the style sample.
	return AnswerBubble.SIZE * 2.0 + SQUARE_GAP  # Two rows of bubbles and the gap between them.


# Runs every frame: counts the timer down while waiting for a tap.
func _process(delta: float) -> void:
	if _state != State.ASKING or _paused:  # Only while asking, and not paused (D-015) ...
		return  # ... does the timer run.
	_time_left = maxf(0.0, _time_left - delta)  # Count down, never below 0.
	_update_timer()  # Show it.
	if _time_left <= 0.0:  # Time is up ...
		_on_time_out()  # ... so it counts as wrong (D-008).


# Shows the time left on the bar and as whole seconds.
func _update_timer() -> void:
	_timer_bar.ratio = _time_left / _run.time_limit()  # Share of time left.
	_seconds_label.text = "%d s" % ceili(_time_left)  # Whole seconds, rounded up.


# Runs when a bubble is tapped: checks the answer and shows the result.
func _on_bubble_tapped(bubble: AnswerBubble) -> void:
	if _state != State.ASKING:  # Only the first tap counts.
		return  # Ignore extra taps.
	_state = State.FEEDBACK  # Stop the timer and show the result.
	var result := _run.submit_answer(bubble.value, _time_left)  # The rules decide (LevelRun).
	_lock_bubbles()  # No more taps on this item.
	if result.correct:  # Right answer ...
		bubble.mark_correct()  # ... green pop with sparkles,
		Audio.play_sfx("correct")  # ... happy sound,
		UiKit.float_text(self, "+%d" % result.points, bubble.global_position + bubble.size / 2.0 - global_position, Palette.YELLOW)  # ... and the points float up.
	else:  # Wrong answer ...
		bubble.mark_wrong()  # ... red shake,
		Audio.play_sfx("wrong")  # ... buzz sound,
		Game.vibrate()  # ... phone buzz if switched on,
		_reveal_answer(result.correct_answer)  # ... and the right bubble turns green to teach the answer.
	_dim_others(bubble, result.correct_answer)  # Fade the bubbles not involved.
	_after_answer(result, FEEDBACK_SECONDS)  # Update the score and wait.


# Runs when the timer reaches 0: counts as wrong and shows the correct answer for a moment (D-008).
func _on_time_out() -> void:
	_state = State.FEEDBACK  # Stop the timer and show the result.
	var result := _run.time_out()  # The rules record a wrong answer with 0 points.
	_lock_bubbles()  # No more taps on this item.
	Audio.play_sfx("time_up")  # Time-up sound.
	_reveal_answer(result.correct_answer)  # Show the right bubble in green.
	_dim_others(null, result.correct_answer)  # Fade the wrong bubbles.
	UiKit.float_text(self, "Time's up!", _card.global_position + Vector2(_card.size.x / 2.0, -20.0) - global_position, Palette.PINK, 80)  # Big message just above the card, clear of the question.
	_after_answer(result, TIME_OUT_SECONDS)  # Update the score and wait a little longer.


# Shared steps after any answer: show the full fact, update score, streak and dots, then wait.
func _after_answer(result: Dictionary, seconds: float) -> void:
	_set_card_text(_item.answered_text(), Palette.GREEN if result.correct else Palette.PINK)  # "56 ÷ 8" and "= 7".
	_update_score()  # Count the score up.
	_update_streak()  # Show or hide the streak badge.
	_dots.show_state(_run.results, _run.index)  # Colour the dot just answered.
	_wait.start(seconds)  # Wait, then _on_feedback_done().


# Stops every bubble from taking taps.
func _lock_bubbles() -> void:
	for bubble in _bubbles:  # Each bubble ...
		bubble.lock()  # ... is locked.


# Turns the bubble with the correct answer green, without the celebration.
func _reveal_answer(answer: int) -> void:
	for bubble in _bubbles:  # Look at each bubble ...
		if bubble.value == answer:  # ... the one with the right number ...
			bubble.reveal()  # ... turns green with a tick.


# Fades every bubble that is neither the tapped one nor the correct one.
func _dim_others(tapped: AnswerBubble, answer: int) -> void:
	for bubble in _bubbles:  # Each bubble ...
		if bubble != tapped and bubble.value != answer:  # ... not involved ...
			bubble.dim()  # ... fades back.


# Counts the score on screen up to the real score, with a little bounce of the score pill.
func _update_score() -> void:
	var tween := create_tween()  # A tween on the screen.
	tween.tween_method(_set_shown_score, _shown_score, float(_run.score), 0.4)  # Count up over 0.4 s.
	if _run.score > int(_shown_score):  # Points were added ...
		_score_pill.scale = Vector2(1.15, 1.15)  # ... the score pill jumps bigger,
		_score_pill.create_tween().tween_property(_score_pill, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)  # ... and settles back.


# Shows a score number while counting up. Called by the tween.
func _set_shown_score(value: float) -> void:
	_shown_score = value  # Remember it.
	_score_label.text = str(int(value))  # Show it as a whole number.


# Shows the streak badge from 3 in a row, growing a little as the streak grows; hides it after a miss.
func _update_streak() -> void:
	if _run.streak < STREAK_BADGE_FROM:  # No streak (or it just ended) ...
		_streak_badge.create_tween().tween_property(_streak_badge, "modulate:a", 0.0, 0.2)  # ... fade the badge out.
		return  # Done.
	_streak_label.text = "×%d Streak!" % _run.streak  # "×4 Streak!".
	_streak_label.label_settings.font_size = mini(46 + (_run.streak - STREAK_BADGE_FROM) * 4, 66)  # Bigger text for a longer streak.
	_streak_badge.modulate.a = 1.0  # Show it.
	_streak_badge.pivot_offset = _streak_badge.size / 2.0  # Bounce from the middle.
	_streak_badge.scale = Vector2(1.3, 1.3)  # Pop bigger ...
	_streak_badge.create_tween().tween_property(_streak_badge, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # ... and settle.


# Runs when the feedback pause ends: pops the bubbles, then shows the next item or ends the Level.
func _on_feedback_done() -> void:
	for bubble in _bubbles:  # Each bubble ...
		bubble.burst()  # ... pops.
	Audio.play_sfx("pop")  # Pop sound.
	var tween := create_tween()  # Wait for the pop to finish.
	tween.tween_interval(0.3)  # 0.3 seconds.
	if _run.is_finished():  # That was the 10th item ...
		tween.tween_callback(_finish)  # ... so end the Level.
	else:  # More items ...
		tween.tween_callback(_show_item)  # ... so show the next one.


# Ends the Level: saves the bests and opens the Level end screen.
func _finish() -> void:
	_state = State.FINISHED  # Nothing more to do here.
	var flags := Save.record_result(Game.episode, Game.difficulty, Game.level, _run.stars(), _run.score, _run.total_time)  # Save bests (D-008).
	Game.last_result = {  # What the Level end screen shows.
		"correct": _run.correct_count,  # Right answers.
		"total": _run.items.size(),  # Items in the Level (10).
		"stars": _run.stars(),  # Stars earned.
		"score": _run.score,  # Points earned.
		"time": _run.total_time,  # Seconds used.
		"passed": _run.passed(),  # At least one Star?
		"new_best": flags.new_stars or flags.new_score or flags.new_time,  # Any new record?
	}  # End of the list.
	Game.go_to("level_end")  # Show the result.


# Builds the "Paused" card: a dark veil over the whole screen with a white card, the word
# "Paused" and three buttons: Resume, Restart and Levels, styled like the Level end buttons.
# It starts hidden and blocks taps on the item while it shows (D-015).
func _build_pause_card() -> void:
	_pause_card = Control.new()  # Holder that fills the screen.
	_pause_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Cover everything.
	_pause_card.mouse_filter = Control.MOUSE_FILTER_STOP  # Taps stop here, so no bubble can be tapped.
	_pause_card.visible = false  # Hidden until the app leaves the screen.
	var veil := ColorRect.new()  # Dark see-through layer.
	veil.color = Color(Palette.INK, 0.7)  # Dark ink, 70% strong.
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the screen.
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE  # The holder already stops taps.
	_pause_card.add_child(veil)  # Add it.
	var centre := CenterContainer.new()  # Puts the card in the middle.
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the screen.
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the button.
	_pause_card.add_child(centre)  # Add it.
	var panel := PanelContainer.new()  # The white card.
	var style := UiKit.box(Palette.WHITE, 70)  # Rounded and outlined, like the item card.
	style.set_content_margin_all(60)  # Room inside the card.
	panel.add_theme_stylebox_override("panel", style)  # Use this look.
	centre.add_child(panel)  # Add it.
	var lines := VBoxContainer.new()  # Word above button.
	lines.add_theme_constant_override("separation", 40)  # Space between them.
	panel.add_child(lines)  # Add it.
	lines.add_child(UiKit.label("Paused", 110, Palette.INK))  # Big word.
	var resume := UiKit.button("Resume", Palette.GREEN, Vector2(600, 150))  # Big green button.
	resume.pressed.connect(resume_level)  # Back to the item, with the time it had left.
	lines.add_child(resume)  # Add it.
	var restart := UiKit.button("Restart", Palette.YELLOW, Vector2(600, 140), 60)  # Yellow, like "Play again".
	restart.pressed.connect(restart_level)  # Start this Level again from item 1.
	lines.add_child(restart)  # Add it.
	var levels := UiKit.button("Levels", Palette.WHITE, Vector2(600, 140), 60)  # White, like on the Level end screen.
	levels.pressed.connect(leave_level)  # Back to Level select.
	lines.add_child(levels)  # Add it.
	add_child(_pause_card)  # Added last, so it draws on top of the screen.


# Runs when Godot or Android sends the screen a notice. Leaving the app pauses the Level (D-015).
# ScreenBase's own _notification still runs too, so the Android Back button keeps working.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:  # The app left the screen ...
		pause_level()  # ... so pause.


# Pauses the Level: stops the timer and the feedback wait, hides the item and bubbles, and shows
# the "Paused" card. Runs when the app leaves the screen. Does nothing after the Level ends.
func pause_level() -> void:
	if _paused or _state == State.FINISHED or _pause_card == null:  # Already paused, over, or not built yet ...
		return  # ... nothing to do.
	_paused = true  # The timer in _process() stops counting.
	_wait.paused = true  # Hold the feedback wait between items, too.
	_card.visible = false  # Hide the item, so leaving the app gives no extra thinking time.
	_bubble_area.visible = false  # Hide the bubbles as well.
	_pause_card.visible = true  # Show the "Paused" card.


# Goes on with the Level: hides the card, shows the item and bubbles again, and lets the timer run
# on from the seconds it had left. Runs when "Resume" is tapped.
func resume_level() -> void:
	if not _paused:  # Not paused ...
		return  # ... nothing to do.
	_paused = false  # The timer counts again.
	_wait.paused = false  # The feedback wait goes on.
	_card.visible = true  # Show the item.
	_bubble_area.visible = true  # Show the bubbles.
	_pause_card.visible = false  # Hide the card.


# Starts this Level again from item 1 with a new shuffle. Nothing from the stopped play is saved,
# the same as leaving with Back. Runs when "Restart" is tapped on the "Paused" card.
func restart_level() -> void:
	_stop_play()  # Stop the timer and any wait first.
	Game.go_to("play_screen")  # A fresh Play screen for the same Level.


# Leaves the Level without saving this play, back to Level select. Runs when "Levels" is tapped.
func leave_level() -> void:
	go_back()  # The same as the Back button.


# Stops this play at once, so no timer or next item runs while the screen fades out.
func _stop_play() -> void:
	_state = State.FINISHED  # Stop the timer.
	_wait.stop()  # Cancel a feedback pause.


# Returns true while the Level is paused. Used by the tests.
func is_paused() -> bool:
	return _paused  # The pause flag.


# Back leaves the Level without saving this play, and returns to Level select.
func go_back() -> void:
	_stop_play()  # Stop the timer and cancel a feedback pause, so no next item starts while the screen fades out.
	Game.go_to("level_select")  # Level select.
