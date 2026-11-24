# Tests for the fourteen new Trophies, the new saved facts they need, and the Featured Trophy (D-031).
extends GutTest  # GUT gives this script its assert_* checks.

const EASY := Difficulty.Kind.EASY  # Short name for Easy.
const MEDIUM := Difficulty.Kind.MEDIUM  # Short name for Medium.
const HARD := Difficulty.Kind.HARD  # Short name for Hard.
const TEST_PATH := "user://test_more_trophies.cfg"  # A separate file, so tests never touch the real save.
const NEW_IDS: Array[String] = ["easy_explorer", "medium_master", "hard_master", "episode_star", "perfect_five", "perfect_twenty", "hard_perfect", "missing_number", "hundred_right", "five_hundred", "try_again", "three_days", "super_streak", "perfect_run"]  # The fourteen new Trophies, in screen order.

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


# Passes every Level of one Difficulty in every Episode with the given Stars.
func _pass_difficulty(difficulty: int, stars: int = 1) -> void:
	for episode in range(1, 5):  # Each Episode ...
		for level in range(1, 6):  # ... each Level ...
			progress.record(episode, difficulty, level, stars, 100, 60.0)  # ... passed.


# There are 26 Trophies: the first 12 in their old places, then the 14 new ones in order, each
# with a name, a goal and a group that decides its ring colour.
func test_twenty_six_trophies_in_order() -> void:
	assert_eq(Trophies.ALL.size(), 26)  # 12 + 14.
	assert_eq(Trophies.ALL[0].id, "first_star")  # The first 12 keep their places ...
	assert_eq(Trophies.ALL[11].id, "division_champion")  # ... to the last of them.
	for i in range(NEW_IDS.size()):  # The new ones ...
		assert_eq(Trophies.ALL[12 + i].id, NEW_IDS[i])  # ... follow in order.
	for trophy: Dictionary in Trophies.ALL:  # Each Trophy ...
		assert_ne(trophy.name, "", trophy.id)  # ... has a name,
		assert_ne(trophy.goal, "", trophy.id)  # ... a goal,
		assert_has(["progress", "accuracy", "practice"], trophy.group, trophy.id)  # ... and a group.


# Passing every Level of a Difficulty earns its Trophy: Easy Explorer, Medium Master, Hard Master.
func test_every_level_of_a_difficulty() -> void:
	_pass_difficulty(EASY)  # Every Easy Level.
	var earned := Trophies.award(progress, records, "2026-11-24")  # Check them all.
	assert_has(earned, "easy_explorer")  # All Easy Levels passed.
	assert_does_not_have(earned, "medium_master")  # Not Medium yet.
	_pass_difficulty(MEDIUM)  # Every Medium Level.
	_pass_difficulty(HARD)  # Every Hard Level.
	earned = Trophies.award(progress, records, "2026-11-24")  # Check again.
	assert_has(earned, "medium_master")  # All Medium passed.
	assert_has(earned, "hard_master")  # All Hard passed.


# 10 of 10 goals: 5 Levels, 20 Levels, a Hard Level, an Episode 4 Level, and a whole Difficulty.
func test_perfect_goals() -> void:
	for level in range(1, 5):  # Four Easy Levels of Episode 1 at 10 of 10.
		progress.record(1, EASY, level, 3, 250, 40.0)  # Three Stars.
	var earned := Trophies.award(progress, records, "2026-11-24")  # Check.
	assert_does_not_have(earned, "perfect_five")  # Four is not five.
	assert_does_not_have(earned, "perfect_run")  # Level 5 is missing.
	progress.record(1, EASY, 5, 3, 250, 40.0)  # The fifth: all of Episode 1 Easy at 10 of 10.
	earned = Trophies.award(progress, records, "2026-11-24")  # Check again.
	assert_has(earned, "perfect_five")  # Five Levels at 10 of 10.
	assert_has(earned, "perfect_run")  # A whole Difficulty at 10 of 10.
	progress.record(2, HARD, 1, 3, 250, 40.0)  # A Hard Level at 10 of 10.
	progress.record(4, MEDIUM, 2, 3, 250, 40.0)  # An Episode 4 Level at 10 of 10.
	earned = Trophies.award(progress, records, "2026-11-24")  # Check again.
	assert_has(earned, "hard_perfect")  # Hard at 10 of 10.
	assert_has(earned, "missing_number")  # Episode 4 at 10 of 10.
	assert_does_not_have(earned, "perfect_twenty")  # Only 7 Levels so far.


