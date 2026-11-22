# Tests for division items, far wrong answers and the Episode 1 item bank (D-007, D-008, D-010).
extends GutTest  # GUT gives this script its assert_* checks.

const EPISODE_1 := "res://resources/episodes/episode_1.tres"  # The Episode 1 item bank file.
const Rules := preload("res://tests/helpers/answer_rules.gd")  # Shared checks for the D-011 rules.


# An item shows its question as "56 ÷ 8 = ?" and its answer is the quotient.
func test_item_question_text_and_answer() -> void:
	var item := DivisionItem.new()  # A new item.
	item.dividend = 56  # 56 ...
	item.divisor = 8  # ... divided by 8 ...
	item.quotient = 7  # ... is 7.
	assert_eq(item.question_text(), "56 ÷ 8 = ?")  # The text on the item card.
	assert_eq(item.correct_answer(), 7)  # The hidden number is the quotient.
	assert_eq(item.answered_text(), "56 ÷ 8 = 7")  # The full fact shown after an answer.


# Far wrong answers are all different, between 1 and 20, and at least 3 from the answer.
func test_far_wrong_answers_follow_the_easy_rule() -> void:
	var rng := RandomNumberGenerator.new()  # A random number maker.
	rng.seed = 7  # Fixed seed so the test repeats exactly.
	for correct in range(1, 11):  # Every possible answer, 1 to 10.
		var wrong := WrongAnswers.far(correct, 2, rng)  # Two far wrong answers.
		assert_eq(wrong.size(), 2)  # Exactly two.
		assert_ne(wrong[0], wrong[1])  # Different from each other.
		for value in wrong:  # Check each wrong answer.
			assert_between(value, 1, 20)  # Inside 1 to 20.
			assert_gte(absi(value - correct), 3)  # At least 3 away from the answer.


# Episode 1 has 5 Levels of 10 items each.
func test_episode_one_has_five_levels_of_ten() -> void:
	var episode: EpisodeData = load(EPISODE_1)  # Load the item bank.
	assert_eq(episode.levels.size(), 5)  # 5 Levels.
	for level in episode.levels:  # Check each Level.
		assert_eq(level.items.size(), 10)  # 10 items each (D-007).


# Levels 1 to 4 each use one divisor: ÷1, ÷2, ÷5, ÷10, with quotients 1 to 10 (D-010).
func test_levels_one_to_four_use_one_divisor_each() -> void:
	var episode: EpisodeData = load(EPISODE_1)  # Load the item bank.
	var divisors := [1, 2, 5, 10]  # The divisor for Levels 1 to 4.
	for i in range(4):  # Levels 1 to 4.
		var quotients := []  # Collect the answers in this Level.
		for item in episode.levels[i].items:  # Each item in the Level.
			assert_eq(item.divisor, divisors[i])  # The Level's one divisor.
			quotients.append(item.quotient)  # Remember the answer.
		quotients.sort()  # Sort the answers.
		assert_eq(quotients, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])  # Every fact 1 to 10, once.


# Level 5 mixes all four divisors of Episode 1.
func test_level_five_mixes_all_divisors() -> void:
	var episode: EpisodeData = load(EPISODE_1)  # Load the item bank.
	var seen := {}  # Divisors found in Level 5.
	for item in episode.levels[4].items:  # Each item in Level 5.
		seen[item.divisor] = true  # Remember its divisor.
	assert_eq(seen.size(), 4)  # All of ÷1, ÷2, ÷5 and ÷10 appear.


# Every item divides evenly, stays within 100, and has 2 far Easy wrong answers.
func test_every_item_is_valid() -> void:
	var episode: EpisodeData = load(EPISODE_1)  # Load the item bank.
	for level in episode.levels:  # Each Level.
		for item in level.items:  # Each item.
			assert_eq(item.dividend, item.divisor * item.quotient)  # Divides evenly.
			assert_lte(item.dividend, 100)  # Dividend 100 or less (D-007).
			assert_eq(item.wrong_easy.size(), 2)  # 2 wrong answers for 3 Easy bubbles.
			for value in item.wrong_easy:  # Each wrong answer.
				assert_gte(absi(value - item.quotient), 3)  # Far from the answer.


# Every Episode 1 item has 3 Medium wrong answers that follow the "closest first" rule (D-011).
func test_every_item_has_medium_wrong_answers() -> void:
	var episode: EpisodeData = load(EPISODE_1)  # Load the item bank.
	for level in episode.levels:  # Each Level.
		for item in level.items:  # Each item.
			assert_eq(Rules.problem(item.quotient, item.wrong_medium, 3), "")  # "" means every rule holds.


# Every Episode 1 item has 3 Hard wrong answers: the divisor, then the next facts (D-011).
func test_every_item_has_hard_wrong_answers() -> void:
	var episode: EpisodeData = load(EPISODE_1)  # Load the item bank.
	for level in episode.levels:  # Each Level.
		for item in level.items:  # Each item.
			assert_eq(Rules.problem(item.quotient, item.wrong_hard, 3, item.divisor), "")  # "" means every rule holds.


# Each Difficulty has enough wrong answers to fill its bubbles, so none shows "Coming soon".
func test_every_difficulty_has_enough_wrong_answers() -> void:
	var episode: EpisodeData = load(EPISODE_1)  # Load the item bank.
	for kind in [Difficulty.Kind.EASY, Difficulty.Kind.MEDIUM, Difficulty.Kind.HARD]:  # Each Difficulty.
		var needed := Difficulty.bubble_count(kind) - 1  # Bubbles minus the correct one.
		for level in episode.levels:  # Each Level.
			for item in level.items:  # Each item.
				assert_eq(item.wrong_for(kind).size(), needed)  # Exactly enough wrong answers.
