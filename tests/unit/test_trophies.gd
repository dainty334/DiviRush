# Tests for the learner's game records and the twelve Trophies (D-023).
extends GutTest  # GUT gives this script its assert_* checks.

const EASY := Difficulty.Kind.EASY  # Short name for Easy.
const MEDIUM := Difficulty.Kind.MEDIUM  # Short name for Medium.
const HARD := Difficulty.Kind.HARD  # Short name for Hard.
const TEST_PATH := "user://test_records.cfg"  # A separate file, so tests never touch the real save.

var progress: Progress  # Fresh bests for each test.
var records: Records  # Fresh records for each test.


# Runs before every test: nothing played yet.
func before_each() -> void:
	progress = Progress.new()  # No bests.
	records = Records.new()  # No records.


# Runs after every test: delete the test file so each test starts clean.
func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):  # Only if the test made the file.
		DirAccess.remove_absolute(TEST_PATH)  # Delete it.


# Passes one Level with the given Stars (1 to 3), to keep the tests short.
func _record_pass(episode: int, difficulty: int, level: int, stars: int = 1) -> void:
	progress.record(episode, difficulty, level, stars, 100, 60.0)  # A passed play.


# Each play adds to the records: Levels played, correct answers and time add up; the best streak is the highest.
func test_records_add_up() -> void:
	records.add_play(8, 5, 60.0)  # A play: 8 correct, best streak 5, 60 s.
	records.add_play(10, 3, 45.5)  # Another: 10 correct, best streak 3, 45.5 s.
	assert_eq(records.levels_played, 2)  # Two Levels played.
	assert_eq(records.correct_total, 18)  # 8 + 10 correct answers.
	assert_eq(records.best_streak, 5)  # The best streak stays 5.
	assert_almost_eq(records.seconds_played, 105.5, 0.001)  # 60 + 45.5 seconds.


# A play remembers its best streak, even after the streak ends.
func test_level_run_keeps_its_best_streak() -> void:
	var items: Array[DivisionItem] = []  # Three simple items.
	for quotient in [1, 2, 3]:  # 2 ÷ 2, 4 ÷ 2, 6 ÷ 2 ...
		var item := DivisionItem.new()  # ... each a new item,
		item.dividend = 2 * quotient  # ... the number divided,
		item.divisor = 2  # ... the number it is divided by,
		item.quotient = quotient  # ... and the answer.
		items.append(item)  # Keep it.
	var run := LevelRun.new(items, EASY)  # A play of those items.
	run.submit_answer(run.current_item().correct_answer(), 5.0)  # Right.
	run.submit_answer(run.current_item().correct_answer(), 5.0)  # Right: 2 in a row.
	run.submit_answer(-1, 5.0)  # Wrong: the streak ends.
	assert_eq(run.streak, 0)  # No streak now ...
	assert_eq(run.best_streak, 2)  # ... but the best was 2 in a row.


# Levels passed are counted over every Episode and Difficulty, out of 60.
func test_levels_passed() -> void:
	_record_pass(1, EASY, 1)  # One pass.
	_record_pass(2, MEDIUM, 3)  # Another, elsewhere.
	progress.record(1, EASY, 2, 0, 50, 70.0)  # A play with no Stars: not a pass.
	assert_eq(progress.levels_passed(), 2)  # Two Levels passed.
	assert_eq(Progress.LEVEL_TOTAL, 60)  # 4 Episodes x 3 Difficulties x 5 Levels.


# There are twelve Trophies, each with a name and a goal to show.
func test_twelve_trophies() -> void:
	assert_eq(Trophies.ALL.size(), 12)  # Twelve Trophies (D-023).
	for trophy: Dictionary in Trophies.ALL:  # Each one ...
		assert_ne(trophy.name, "", trophy.id)  # ... has a name,
		assert_ne(trophy.goal, "", trophy.id)  # ... and a goal.


# Nothing is earned at the start; the first Star earns "First Star" once, and only once.
func test_first_star_is_earned_once() -> void:
	assert_eq(Trophies.award(progress, records), [] as Array[String])  # Nothing yet.
	_record_pass(1, EASY, 1)  # The first Star.
	assert_eq(Trophies.award(progress, records), ["first_star"] as Array[String])  # Earned now.
	assert_eq(Trophies.award(progress, records), [] as Array[String])  # Not earned again.
	assert_true(records.has_trophy("first_star"))  # It is kept.


# Each Trophy's goal earns it.
func test_each_goal_earns_its_trophy() -> void:
	_record_pass(1, EASY, 1, 3)  # 10 of 10: three Stars.
	records.add_play(10, 5, 50.0)  # 5 in a row.
	for episode in range(1, 5):  # Each Episode's Easy Level 5 ...
		_record_pass(episode, EASY, 5)  # ... passed.
	_record_pass(1, MEDIUM, 1)  # A Medium pass.
	_record_pass(1, HARD, 1)  # A Hard pass.
	var earned := Trophies.award(progress, records)  # Check them all.
	for id: String in ["first_star", "perfect_10", "on_a_roll", "easy_facts", "middle_facts", "hard_facts", "fact_families", "medium_ready", "hard_hero"]:  # These goals were met ...
		assert_has(earned, id)  # ... so these Trophies are earned.
	for id: String in ["star_collector", "practice_pro", "division_champion"]:  # These were not ...
		assert_does_not_have(earned, id)  # ... so not these.