# All 45 Stars in one Episode earns Episode Star; Stars spread over Episodes do not.
func test_episode_star() -> void:
	for difficulty: int in [EASY, MEDIUM]:  # Two Difficulties of Episode 1 ...
		for level in range(1, 6):  # ... every Level ...
			progress.record(1, difficulty, level, 3, 250, 40.0)  # ... with three Stars: 30 Stars.
	assert_does_not_have(Trophies.award(progress, records, "2026-11-24"), "episode_star")  # 30 of 45.
	for level in range(1, 6):  # Hard too ...
		progress.record(1, HARD, level, 3, 250, 40.0)  # ... 45 Stars in Episode 1.
	assert_has(Trophies.award(progress, records, "2026-11-24"), "episode_star")  # Earned.


# Right answers add up over all plays: 100 earns Hundred Right, 500 earns Five Hundred.
func test_right_answer_goals() -> void:
	for i in range(10):  # 10 plays of 10 right ...
		records.add_play(10, 10, 40.0)  # ... is 100 right answers.
	var earned := Trophies.award(progress, records, "2026-11-24")  # Check.
	assert_has(earned, "hundred_right")  # 100.
	assert_does_not_have(earned, "five_hundred")  # Not 500 yet.
	for i in range(40):  # 40 more plays ...
		records.add_play(10, 10, 40.0)  # ... make 500.
	assert_has(Trophies.award(progress, records, "2026-11-24"), "five_hundred")  # 500.


# Try Again: a Level played without passing and then passed later is a comeback.
func test_try_again() -> void:
	var key := Progress.level_key(1, EASY, 2)  # Episode 1 Easy Level 2.
	records.note_result(key, false, false)  # Played, not passed.
	assert_eq(records.comebacks, 0)  # No comeback yet.
	records.note_result(key, true, false)  # Passed this time.
	assert_eq(records.comebacks, 1)  # A comeback.
	assert_has(Trophies.award(progress, records, "2026-11-24"), "try_again")  # Earned.


# A Level that was already passed, then not passed, then passed again, is not a comeback.
func test_passing_again_is_not_a_comeback() -> void:
	var key := Progress.level_key(1, EASY, 1)  # Episode 1 Easy Level 1.
	records.note_result(key, true, false)  # Passed the first time.
	records.note_result(key, false, true)  # A worse play later.
	records.note_result(key, true, true)  # Passed again.
	assert_eq(records.comebacks, 0)  # Not a comeback.


# Three Days: plays on the same day count once; three different days earn the Trophy.
func test_three_days() -> void:
	records.note_day("2026-11-24")  # A play on the 24th ...
	records.note_day("2026-11-24")  # ... and another the same day.
	assert_eq(records.days_played, 1)  # One day.
	records.note_day("2026-11-25")  # The next day.
	assert_does_not_have(Trophies.award(progress, records, "2026-11-25"), "three_days")  # Two days.
	records.note_day("2026-11-27")  # A third day.
	assert_eq(records.days_played, 3)  # Three days.
	assert_has(Trophies.award(progress, records, "2026-11-27"), "three_days")  # Earned.


