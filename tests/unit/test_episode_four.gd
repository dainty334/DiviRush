# Tests for the Episode 4 item bank (Fact Families): its 5 Levels, which number each item hides,
# and every item's wrong answers (D-013).
extends GutTest  # GUT gives this script its assert_* checks.

const EPISODE_4 := "res://resources/episodes/episode_4.tres"  # The Episode 4 item bank file.
const Rules := preload("res://tests/helpers/answer_rules.gd")  # Shared checks for the D-011 and D-013 rules.
const Q := DivisionItem.Hidden.QUOTIENT  # Short name: 56 ÷ 8 = ?.
const D := DivisionItem.Hidden.DIVISOR  # Short name: 56 ÷ ☐ = 7.
const N := DivisionItem.Hidden.DIVIDEND  # Short name: ☐ ÷ 8 = 7.
const LEVEL_KINDS := [{Q: 10}, {D: 10}, {N: 10}, {D: 5, N: 5}, {Q: 2, D: 4, N: 4}]  # Hidden kinds in Levels 1-5 (D-013).
const LABELS := ["÷ ?", "÷ ☐", "☐ ÷", "Mix ☐", "Mix"]  # Level card labels (D-013 working values).

var episode: EpisodeData  # The Episode 4 item bank, loaded fresh for each test.


# Runs before every test: load the item bank.
func before_each() -> void:
	episode = load(EPISODE_4)  # Load the file Godot wrote.


# Returns true when the 5 Levels exist; otherwise fails the test with a clear message.
func _built() -> bool:
	assert_eq(episode.levels.size(), 5, "Episode 4 needs 5 Levels")  # Fails cleanly when not built.
	return episode.levels.size() == 5  # Tells the test whether it may go on.


# Episode 4 is built: 5 Levels of 10 items each (D-007, D-008).
func test_episode_four_has_five_levels_of_ten() -> void:
	if not _built():  # Not built yet ...
		return  # ... so the checks below would crash.
	for level: LevelData in episode.levels:  # Check each Level.
		assert_eq(level.items.size(), 10)  # 10 items each.


# Every Level has exactly one fact from each table ÷1 to ÷10 (D-013).
func test_every_level_has_one_fact_per_table() -> void:
	if not _built():  # Not built yet ...
		return  # ... so the checks below would crash.
	for level: LevelData in episode.levels:  # Each Level.
		var divisors: Array[int] = []  # Its divisors.
		for item: DivisionItem in level.items:  # Each item ...
			divisors.append(item.divisor)  # ... adds its divisor.
		divisors.sort()  # Smallest first.
		assert_eq(divisors, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "Level %d" % level.number)  # Each table once.


# No fact appears twice in the whole Episode, so 50 different facts are used (D-013).
func test_no_fact_repeats_across_levels() -> void:
	if not _built():  # Not built yet ...
		return  # ... so the checks below would crash.
	var seen := {}  # Facts met so far, as "divisor:quotient".
	for level: LevelData in episode.levels:  # Each Level.
		for item: DivisionItem in level.items:  # Each item.
			var fact := "%d:%d" % [item.divisor, item.quotient]  # For example "8:7" for 56 ÷ 8.
			assert_false(seen.has(fact), "%s repeats" % fact)  # Not met before.
			seen[fact] = true  # Remember it.
	assert_eq(seen.size(), 50)  # 5 Levels x 10 facts.


# Each Level hides the numbers set in D-013: L1 quotient, L2 divisor, L3 dividend, L4 5 / 5, L5 2 / 4 / 4.
func test_levels_hide_the_planned_numbers() -> void:
	if not _built():  # Not built yet ...
		return  # ... so the checks below would crash.
	for i in range(5):  # Levels 1 to 5.
		var counts := {}  # How many items hide each kind of number.
		for item: DivisionItem in episode.levels[i].items:  # Each item ...
			counts[item.hidden] = counts.get(item.hidden, 0) + 1  # ... counts its hidden kind.
		assert_eq(counts, LEVEL_KINDS[i], "Level %d" % (i + 1))  # The planned mix and no other kind.


# The Level cards show their own labels, since every Level mixes all ten tables (D-013).
func test_levels_have_card_labels() -> void:
	if not _built():  # Not built yet ...
		return  # ... so the checks below would crash.
	for i in range(5):  # Levels 1 to 5.
		assert_eq(episode.levels[i].label, LABELS[i])  # Its label.


