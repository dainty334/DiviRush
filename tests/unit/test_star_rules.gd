# Tests for the Star and Pass rules in D-008: 8 = 1 Star, 9 = 2, 10 = 3, 0-7 = not passed.
extends GutTest  # GUT gives this script its assert_* checks.


# 0 to 7 correct answers earn no Star.
func test_zero_to_seven_correct_earn_no_star() -> void:
	for correct in range(0, 8):  # Check every count from 0 to 7.
		assert_eq(StarRules.stars_for(correct), 0, "correct = %d" % correct)  # Each must give 0 Stars.


# 8 correct answers earn 1 Star, the pass mark.
func test_eight_correct_earn_one_star() -> void:
	assert_eq(StarRules.stars_for(8), 1)  # 8 of 10 = 1 Star.


# 9 correct answers earn 2 Stars.
func test_nine_correct_earn_two_stars() -> void:
	assert_eq(StarRules.stars_for(9), 2)  # 9 of 10 = 2 Stars.


# 10 correct answers earn 3 Stars.
func test_ten_correct_earn_three_stars() -> void:
	assert_eq(StarRules.stars_for(10), 3)  # 10 of 10 = 3 Stars.


# 7 correct is not a Pass; 8 correct is a Pass.
func test_pass_starts_at_eight_correct() -> void:
	assert_false(StarRules.is_pass(7))  # 7 of 10 is not passed.
	assert_true(StarRules.is_pass(8))  # 8 of 10 is passed.
