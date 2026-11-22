# Tests for the Episode 2 item bank (÷3, ÷4): its 5 Levels and every item's wrong answers (D-011).
extends GutTest  # GUT gives this script its assert_* checks.

const EPISODE_2 := "res://resources/episodes/episode_2.tres"  # The Episode 2 item bank file.
const Rules := preload("res://tests/helpers/answer_rules.gd")  # Shared checks for the D-011 rules.

var episode: EpisodeData  # The Episode 2 item bank, loaded fresh for each test.


# Runs before every test: load the item bank.
func before_each() -> void:
	episode = load(EPISODE_2)  # Load the file Godot wrote.


# Returns the facts of one Level as "divisor:quotient" texts, sorted, so tests can compare them.
func _facts(level_number: int) -> Array[String]:
	var facts: Array[String] = []  # The list to fill.
	for item in episode.levels[level_number - 1].items:  # Each item in the Level.
		facts.append("%d:%d" % [item.divisor, item.quotient])  # For example "3:7" for 21 ÷ 3.
	facts.sort()  # Same order every time.
	return facts  # Hand back the list.


# Returns the expected facts for some divisors and quotients, in the same form as _facts().
func _expected(divisors: Array, quotients: Array) -> Array[String]:
	var facts: Array[String] = []  # The list to fill.
	for divisor in divisors:  # Each divisor ...
		for quotient in quotients:  # ... with each quotient ...
			facts.append("%d:%d" % [divisor, quotient])  # ... is one fact.
	facts.sort()  # Same order as _facts().
	return facts  # Hand back the list.


# Episode 2 is built: 5 Levels of 10 items each (D-007, D-008).
func test_episode_two_has_five_levels_of_ten() -> void:
	assert_true(episode.is_built())  # It has Levels now.
	assert_eq(episode.levels.size(), 5)  # 5 Levels.
	for level in episode.levels:  # Check each Level.
		assert_eq(level.items.size(), 10)  # 10 items each.


# Level 1 is ÷3 and Level 2 is ÷4, each with answers 1 to 10 (D-011).
func test_levels_one_and_two_are_single_tables() -> void:
	assert_eq(_facts(1), _expected([3], range(1, 11)))  # ÷3, every fact once.
	assert_eq(_facts(2), _expected([4], range(1, 11)))  # ÷4, every fact once.


# Level 3 is ÷3 and ÷4 with answers 1-5; Level 4 is ÷3 and ÷4 with answers 6-10 (D-011).
func test_levels_three_and_four_are_halves() -> void:
	assert_eq(_facts(3), _expected([3, 4], range(1, 6)))  # Answers 1 to 5 of both tables.
	assert_eq(_facts(4), _expected([3, 4], range(6, 11)))  # Answers 6 to 10 of both tables.


# Level 5 is a mixed review: 5 ÷3 facts and 5 ÷4 facts, none repeated (D-011).
func test_level_five_mixes_five_of_each() -> void:
	var counts := {3: 0, 4: 0}  # How many facts of each divisor.
	for item in episode.levels[4].items:  # Each item in Level 5.
		counts[item.divisor] += 1  # Count its divisor (any other divisor would crash the test).
	assert_eq(counts, {3: 5, 4: 5})  # 5 of each.
	var facts := _facts(5)  # The facts, sorted.
	for i in range(1, facts.size()):  # Each fact after the first ...
		assert_ne(facts[i], facts[i - 1])  # ... differs from the one before, so none repeats.


# Levels 3 and 4 show their answer range on the Level card, since "Mix" alone would not tell them apart.
func test_half_levels_have_card_labels() -> void:
	assert_eq(episode.levels[2].label, "Mix 1–5")  # Level 3.
	assert_eq(episode.levels[3].label, "Mix 6–10")  # Level 4.


# Every item divides evenly, stays within 100, and has Easy, Medium and Hard wrong answers by the rules.
func test_every_item_is_valid_for_every_difficulty() -> void:
	for level in episode.levels:  # Each Level.
		for item in level.items:  # Each item.
			assert_eq(item.dividend, item.divisor * item.quotient)  # Divides evenly.
			assert_lte(item.dividend, 100)  # Dividend 100 or less (D-007).
			assert_eq(item.wrong_easy.size(), 2)  # 2 wrong answers for 3 Easy bubbles.
			assert_ne(item.wrong_easy[0], item.wrong_easy[1])  # Different from each other.
			for value in item.wrong_easy:  # Each Easy wrong answer ...
				assert_between(value, 1, 20)  # ... is inside 1 to 20 ...
				assert_gte(absi(value - item.quotient), 3)  # ... and far from the answer (D-010).
			assert_eq(Rules.problem(item.quotient, item.wrong_medium, 3), "")  # Medium: closest first.
			assert_eq(Rules.problem(item.quotient, item.wrong_hard, 3, item.divisor), "")  # Hard: divisor, then next facts.