# Every item divides evenly, stays within 100, and has wrong answers for every Difficulty by the
# rule for the number it hides (D-011 for a quotient or divisor, D-013 for a dividend).
func test_every_item_is_valid_for_every_difficulty() -> void:
	if not _built():  # Not built yet ...
		return  # ... so the checks below would crash.
	for level: LevelData in episode.levels:  # Each Level.
		for item: DivisionItem in level.items:  # Each item.
			assert_eq(item.dividend, item.divisor * item.quotient)  # Divides evenly.
			assert_lte(item.dividend, 100)  # D-007's largest dividend.
			if item.hidden == N:  # Hidden dividend: multiples rules (D-013).
				assert_eq(Rules.dividend_problem(item.divisor, item.quotient, item.wrong_easy, "easy"), "")  # Far multiples.
				assert_eq(Rules.dividend_problem(item.divisor, item.quotient, item.wrong_medium, "medium"), "")  # Nearest multiples.
				assert_eq(Rules.dividend_problem(item.divisor, item.quotient, item.wrong_hard, "hard"), "")  # Neighbouring facts.
				continue  # Next item.
			var answer := item.correct_answer()  # The quotient, or the divisor when it is hidden.
			var partner := item.divisor if item.hidden == Q else item.quotient  # The swapped fact's answer.
			assert_eq(item.wrong_easy.size(), 2)  # 2 wrong answers for 3 Easy bubbles.
			for value: int in item.wrong_easy:  # Each Easy wrong answer ...
				assert_between(value, 1, 20)  # ... is inside 1 to 20 ...
				assert_gte(absi(value - answer), 3)  # ... and far from the answer (D-010).
			if item.wrong_easy.size() == 2:  # Only compare when both are there.
				assert_ne(item.wrong_easy[0], item.wrong_easy[1])  # Different from each other.
			assert_eq(Rules.problem(answer, item.wrong_medium, 3), "")  # Medium: closest first.
			assert_eq(Rules.problem(answer, item.wrong_hard, 3, partner), "")  # Hard: partner, then next facts.


# Missing-number items show a ☐ where the hidden number goes, and the full fact after an answer.
func test_missing_number_items_show_a_box() -> void:
	var item := DivisionItem.new()  # A new item.
	item.dividend = 56  # 56 ...
	item.divisor = 8  # ... divided by 8 ...
	item.quotient = 7  # ... is 7.
	item.hidden = D  # Hide the divisor.
	assert_eq(item.question_text(), "56 ÷ ☐ = 7")  # The card text.
	assert_eq(item.correct_answer(), 8)  # The learner must tap 8.
	item.hidden = N  # Hide the dividend.
	assert_eq(item.question_text(), "☐ ÷ 8 = 7")  # The card text.
	assert_eq(item.correct_answer(), 56)  # The learner must tap 56.
	assert_eq(item.answered_text(), "56 ÷ 8 = 7")  # The full fact after an answer.


# A hidden-dividend item on Hard gives 4 choices that include the dividend and its stored wrong answers.
func test_level_run_offers_the_hidden_dividend() -> void:
	var item := DivisionItem.new()  # ☐ ÷ 8 = 7.
	item.divisor = 8  # Divides by 8.
	item.quotient = 7  # Answer 7.
	item.dividend = 56  # The hidden number.
	item.hidden = N  # Hide the dividend.
	item.wrong_hard = [49, 63, 48]  # Neighbouring facts.
	var items: Array[DivisionItem] = [item]  # A one-item play.
	var run := LevelRun.new(items, Difficulty.Kind.HARD)  # A Hard play.
	var choices := run.choices()  # The bubble numbers.
	choices.sort()  # Smallest first.
	assert_eq(choices, [48, 49, 56, 63])  # The answer and its 3 wrong answers.
	assert_true(run.submit_answer(56, 3.0).correct)  # Tapping 56 is right.


# Episode 4 can be played on Easy, Medium and Hard, so its cards no longer show "Soon".
func test_episode_four_is_playable_on_every_difficulty() -> void:
	for kind: int in [Difficulty.Kind.EASY, Difficulty.Kind.MEDIUM, Difficulty.Kind.HARD]:  # Each Difficulty.
		assert_true(Game.is_playable(4, kind), Difficulty.name_of(kind))  # Enough wrong answers for its bubbles.