# Super Streak: the streak carries over from Level to Level while every answer is right.
func test_streak_carries_across_levels() -> void:
	records.carry_streak(10, 10, 10, 10)  # A Level all right: 10 in a row.
	records.carry_streak(10, 10, 10, 10)  # Another: 20 in a row.
	assert_eq(records.run_streak, 20)  # The streak goes on.
	records.carry_streak(6, 2, 8, 10)  # 6 right, then a wrong one, then 2 right at the end.
	assert_eq(records.best_run_streak, 26)  # 20 + 6 before the wrong answer.
	assert_eq(records.run_streak, 2)  # The 2 at the end start a new streak.
	assert_does_not_have(Trophies.award(progress, records, "2026-11-24"), "super_streak")  # 26 is not 30.
	records.carry_streak(10, 10, 10, 10)  # A Level all right: 12.
	records.carry_streak(10, 10, 10, 10)  # Another: 22.
	records.carry_streak(8, 1, 9, 10)  # 8 more right before a wrong one: 30.
	assert_eq(records.best_run_streak, 30)  # 30 in a row.
	assert_has(Trophies.award(progress, records, "2026-11-24"), "super_streak")  # Earned.


# How far along each new goal is, never more than the goal.
func test_progress_texts() -> void:
	progress.record(1, EASY, 1, 3, 250, 40.0)  # One Level at 10 of 10, 3 Stars.
	progress.record(1, EASY, 2, 1, 120, 60.0)  # One more pass, 1 Star.
	records.add_play(10, 10, 40.0)  # 10 right ...
	records.add_play(8, 4, 60.0)  # ... and 8 more: 18 right.
	records.note_day("2026-11-24")  # One day.
	records.carry_streak(10, 10, 10, 10)  # 10 in a row so far.
	var expected := {  # Each new Trophy's progress text.
		"easy_explorer": "2 of 20 Levels passed",  # Easy Levels passed.
		"medium_master": "0 of 20 Levels passed",  # Medium Levels passed.
		"hard_master": "0 of 20 Levels passed",  # Hard Levels passed.
		"episode_star": "4 of 45 Stars",  # The best Episode's Stars.
		"perfect_five": "1 of 5 Levels with 10 of 10",  # Levels at 10 of 10.
		"perfect_twenty": "1 of 20 Levels with 10 of 10",  # Levels at 10 of 10.
		"hard_perfect": "0 of 1 Hard Level with 10 of 10",  # Not yet.
		"missing_number": "0 of 1 Episode 4 Level with 10 of 10",  # Not yet.
		"hundred_right": "18 of 100 right answers",  # Right answers.
		"five_hundred": "18 of 500 right answers",  # Right answers.
		"try_again": "0 of 1 Level passed after trying again",  # No comeback yet.
		"three_days": "1 of 3 days",  # Days played.
		"super_streak": "10 of 30 right in a row",  # The streak so far.
		"perfect_run": "1 of 5 Levels with 10 of 10",  # The best Difficulty's Levels at 10 of 10.
	}  # End of the list.
	for id: String in expected:  # Each one ...
		assert_eq(Trophies.progress_text(id, progress, records), expected[id], id)  # ... shows how far along.


# A finished play records its day, a comeback and the carried streak through the Save autoload.
func test_finished_play_records_the_new_facts() -> void:
	var real := [Save.progress, Save.records, Save.profile, Save._store]  # Keep the game's own data safe.
	Save.progress = progress  # Fresh progress.
	Save.records = records  # Fresh records.
	Save.profile = Profile.new()  # Fresh Profile.
	Save._store = SaveStore.new(TEST_PATH)  # Saves go to the test file.
	Save.record_result(1, EASY, 1, 0, 60, 70.0, 6, 3, 2, 1, 10)  # Not passed: 6 right, 2 at the start, 1 at the end.
	Save.record_result(1, EASY, 1, 3, 250, 40.0, 10, 10, 10, 10, 10)  # Then 10 of 10.
	assert_eq(records.days_played, 1)  # Today counted once.
	assert_eq(records.comebacks, 1)  # Passed after not passing.
	assert_eq(records.run_streak, 11)  # 1 at the end of the first play + 10.
	assert_has(records.trophies, "try_again")  # Earned at once.
	Save.progress = real[0]  # Put the game's data back ...
	Save.records = real[1]  # ... records,
	Save.profile = real[2]  # ... Profile,
	Save._store = real[3]  # ... and save file.


