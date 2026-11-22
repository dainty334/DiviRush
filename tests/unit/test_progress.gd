# Tests for unlocking and best results (D-008, D-010).
extends GutTest  # GUT gives this script its assert_* checks.

const EASY := Difficulty.Kind.EASY  # Short name for Easy.
const MEDIUM := Difficulty.Kind.MEDIUM  # Short name for Medium.
const HARD := Difficulty.Kind.HARD  # Short name for Hard.

var progress: Progress  # A fresh Progress for each test.


# Runs before every test: start with no Levels played.
func before_each() -> void:
	progress = Progress.new()  # New, empty progress.


# Records a passing play (1 Star) for one Level, to keep the tests short.
func _record_pass(episode: int, difficulty: int, level: int) -> void:
	progress.record(episode, difficulty, level, 1, 100, 60.0)  # 1 Star, 100 points, 60 seconds.


# At the start only Episode 1 -> Easy -> Level 1 is open.
func test_only_first_level_is_open_at_start() -> void:
	assert_true(progress.is_level_open(1, EASY, 1))  # The first Level is open.
	assert_false(progress.is_level_open(1, EASY, 2))  # Level 2 is locked.
	assert_false(progress.is_difficulty_open(1, MEDIUM))  # Medium is locked.
	assert_false(progress.is_difficulty_open(1, HARD))  # Hard is locked.
	assert_false(progress.is_episode_open(2))  # Episode 2 is locked.


# Passing a Level opens the next Level in the same Difficulty.
func test_passing_a_level_opens_the_next() -> void:
	_record_pass(1, EASY, 1)  # Pass Level 1.
	assert_true(progress.is_level_open(1, EASY, 2))  # Level 2 is now open.
	assert_false(progress.is_level_open(1, EASY, 3))  # Level 3 is still locked.


# A play with 0 Stars does not open the next Level.
func test_failing_a_level_keeps_the_next_locked() -> void:
	progress.record(1, EASY, 1, 0, 70, 80.0)  # 0 Stars: not passed.
	assert_false(progress.is_level_open(1, EASY, 2))  # Level 2 stays locked.


# Passing Easy Level 5 opens that Episode's Medium and the next Episode's Easy.
func test_passing_easy_level_five_opens_medium_and_next_episode() -> void:
	for level in range(1, 6):  # Pass Easy Levels 1 to 5.
		_record_pass(1, EASY, level)  # Record a pass for this Level.
	assert_true(progress.is_level_open(1, MEDIUM, 1))  # Episode 1 Medium Level 1 opens.
	assert_true(progress.is_level_open(2, EASY, 1))  # Episode 2 Easy Level 1 opens.
	assert_true(progress.is_episode_open(2))  # Episode 2 shows as open.
	assert_false(progress.is_difficulty_open(1, HARD))  # Hard needs Medium Level 5 first.
	assert_false(progress.is_episode_open(3))  # Episode 3 is still locked.


# Passing Medium Level 5 opens that Episode's Hard.
func test_passing_medium_level_five_opens_hard() -> void:
	for level in range(1, 6):  # Pass Easy and Medium Levels 1 to 5.
		_record_pass(1, EASY, level)  # Easy Level passed.
		_record_pass(1, MEDIUM, level)  # Medium Level passed.
	assert_true(progress.is_level_open(1, HARD, 1))  # Hard Level 1 is open.


# The best Stars stay when a later play earns fewer.
func test_best_stars_are_kept() -> void:
	progress.record(1, EASY, 1, 3, 200, 50.0)  # A perfect play first.
	progress.record(1, EASY, 1, 1, 120, 70.0)  # A weaker play later.
	assert_eq(progress.best(1, EASY, 1).stars, 3)  # The 3 Stars stay.


# The best score is the highest score of any play.
func test_best_score_is_the_highest() -> void:
	progress.record(1, EASY, 1, 0, 90, 80.0)  # 90 points, not passed.
	progress.record(1, EASY, 1, 1, 150, 70.0)  # 150 points.
	progress.record(1, EASY, 1, 2, 130, 60.0)  # 130 points.
	assert_eq(progress.best(1, EASY, 1).score, 150)  # The highest, 150, is kept.


# Best time comes only from passed plays, and the shortest one wins (D-010).
func test_best_time_is_the_shortest_passed_play() -> void:
	progress.record(1, EASY, 1, 0, 0, 20.0)  # Fast but not passed: ignored.
	assert_eq(progress.best(1, EASY, 1).time, -1.0)  # Still no best time (-1 means none).
	progress.record(1, EASY, 1, 1, 100, 70.0)  # First passed play: 70 s.
	progress.record(1, EASY, 1, 1, 100, 55.5)  # Faster passed play: 55.5 s.
	progress.record(1, EASY, 1, 2, 100, 65.0)  # Slower passed play: ignored for time.
	assert_eq(progress.best(1, EASY, 1).time, 55.5)  # The shortest, 55.5 s, is kept.


# stars_in() adds up the best Stars of the 5 Levels in one Difficulty.
func test_stars_in_adds_best_stars_of_a_difficulty() -> void:
	progress.record(1, EASY, 1, 3, 200, 50.0)  # Level 1: 3 Stars.
	progress.record(1, EASY, 2, 1, 120, 70.0)  # Level 2: 1 Star.
	progress.record(1, MEDIUM, 1, 2, 150, 60.0)  # Another Difficulty: not counted.
	assert_eq(progress.stars_in(1, EASY), 4)  # 3 + 1 = 4 Stars in Easy.


# record() reports which bests are new, so the Level end screen can show "New best!".
func test_record_reports_new_bests() -> void:
	var first := progress.record(1, EASY, 1, 1, 100, 70.0)  # The first play sets every best.
	assert_true(first.new_stars)  # 1 Star is new.
	assert_true(first.new_score)  # 100 points is new.
	assert_true(first.new_time)  # 70 s is new.
	var second := progress.record(1, EASY, 1, 1, 90, 80.0)  # A weaker play.
	assert_false(second.new_stars)  # Same Stars: not new.
	assert_false(second.new_score)  # Lower score: not new.
	assert_false(second.new_time)  # Slower time: not new.
