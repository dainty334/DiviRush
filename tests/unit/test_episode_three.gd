# Tests for the Episode 3 item bank (÷6, ÷7, ÷8, ÷9): its 5 Levels and every item's wrong answers (D-012).
extends GutTest  # GUT gives this script its assert_* checks.

const EPISODE_3 := "res://resources/episodes/episode_3.tres"  # The Episode 3 item bank file.
const Rules := preload("res://tests/helpers/answer_rules.gd")  # Shared checks for the D-011 rules.
const LEVEL_DIVISORS := [6, 7, 8, 9]  # Levels 1 to 4 in counting order, one divisor each (D-012).
const LEVEL_5_MIX := {6: 2, 7: 3, 8: 3, 9: 2}  # Level 5 review: divisor -> how many facts (D-012).

var episode: EpisodeData  # The Episode 3 item bank, loaded fresh for each test.


# Runs before every test: load the item bank.
func before_each() -> void:
	episode = load(EPISODE_3)  # Load the file Godot wrote.


# Returns the facts of one Level as "divisor:quotient" texts, sorted, so tests can compare them.
func _facts(level_number: int) -> Array[String]:
	var facts: Array[String] = []  # The list to fill.
	for item: DivisionItem in episode.levels[level_number - 1].items:  # Each item in the Level.
		facts.append("%d:%d" % [item.divisor, item.quotient])  # For example "7:8" for 56 ÷ 7.
	facts.sort()  # Same order every time.
	return facts  # Hand back the list.


# Returns the expected facts for one divisor with answers 1 to 10, in the same form as _facts().
func _table(divisor: int) -> Array[String]:
	var facts: Array[String] = []  # The list to fill.
	for quotient: int in range(1, 11):  # Answers 1 to 10 ...
		facts.append("%d:%d" % [divisor, quotient])  # ... each one fact.
	facts.sort()  # Same order as _facts().
	return facts  # Hand back the list.


# Episode 3 is built: 5 Levels of 10 items each (D-007, D-008).
func test_episode_three_has_five_levels_of_ten() -> void:
	assert_true(episode.is_built())  # It has Levels now.
	assert_eq(episode.levels.size(), 5)  # 5 Levels.
	for level: LevelData in episode.levels:  # Check each Level.
		assert_eq(level.items.size(), 10)  # 10 items each.


# Levels 1 to 4 are ÷6, ÷7, ÷8 and ÷9 in that order, each with answers 1 to 10 (D-012).
func test_levels_one_to_four_are_single_tables_in_order() -> void:
	assert_eq(episode.levels.size(), 5)  # Stop here with a clear message if the Levels are missing.
	if episode.levels.size() != 5:  # Not built yet ...
		return  # ... so the checks below would crash.
	for i in range(LEVEL_DIVISORS.size()):  # Levels 1 to 4.
		assert_eq(_facts(i + 1), _table(LEVEL_DIVISORS[i]), "Level %d" % (i + 1))  # Every fact of its divisor once.


# Level 5 is a mixed review of 2 ÷6, 3 ÷7, 3 ÷8 and 2 ÷9 facts, none repeated (D-012).
func test_level_five_follows_the_mix() -> void:
	assert_eq(episode.levels.size(), 5)  # Stop here with a clear message if the Levels are missing.
	if episode.levels.size() != 5:  # Not built yet ...
		return  # ... so the checks below would crash.
	var counts := {}  # How many facts of each divisor.
	for item: DivisionItem in episode.levels[4].items:  # Each item in Level 5.
		counts[item.divisor] = counts.get(item.divisor, 0) + 1  # Count its divisor.
	assert_eq(counts, LEVEL_5_MIX)  # 2, 3, 3 and 2, and no other divisor.
	var facts := _facts(5)  # The facts, sorted.
	for i in range(1, facts.size()):  # Each fact after the first ...
		assert_ne(facts[i], facts[i - 1])  # ... differs from the one before, so none repeats.


# No Level card needs its own label: Levels 1-4 show "÷6" to "÷9" and Level 5 shows "Mix" (D-012).
func test_levels_have_no_card_labels() -> void:
	assert_eq(episode.levels.size(), 5)  # The Levels must exist for this check to mean anything.
	for level: LevelData in episode.levels:  # Each Level.
		assert_eq(level.label, "")  # Empty, so the card works its text out from the items.


# Every item divides evenly, stays within 90, and has Easy, Medium and Hard wrong answers by the rules.
func test_every_item_is_valid_for_every_difficulty() -> void:
	assert_eq(episode.levels.size(), 5)  # The Levels must exist for this check to mean anything.
	for level: LevelData in episode.levels:  # Each Level.
		for item: DivisionItem in level.items:  # Each item.
			assert_eq(item.dividend, item.divisor * item.quotient)  # Divides evenly.
			assert_lte(item.dividend, 90)  # 9 x 10 = 90 is the largest Episode 3 dividend, inside D-007's 100.
			assert_eq(item.wrong_easy.size(), 2)  # 2 wrong answers for 3 Easy bubbles.
			if item.wrong_easy.size() == 2:  # Only compare when both are there, so a short list fails cleanly.
				assert_ne(item.wrong_easy[0], item.wrong_easy[1])  # Different from each other.
			for value: int in item.wrong_easy:  # Each Easy wrong answer ...
				assert_between(value, 1, 20)  # ... is inside 1 to 20 ...
				assert_gte(absi(value - item.quotient), 3)  # ... and far from the answer (D-010).
			assert_eq(Rules.problem(item.quotient, item.wrong_medium, 3), "")  # Medium: closest first.
			assert_eq(Rules.problem(item.quotient, item.wrong_hard, 3, item.divisor), "")  # Hard: divisor, then next facts.


# Episode 3 can be played on Easy, Medium and Hard, so its cards no longer show "Soon".
func test_episode_three_is_playable_on_every_difficulty() -> void:
	for kind: int in [Difficulty.Kind.EASY, Difficulty.Kind.MEDIUM, Difficulty.Kind.HARD]:  # Each Difficulty.
		assert_true(Game.is_playable(3, kind), Difficulty.name_of(kind))  # Enough wrong answers for its bubbles.