# The new facts and the Featured Trophy come back after a restart.
func test_new_facts_survive_a_restart() -> void:
	records.note_result(Progress.level_key(2, EASY, 3), false, false)  # A Level not passed yet.
	records.comebacks = 2  # Two comebacks.
	records.note_day("2026-11-24")  # One day ...
	records.carry_streak(10, 10, 10, 10)  # ... and a streak of 10.
	records.best_run_streak = 17  # The best streak so far.
	records.trophies.assign(["first_star"])  # One Trophy earned.
	var profile := Profile.new()  # A Profile ...
	profile.nickname = "Bea"  # ... with a Nickname ...
	profile.featured = "first_star"  # ... and a Featured Trophy.
	assert_eq(SaveStore.new(TEST_PATH).save(progress, SaveStore.default_settings(), records, profile), OK)  # Write the file.
	var loaded := Records.new()  # Empty records ...
	var loaded_profile := Profile.new()  # ... and Profile, as after a restart.
	SaveStore.new(TEST_PATH).load_into(Progress.new(), SaveStore.default_settings(), loaded, loaded_profile)  # Read the file back.
	assert_eq(loaded.failed_levels, [Progress.level_key(2, EASY, 3)] as Array[String])  # The Level not passed yet.
	assert_eq(loaded.comebacks, 2)  # Comebacks.
	assert_eq(loaded.days_played, 1)  # Days played.
	assert_eq(loaded.last_day, "2026-11-24")  # The last day.
	assert_eq(loaded.run_streak, 10)  # The carried streak.
	assert_eq(loaded.best_run_streak, 17)  # The best streak.
	assert_eq(loaded_profile.featured, "first_star")  # The Featured Trophy.


# Only an earned Trophy, or none, can be the Featured Trophy.
func test_featured_trophy_must_be_earned() -> void:
	var real := [Save.records, Save.profile, Save._store]  # Keep the game's own data safe.
	Save.records = records  # Fresh records.
	Save.profile = Profile.new()  # Fresh Profile.
	Save._store = SaveStore.new(TEST_PATH)  # Saves go to the test file.
	Save.set_featured("first_star")  # Not earned yet ...
	assert_eq(Save.profile.featured, "")  # ... so it is not shown.
	records.trophies.assign(["first_star"])  # Earned now.
	Save.set_featured("first_star")  # Picked ...
	assert_eq(Save.profile.featured, "first_star")  # ... and shown.
	Save.set_featured("")  # None picked ...
	assert_eq(Save.profile.featured, "")  # ... so nothing is shown.
	Save.records = real[0]  # Put the game's data back ...
	Save.profile = real[1]  # ... Profile,
	Save._store = real[2]  # ... and save file.


# A Level played to the end counts its right answers in a row from the first item, for Super Streak.
func test_level_run_counts_the_opening_streak() -> void:
	var items: Array[DivisionItem] = []  # Ten simple items.
	for quotient in range(1, 11):  # Quotients 1 to 10.
		var item := DivisionItem.new()  # A new item.
		item.divisor = 2  # Divide by 2.
		item.quotient = quotient  # The answer.
		item.dividend = 2 * quotient  # The number being divided.
		item.wrong_easy = [quotient + 5, quotient + 9]  # Two wrong answers.
		items.append(item)  # Add it.
	var run := LevelRun.new(items, EASY)  # A new play.
	for i in range(3):  # Three right ...
		run.submit_answer(run.current_item().correct_answer(), 5.0)  # ... answers.
	run.time_out()  # Then a time-out.
	run.submit_answer(run.current_item().correct_answer(), 5.0)  # And one more right.
	assert_eq(run.lead_streak, 3)  # Three right from the start.
	assert_eq(run.streak, 1)  # One right at the end so far.
