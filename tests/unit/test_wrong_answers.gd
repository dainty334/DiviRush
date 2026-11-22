# Tests for the Medium "near" and Hard "look-alike" wrong answers (D-011).
extends GutTest  # GUT gives this script its assert_* checks.

const Rules := preload("res://tests/helpers/answer_rules.gd")  # Shared checks for the D-011 rules.
const SEEDS := 30  # How many random seeds each rule is tried with.


# Makes a random number maker with a fixed seed, so a test gives the same result every time.
func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()  # A new random number maker.
	rng.seed = seed_value  # Fix its seed.
	return rng  # Hand it back.


# Returns a sorted copy of a list, so tests can compare lists whatever their order.
func _sorted(values: Array[int]) -> Array[int]:
	var copy: Array[int] = values.duplicate()  # Copy, so the original keeps its order.
	copy.sort()  # Smallest first.
	return copy  # Hand back the sorted copy.


# For every answer 1-10 and many seeds, near() gives 3 answers that follow the Medium rule.
func test_near_follows_the_medium_rule_for_every_answer() -> void:
	for correct in range(1, 11):  # Every possible answer, 1 to 10.
		for seed_value in range(SEEDS):  # Many random seeds.
			var wrong := WrongAnswers.near(correct, 3, _rng(seed_value))  # Three near answers.
			assert_eq(Rules.problem(correct, wrong, 3), "")  # "" means every rule holds.


# 35 ÷ 5 = 7 gets 6 and 8, and then 5 or 9 (D-011 example).
func test_near_for_seven_takes_both_neighbours_first() -> void:
	for seed_value in range(SEEDS):  # Many random seeds.
		var wrong := WrongAnswers.near(7, 3, _rng(seed_value))  # Three near answers for 7.
		assert_has(wrong, 6)  # 1 below.
		assert_has(wrong, 8)  # 1 above.
		assert_true(wrong.has(5) or wrong.has(9))  # Then one number 2 away.


# Answer 1 cannot go below 1, so it gets 2, 3 and 4 (D-011 example).
func test_near_for_one_goes_upwards() -> void:
	assert_eq(_sorted(WrongAnswers.near(1, 3, _rng(1))), [2, 3, 4])  # The three nearest allowed numbers.


# Answer 10 may get 11, so the biggest bubble is not always right (D-011 example).
func test_near_for_ten_can_go_above_ten() -> void:
	var wrong := WrongAnswers.near(10, 3, _rng(1))  # Three near answers for 10.
	assert_has(wrong, 9)  # 1 below.
	assert_has(wrong, 11)  # 1 above, allowed in the 1-20 range.
	assert_true(wrong.has(8) or wrong.has(12))  # Then one number 2 away.


# Both sides 2 away come up over many seeds, so the third answer really is random.
func test_near_picks_the_third_answer_at_random() -> void:
	var thirds: Array[int] = []  # The third numbers seen, each once.
	for seed_value in range(SEEDS):  # Many random seeds.
		for value in WrongAnswers.near(7, 3, _rng(seed_value)):  # Each near answer for 7.
			if value != 6 and value != 8 and not thirds.has(value):  # A new third answer ...
				thirds.append(value)  # ... is remembered.
	assert_eq(_sorted(thirds), [5, 9])  # Both 5 and 9 appear.


# For every Episode 1 fact and many seeds, look_alike() follows the Hard rule.
func test_look_alike_follows_the_hard_rule_for_episode_one() -> void:
	for divisor in [1, 2, 5, 10]:  # The Episode 1 divisors.
		for quotient in range(1, 11):  # Every answer, 1 to 10.
			for seed_value in range(SEEDS):  # Many random seeds.
				var wrong := WrongAnswers.look_alike(quotient, divisor, 3, _rng(seed_value))  # Three Hard answers.
				assert_eq(Rules.problem(quotient, wrong, 3, divisor), "")  # "" means every rule holds.


# 35 ÷ 5 = 7 gets the fact family answer 5 and the next facts 6 and 8 (D-011 example).
func test_look_alike_for_35_div_5() -> void:
	assert_eq(_sorted(WrongAnswers.look_alike(7, 5, 3, _rng(1))), [5, 6, 8])  # 5, 6, 8.


# 70 ÷ 10 = 7 gets 10, 6 and 8 (D-011 example).
func test_look_alike_for_70_div_10() -> void:
	assert_eq(_sorted(WrongAnswers.look_alike(7, 10, 3, _rng(1))), [6, 8, 10])  # 10, 6, 8.


# 56 ÷ 8 = 7: 8 is both the divisor and 7 + 1, so the nearest unused number fills the gap.
func test_look_alike_fills_when_partner_is_a_neighbour() -> void:
	var wrong := WrongAnswers.look_alike(7, 8, 3, _rng(1))  # Three Hard answers for 56 ÷ 8.
	assert_has(wrong, 8)  # The fact family answer.
	assert_has(wrong, 6)  # 1 below.
	assert_true(wrong.has(5) or wrong.has(9))  # Filled with a number 2 away.


# 25 ÷ 5 = 5: the divisor is the answer itself, so it is skipped and the gap is filled.
func test_look_alike_skips_a_partner_equal_to_the_answer() -> void:
	var wrong := WrongAnswers.look_alike(5, 5, 3, _rng(1))  # Three Hard answers for 25 ÷ 5.
	assert_has(wrong, 4)  # 1 below.
	assert_has(wrong, 6)  # 1 above.
	assert_true(wrong.has(3) or wrong.has(7))  # Filled with a number 2 away.


# 2 ÷ 2 = 1 gets 2, 3 and 4 (D-011 example).
func test_look_alike_for_2_div_2() -> void:
	assert_eq(_sorted(WrongAnswers.look_alike(1, 2, 3, _rng(1))), [2, 3, 4])  # 2, then 3 and 4.
