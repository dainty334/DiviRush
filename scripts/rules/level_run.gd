# One play of a Level: the shuffled items, the answers given, the score, the streak and the time.
# A plain class with no scene, so the Play screen only shows what this class decides,
# and tests can check every rule without opening a scene.
class_name LevelRun  # Lets the Play screen and tests write LevelRun.new(...).
extends RefCounted  # A light object that frees itself when no longer used.

var items: Array[DivisionItem] = []  # This play's items, in shuffled order.
var difficulty: int = Difficulty.Kind.EASY  # The Difficulty being played.
var index: int = 0  # Which item is showing now, 0 to 9.
var score: int = 0  # Points so far; it only goes up.
var correct_count: int = 0  # Correct answers so far.
var streak: int = 0  # Correct answers in a row right now.
var total_time: float = 0.0  # Seconds used on all items so far.
var results: Array[bool] = []  # true or false for each answered item, for the progress dots.
var _rng: RandomNumberGenerator  # Random number maker for shuffling.


# Starts a new play. Called by the Play screen when a Level begins.
# The items are copied and shuffled, so the item bank itself never changes (D-010).
func _init(level_items: Array[DivisionItem], kind: int, rng: RandomNumberGenerator = null) -> void:
	difficulty = kind  # Remember the Difficulty.
	_rng = rng if rng != null else RandomNumberGenerator.new()  # Use the given maker, or a new one.
	if rng == null:  # A new maker needs a seed ...
		_rng.randomize()  # ... from the clock, so each play is different.
	items = level_items.duplicate()  # Copy the list so the shared item bank stays the same.
	_shuffle(items)  # Mix the order for this play.


# Mixes a list into random order (Fisher-Yates shuffle) using this play's random number maker.
func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):  # From the last spot down to the second.
		var j := _rng.randi_range(0, i)  # Pick a random spot at or before i.
		var temp: Variant = list[i]  # Hold the item at i (any type, since items and numbers are both shuffled).
		list[i] = list[j]  # Move item j to spot i.
		list[j] = temp  # Move the held item to spot j.


# Returns the item that is showing now.
func current_item() -> DivisionItem:
	return items[index]  # The item at the current spot.


# Returns the seconds allowed for each item at this play's Difficulty.
func time_limit() -> float:
	return Difficulty.time_limit(difficulty)  # Easy 15 s (D-008).


# Returns the numbers for the answer bubbles: the correct answer plus wrong ones, mixed.
func choices() -> Array[int]:
	var item := current_item()  # The item showing now.
	var values: Array[int] = [item.correct_answer()]  # Start with the correct answer.
	for wrong in item.wrong_for(difficulty):  # Add the stored wrong answers.
		if values.size() >= Difficulty.bubble_count(difficulty):  # Stop when all bubbles are filled.
			break  # Enough numbers.
		values.append(wrong)  # Add this wrong answer.
	_shuffle(values)  # Mix the order so the correct bubble moves around.
	return values  # Hand back the bubble numbers.


# Checks a tapped answer, adds its points and moves to the next item.
# Returns { correct, points, correct_answer } so the Play screen can show feedback.
func submit_answer(value: int, seconds_left: float) -> Dictionary:
	var answer := current_item().correct_answer()  # The right number for this item.
	var used := clampf(time_limit() - seconds_left, 0.0, time_limit())  # Seconds used on this item.
	return _finish_item(value == answer, seconds_left, used, answer)  # Score and move on.


# Records a time-out. It counts as wrong and uses the full time (D-008).
# Returns { correct, points, correct_answer } so the screen can briefly show the answer.
func time_out() -> Dictionary:
	var answer := current_item().correct_answer()  # The right number to show.
	return _finish_item(false, 0.0, time_limit(), answer)  # Wrong, 0 points, full time used.


# Shared end-of-item step for an answer or a time-out: updates streak, score, time and position.
func _finish_item(is_correct: bool, seconds_left: float, used: float, answer: int) -> Dictionary:
	if is_correct:  # A correct answer ...
		correct_count += 1  # ... counts towards Stars ...
		streak += 1  # ... and grows the streak.
	else:  # A wrong answer or time-out ...
		streak = 0  # ... ends the streak.
	var points := Scoring.points_for(is_correct, seconds_left, streak)  # Points for this item (D-008).
	score += points  # Add them; points are never taken away.
	total_time += used  # Add the seconds used.
	results.append(is_correct)  # Remember the result for the progress dots.
	index += 1  # Move to the next item.
	return {"correct": is_correct, "points": points, "correct_answer": answer}  # Feedback for the screen.


# Returns true once all items have been answered or timed out.
func is_finished() -> bool:
	return index >= items.size()  # Past the last item.


# Returns the Stars earned in this play (0 to 3).
func stars() -> int:
	return StarRules.stars_for(correct_count)  # 8 = 1, 9 = 2, 10 = 3 (D-008).


# Returns true when this play passed the Level.
func passed() -> bool:
	return StarRules.is_pass(correct_count)  # At least one Star.
