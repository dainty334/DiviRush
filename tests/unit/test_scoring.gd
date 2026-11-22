# Tests for the points rules in D-008 and D-010.
extends GutTest  # GUT gives this script its assert_* checks.


# A correct answer earns 10 points plus 1 point per whole second left.
func test_correct_answer_earns_ten_plus_whole_seconds_left() -> void:
	assert_eq(Scoring.points_for(true, 10.0, 1), 20)  # 10 + 10 seconds left = 20.


# Only whole seconds count, so 9.7 seconds left gives 9 extra points.
func test_part_of_a_second_does_not_count() -> void:
	assert_eq(Scoring.points_for(true, 9.7, 1), 19)  # 10 + 9 whole seconds = 19.


# A correct answer with under one second left still earns the base 10.
func test_correct_answer_with_no_whole_second_left_earns_ten() -> void:
	assert_eq(Scoring.points_for(true, 0.4, 1), 10)  # 10 + 0 whole seconds = 10.


# A wrong answer earns 0 points, even with time left.
func test_wrong_answer_earns_zero() -> void:
	assert_eq(Scoring.points_for(false, 12.0, 0), 0)  # Wrong = 0 points.


# The 3rd correct answer in a row earns no bonus yet (D-010).
func test_third_in_a_row_has_no_streak_bonus() -> void:
	assert_eq(Scoring.points_for(true, 5.0, 3), 15)  # 10 + 5 seconds, no bonus.


# The 4th correct answer in a row is the first to earn +5 (D-010).
func test_fourth_in_a_row_earns_streak_bonus() -> void:
	assert_eq(Scoring.points_for(true, 5.0, 4), 20)  # 10 + 5 seconds + 5 bonus.


# Every correct answer after the 4th also earns the same +5, not more.
func test_later_answers_in_a_streak_earn_the_same_bonus() -> void:
	assert_eq(Scoring.points_for(true, 5.0, 7), 20)  # Still only +5 at a streak of 7.


# Points never go below zero, even if the time left is negative by mistake.
func test_points_never_go_below_base() -> void:
	assert_eq(Scoring.points_for(true, -3.0, 1), 10)  # Negative time counts as 0 seconds.
