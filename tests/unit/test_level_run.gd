# Tests for one play of a Level: answers, time-outs, score, streak and the end result.
extends GutTest  # GUT gives this script its assert_* checks.

const EASY := Difficulty.Kind.EASY  # Short name for Easy.
const MEDIUM := Difficulty.Kind.MEDIUM  # Short name for Medium.
const HARD := Difficulty.Kind.HARD  # Short name for Hard.

var run: LevelRun  # A fresh play for each test.


# Makes 10 simple items: 2 ÷ 1 = 2, 4 ÷ 2 = 2, ... so each test has a full Level.
func _make_items() -> Array[DivisionItem]:
	var items: Array[DivisionItem] = []  # The list to fill.
	for quotient in range(1, 11):  # Quotients 1 to 10.
		var item := DivisionItem.new()  # A new item.
		item.divisor = 2  # Every item divides by 2.
		item.quotient = quotient  # The answer.
		item.dividend = 2 * quotient  # The number being divided.
		item.wrong_easy = [quotient + 5, quotient + 9]  # Two far wrong answers.
		item.wrong_medium = [quotient + 1, quotient + 2, quotient + 3]  # Three near wrong answers.
		item.wrong_hard = [quotient + 1, quotient + 2, quotient + 4]  # Three Hard wrong answers.
		items.append(item)  # Add it to the list.
	return items  # Hand back all 10 items.


# Makes a random number maker with a fixed seed, so a test gives the same result every time.
func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()  # A new random number maker.
	rng.seed = seed_value  # Fix its seed.
	return rng  # Hand it back.


# Runs before every test: start a new Easy play with seed 1.
func before_each() -> void:
	run = LevelRun.new(_make_items(), EASY, _rng(1))  # New play.


# Answers the current item correctly with the given seconds left.
func _answer_right(seconds_left: float) -> Dictionary:
	return run.submit_answer(run.current_item().correct_answer(), seconds_left)  # Tap the right bubble.


# Answers the current item wrongly with the given seconds left.
func _answer_wrong(seconds_left: float) -> Dictionary:
	return run.submit_answer(run.current_item().correct_answer() + 100, seconds_left)  # Tap a wrong number.


# The play keeps all 10 items, but the order is shuffled by the seed.
func test_items_are_shuffled_each_play() -> void:
	var other := LevelRun.new(_make_items(), EASY, _rng(99))  # A second play with another seed.
	var order_a := run.items.map(func(item: DivisionItem) -> int: return item.quotient)  # First play's order.
	var order_b := other.items.map(func(item: DivisionItem) -> int: return item.quotient)  # Second play's order.
	assert_eq(run.items.size(), 10)  # Still 10 items.
	assert_ne(order_a, order_b)  # Different plays, different order.
	var sorted_a := order_a.duplicate()  # Copy the order to sort it.
	sorted_a.sort()  # Sort it.
	assert_eq(sorted_a, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])  # No item lost or repeated.


# Easy items show 3 answer bubbles: the correct answer and 2 wrong ones, all different.
func test_easy_shows_three_different_choices_with_the_answer() -> void:
	var choices := run.choices()  # The numbers on the bubbles.
	assert_eq(choices.size(), 3)  # Easy has 3 bubbles (D-008).
	assert_has(choices, run.current_item().correct_answer())  # One is correct.
	var unique := {}  # Collect each number once.
	for value in choices:  # Look at each bubble.
		unique[value] = true  # Remember it.
	assert_eq(unique.size(), 3)  # No two bubbles show the same number.


# Medium and Hard items show 4 bubbles: the answer and that Difficulty's 3 wrong ones, all different.
func test_medium_and_hard_show_four_different_choices_with_the_answer() -> void:
	for kind in [MEDIUM, HARD]:  # Both 4-bubble Difficulties.
		var play := LevelRun.new(_make_items(), kind, _rng(3))  # A new play at this Difficulty.
		var item := play.current_item()  # The item showing now.
		var choices := play.choices()  # The numbers on the bubbles.
		assert_eq(choices.size(), 4)  # 4 bubbles (D-008).
		assert_has(choices, item.correct_answer())  # One is correct.
		for wrong in item.wrong_for(kind):  # This Difficulty's own wrong answers ...
			assert_has(choices, wrong)  # ... are all on the bubbles.


# Medium gives 10 seconds per item and Hard gives 7 (D-008 starting values).
func test_medium_and_hard_time_limits() -> void:
	assert_eq(LevelRun.new(_make_items(), MEDIUM, _rng(1)).time_limit(), 10.0)  # Medium: 10 s.
	assert_eq(LevelRun.new(_make_items(), HARD, _rng(1)).time_limit(), 7.0)  # Hard: 7 s.


