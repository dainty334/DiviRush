# Tests for the wrong answers of Episode 4 missing-number items (D-013):
# a hidden dividend (☐ ÷ 8 = 7) and a hidden divisor (56 ÷ ☐ = 7).
extends GutTest  # GUT gives this script its assert_* checks.

const Rules := preload("res://tests/helpers/answer_rules.gd")  # Shared checks for the D-011 and D-013 rules.
const SEEDS := 20  # How many random seeds each rule is tried with.


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


# For every fact ÷1-÷10 and many seeds, the three hidden-dividend rules hold.
func test_dividend_rules_hold_for_every_fact() -> void:
	for divisor in range(1, 11):  # Every table.
		for quotient in range(1, 11):  # Every answer in it.
			for seed_value in range(SEEDS):  # Many random seeds.
				var easy := WrongAnswers.far_multiples(divisor, quotient, 2, _rng(seed_value))  # 2 Easy answers.
				var medium := WrongAnswers.near_multiples(divisor, quotient, 3, _rng(seed_value))  # 3 Medium answers.
				var hard := WrongAnswers.neighbour_facts(divisor, quotient, 3, _rng(seed_value))  # 3 Hard answers.
				assert_eq(Rules.dividend_problem(divisor, quotient, easy, "easy"), "")  # "" means every rule holds.
				assert_eq(Rules.dividend_problem(divisor, quotient, medium, "medium"), "")  # Nearest multiples.
				assert_eq(Rules.dividend_problem(divisor, quotient, hard, "hard"), "")  # Neighbouring facts first.


# ☐ ÷ 8 = 7 on Medium gets 48 and 64, and then 40 or 72 (D-013 example).
func test_near_multiples_for_56() -> void:
	for seed_value in range(SEEDS):  # Many random seeds.
		var wrong := WrongAnswers.near_multiples(8, 7, 3, _rng(seed_value))  # Three Medium answers.
		assert_has(wrong, 48)  # 8 x 6.
		assert_has(wrong, 64)  # 8 x 8.
		assert_true(wrong.has(40) or wrong.has(72))  # Then one multiple 2 steps away.


# ☐ ÷ 8 = 7 on Hard gets 49 (7 x 7) and 63 (9 x 7), then 48 or 64 (D-013 example).
func test_neighbour_facts_for_56() -> void:
	for seed_value in range(SEEDS):  # Many random seeds.
		var wrong := WrongAnswers.neighbour_facts(8, 7, 3, _rng(seed_value))  # Three Hard answers.
		assert_has(wrong, 49)  # The ÷7 table's fact.
		assert_has(wrong, 63)  # The ÷9 table's fact.
		assert_true(wrong.has(48) or wrong.has(64))  # Then a fact just before or after in the ÷8 table.


# ☐ ÷ 1 = 7 on Hard: 0 x 7 cannot be shown, so it gets 14, 6 and 8 (D-013 example).
func test_neighbour_facts_for_7_div_1() -> void:
	assert_eq(_sorted(WrongAnswers.neighbour_facts(1, 7, 3, _rng(1))), [6, 8, 14])  # 14, 6, 8.


# ☐ ÷ 10 = 10 on Hard: 110 is too big and 90 repeats, so it gets 90, 80 and 70 (D-013 example).
func test_neighbour_facts_for_100() -> void:
	assert_eq(_sorted(WrongAnswers.neighbour_facts(10, 10, 3, _rng(1))), [70, 80, 90])  # 90, 80, 70.


# ☐ ÷ 10 = 10 on Easy gets multiples of 10 at least 3 steps away, so 70 or less.
func test_far_multiples_for_100() -> void:
	for seed_value in range(SEEDS):  # Many random seeds.
		for value in WrongAnswers.far_multiples(10, 10, 2, _rng(seed_value)):  # Each Easy answer.
			assert_eq(value % 10, 0)  # A multiple of 10.
			assert_lte(value, 70)  # At least 3 multiples below 100.


# 56 ÷ ☐ = 7 (hidden divisor 8) uses the D-011 rules with the quotient as the partner: 7, 9, and 6 or 10.
func test_hidden_divisor_uses_the_quotient_as_partner() -> void:
	for seed_value in range(SEEDS):  # Many random seeds.
		var wrong := WrongAnswers.look_alike(8, 7, 3, _rng(seed_value))  # Hard answers for divisor 8, partner 7.
		assert_eq(Rules.problem(8, wrong, 3, 7), "")  # The D-011 Hard rule holds.
		assert_has(wrong, 7)  # The quotient, the fact family partner.
		assert_has(wrong, 9)  # 1 above.
		assert_true(wrong.has(6) or wrong.has(10))  # 7 is both partner and 8 - 1, so a number 2 away fills the gap.