# The big goals: 50 Stars, 25 Levels played and all 180 Stars.
func test_big_goals() -> void:
	for episode in range(1, 5):  # Every Episode ...
		for difficulty: int in [EASY, MEDIUM, HARD]:  # ... every Difficulty ...
			for level in range(1, 6):  # ... every Level ...
				_record_pass(episode, difficulty, level, 3)  # ... with three Stars: 180 Stars in all.
	for i in range(25):  # 25 plays ...
		records.add_play(10, 10, 40.0)  # ... recorded.
	var earned := Trophies.award(progress, records)  # Check them all.
	assert_has(earned, "star_collector")  # 50 Stars or more.
	assert_has(earned, "practice_pro")  # 25 Levels played.
	assert_has(earned, "division_champion")  # All 180 Stars.
	assert_eq(records.trophies.size(), 12)  # Every Trophy earned.


# Records and earned Trophies are saved on the device and come back after a restart, and the
# records section is not mistaken for a Level's bests.
func test_records_survive_a_restart() -> void:
	_record_pass(1, EASY, 1)  # A pass to save.
	records.add_play(8, 4, 61.5)  # A play to save.
	Trophies.award(progress, records)  # Earns "First Star".
	var settings := SaveStore.default_settings()  # Settings to save.
	assert_eq(SaveStore.new(TEST_PATH).save(progress, settings, records), OK)  # Saving worked.
	var loaded_progress := Progress.new()  # New, empty objects, as after a restart.
	var loaded_records := Records.new()  # New, empty records.
	SaveStore.new(TEST_PATH).load_into(loaded_progress, SaveStore.default_settings(), loaded_records)  # Read the file back.
	assert_eq(loaded_records.levels_played, 1)  # Levels played came back.
	assert_eq(loaded_records.correct_total, 8)  # Correct answers came back.
	assert_eq(loaded_records.best_streak, 4)  # Best streak came back.
	assert_almost_eq(loaded_records.seconds_played, 61.5, 0.001)  # Time played came back.
	assert_eq(loaded_records.trophies, ["first_star"] as Array[String])  # Earned Trophies came back.
	assert_eq(loaded_progress.bests.size(), 1)  # Only the one Level's bests, not a "records" Level.


# A Trophy earned now keeps the day it was earned (D-030); a Trophy earned before keeps its own day.
func test_trophy_keeps_the_day_it_was_earned() -> void:
	_record_pass(1, EASY, 1)  # Earns "First Star" ...
	Trophies.award(progress, records, "2026-11-24")  # ... on 24 November 2026.
	assert_eq(records.earned_date("first_star"), "2026-11-24")  # Its day is kept.
	_record_pass(1, EASY, 2, 3)  # Later, "Perfect 10" ...
	Trophies.award(progress, records, "2026-11-30")  # ... on 30 November.
	assert_eq(records.earned_date("perfect_10"), "2026-11-30")  # Its own day.
	assert_eq(records.earned_date("first_star"), "2026-11-24")  # The first day does not change.


# With no day given, the phone's own date is used.
func test_trophy_date_comes_from_the_phone() -> void:
	_record_pass(1, EASY, 1)  # Earns "First Star".
	Trophies.award(progress, records)  # No day given.
	assert_eq(records.earned_date("first_star"), Time.get_date_string_from_system())  # Today's date.


# The earned day is written in words for the Trophy card.
func test_date_in_words() -> void:
	assert_eq(Trophies.date_text("2026-11-24"), "Earned on 24 Nov 2026")  # A kept day.
	assert_eq(Trophies.date_text("2027-01-05"), "Earned on 5 Jan 2027")  # No leading zero.
	assert_eq(Trophies.date_text(""), "Earned before dates were kept")  # Earned before this version kept days.


# A Trophy not yet earned shows how far along the learner is, never more than its goal.
func test_progress_towards_each_goal() -> void:
	assert_eq(Trophies.progress_text("first_star", progress, records), "0 of 1 Star")  # Nothing yet.
	_record_pass(1, EASY, 1)  # 1 Star, Level 1 of Episode 1 Easy passed.
	_record_pass(1, EASY, 2)  # 1 more Star, Level 2 passed.
	records.add_play(7, 3, 50.0)  # A play with 3 in a row.
	assert_eq(Trophies.progress_text("star_collector", progress, records), "2 of 50 Stars")  # Stars so far.
	assert_eq(Trophies.progress_text("division_champion", progress, records), "2 of 180 Stars")  # All Stars.
	assert_eq(Trophies.progress_text("on_a_roll", progress, records), "3 of 5 right in a row")  # Best streak.
	assert_eq(Trophies.progress_text("practice_pro", progress, records), "1 of 25 Levels played")  # Plays.
	assert_eq(Trophies.progress_text("easy_facts", progress, records), "2 of 5 Levels passed")  # Episode 1 Easy.
	assert_eq(Trophies.progress_text("middle_facts", progress, records), "0 of 5 Levels passed")  # Episode 2 Easy.
	assert_eq(Trophies.progress_text("perfect_10", progress, records), "0 of 1 Level with 10 of 10")  # No 3 Stars yet.
	assert_eq(Trophies.progress_text("medium_ready", progress, records), "0 of 1 Medium Level passed")  # No Medium pass.
	assert_eq(Trophies.progress_text("hard_hero", progress, records), "0 of 1 Hard Level passed")  # No Hard pass.
	records.best_streak = 9  # A longer streak than the goal ...
	assert_eq(Trophies.progress_text("on_a_roll", progress, records), "5 of 5 right in a row")  # ... shows the goal, not more.