# On Medium and Hard a time-out still counts as wrong and uses that Difficulty's full time.
func test_time_out_on_medium_and_hard_counts_as_wrong() -> void:
	for kind in [MEDIUM, HARD]:  # Both Difficulties.
		var play := LevelRun.new(_make_items(), kind, _rng(5))  # A new play.
		var result := play.time_out()  # The timer ran out.
		assert_false(result.correct)  # Counts as wrong.
		assert_eq(result.points, 0)  # 0 points.
		assert_eq(play.correct_count, 0)  # Not counted as correct.
		assert_almost_eq(play.total_time, Difficulty.time_limit(kind), 0.001)  # The full 10 s or 7 s used.


# Easy gives 15 seconds per item.
func test_easy_time_limit_is_fifteen_seconds() -> void:
	assert_eq(run.time_limit(), 15.0)  # 15 s per item (D-008).


# A correct answer adds points and counts as correct.
func test_correct_answer_adds_points() -> void:
	var result := _answer_right(10.0)  # Right with 10 s left.
	assert_true(result.correct)  # Marked correct.
	assert_eq(result.points, 20)  # 10 + 10 seconds.
	assert_eq(run.score, 20)  # Score is now 20.
	assert_eq(run.correct_count, 1)  # One correct so far.


# A wrong answer adds 0, never takes points away, and ends the streak.
func test_wrong_answer_keeps_score_and_ends_streak() -> void:
	_answer_right(5.0)  # 15 points.
	_answer_right(5.0)  # 15 more points: score 30, streak 2.
	var result := _answer_wrong(5.0)  # Now a wrong answer.
	assert_false(result.correct)  # Marked wrong.
	assert_eq(result.points, 0)  # 0 points.
	assert_eq(run.score, 30)  # Score did not go down.
	assert_eq(run.streak, 0)  # Streak is back to 0.


# A time-out counts as wrong and gives the correct answer so the screen can show it.
func test_time_out_counts_as_wrong_and_gives_correct_answer() -> void:
	var expected := run.current_item().correct_answer()  # The answer for this item.
	var result := run.time_out()  # The timer ran out.
	assert_false(result.correct)  # Counts as wrong.
	assert_eq(result.points, 0)  # 0 points.
	assert_eq(result.correct_answer, expected)  # The correct answer to show.
	assert_eq(run.correct_count, 0)  # Not counted as correct.
	assert_eq(run.index, 1)  # The play moved on to the next item.


# The streak bonus starts on the 4th correct answer in a row.
func test_streak_bonus_starts_on_fourth_in_a_row() -> void:
	for i in range(3):  # Three right answers with no time left.
		_answer_right(0.0)  # Each earns 10.
	var fourth := _answer_right(0.0)  # The 4th in a row.
	assert_eq(fourth.points, 15)  # 10 + 5 streak bonus.
	assert_eq(run.score, 45)  # 10 + 10 + 10 + 15.


# Total time adds the time used on each item; a time-out uses the full 15 s.
func test_total_time_adds_time_used_per_item() -> void:
	_answer_right(10.0)  # Used 5 s.
	run.time_out()  # Used all 15 s.
	assert_almost_eq(run.total_time, 20.0, 0.001)  # 5 + 15 = 20 s.


# After 10 items the play is finished, and 8 correct earns 1 Star and a Pass.
func test_finished_play_with_eight_correct_passes() -> void:
	for i in range(8):  # 8 right answers.
		assert_false(run.is_finished())  # Not finished yet.
		_answer_right(5.0)  # Answer right.
	_answer_wrong(5.0)  # 1 wrong answer.
	run.time_out()  # 1 time-out.
	assert_true(run.is_finished())  # All 10 items done.
	assert_eq(run.stars(), 1)  # 8 correct = 1 Star.
	assert_true(run.passed())  # The Level is passed.


# After 10 items with 7 correct the play is not passed.
func test_finished_play_with_seven_correct_does_not_pass() -> void:
	for i in range(7):  # 7 right answers.
		_answer_right(5.0)  # Answer right.
	for i in range(3):  # 3 wrong answers.
		_answer_wrong(5.0)  # Answer wrong.
	assert_true(run.is_finished())  # All 10 items done.
	assert_eq(run.stars(), 0)  # 7 correct = no Star.
	assert_false(run.passed())  # Not passed.
