# The twelve Trophies and their goals (D-023): rewards for progress, accuracy and practice, never
# for speed, like the Stars. A Trophy is earned once and kept. A plain class with no scene, so tests
# can check every goal.
class_name Trophies  # Lets the Save autoload, the screens and tests write Trophies.award(...).
extends RefCounted  # Only its constants and static functions are used.

const ALL := [  # Every Trophy, in the order the Trophies screen shows them: id, name and goal.
	{"id": "first_star", "name": "First Star", "goal": "Earn your first Star"},  # The first Star.
	{"id": "perfect_10", "name": "Perfect 10", "goal": "Get 10 of 10 in a Level"},  # Three Stars once.
	{"id": "on_a_roll", "name": "On a Roll", "goal": "Get 5 right in a row"},  # A streak of 5.
	{"id": "easy_facts", "name": "Easy Facts", "goal": "Pass Episode 1 Easy Level 5"},  # Episode 1 Easy done.
	{"id": "middle_facts", "name": "Middle Facts", "goal": "Pass Episode 2 Easy Level 5"},  # Episode 2 Easy done.
	{"id": "hard_facts", "name": "Hard Facts", "goal": "Pass Episode 3 Easy Level 5"},  # Episode 3 Easy done.
	{"id": "fact_families", "name": "Fact Families", "goal": "Pass Episode 4 Easy Level 5"},  # Episode 4 Easy done.
	{"id": "medium_ready", "name": "Medium Ready", "goal": "Pass a Medium Level"},  # Any Medium pass.
	{"id": "hard_hero", "name": "Hard Hero", "goal": "Pass a Hard Level"},  # Any Hard pass.
	{"id": "star_collector", "name": "Star Collector", "goal": "Earn 50 Stars"},  # 50 Stars.
	{"id": "practice_pro", "name": "Practice Pro", "goal": "Play 25 Levels"},  # 25 plays.
	{"id": "division_champion", "name": "Division Champion", "goal": "Earn all 180 Stars"},  # Every Star.
]  # End of the list.
const STREAK_GOAL := 5  # "On a Roll": 5 correct in a row.
const STAR_GOAL := 50  # "Star Collector": 50 Stars.
const PLAY_GOAL := 25  # "Practice Pro": 25 Levels played.
const EASY_FIVE := {"easy_facts": 1, "middle_facts": 2, "hard_facts": 3, "fact_families": 4}  # The Trophies for passing an Episode's Easy Level 5, and their Episode.
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]  # Short month names for the earned day.


# Gives every Trophy whose goal is now met and that was not earned before, and keeps the day it was
# earned (D-030): `today` as "2026-11-24", or the phone's own date when none is given. Returns the
# ids of the new ones, so the Level end screen can show them. Called after each play and when the game starts.
static func award(progress: Progress, records: Records, today: String = "") -> Array[String]:
	var day := today if today != "" else Time.get_date_string_from_system()  # The day to keep for new Trophies.
	var new_ones: Array[String] = []  # Trophies earned just now.
	for trophy: Dictionary in ALL:  # Each Trophy, in order ...
		var id: String = trophy.id  # ... its id,
		if not records.has_trophy(id) and is_goal_met(id, progress, records):  # ... not earned yet, but its goal is met ...
			records.trophies.append(id)  # ... is kept,
			records.trophy_dates[id] = day  # ... with the day it was earned,
			new_ones.append(id)  # ... and reported as new.
	return new_ones  # Hand back the new Trophies.


# Returns the earned day in words for the Trophy card, for example "Earned on 24 Nov 2026" (D-030).
# A Trophy earned before the game kept days has no day, so the card says so.
static func date_text(day: String) -> String:
	if day == "":  # No day was kept ...
		return "Earned before dates were kept"  # ... so say so truthfully.
	var parts := day.split("-")  # Year, month and day, as "2026", "11", "24".
	return "Earned on %d %s %s" % [int(parts[2]), MONTHS[int(parts[1]) - 1], parts[0]]  # Day without a leading zero, short month, year.


# Returns how far along a Trophy's goal the learner is, for example "23 of 50 Stars" (D-030).
# The first number never goes past the goal. Shown on the card of a Trophy not yet earned.
static func progress_text(id: String, progress: Progress, records: Records) -> String:
	var now := 0  # How much is done so far.
	var goal := 1  # How much the goal needs; most goals need one thing.
	var what := ""  # What is counted.
	match id:  # Each Trophy counts its own thing.
		"first_star":  # Any Star.
			now = progress.total_stars()  # Stars so far.
			what = "Star"  # One Star.
		"perfect_10":  # 10 of 10 in a Level.
			now = 1 if is_goal_met(id, progress, records) else 0  # Done or not.
			what = "Level with 10 of 10"  # One such Level.
		"on_a_roll":  # 5 right in a row.
			now = records.best_streak  # The longest streak so far.
			goal = STREAK_GOAL  # 5.
			what = "right in a row"  # Answers in a row.
		"medium_ready":  # Any Medium Level.
			now = 1 if is_goal_met(id, progress, records) else 0  # Done or not.
			what = "Medium Level passed"  # One Medium pass.
		"hard_hero":  # Any Hard Level.
			now = 1 if is_goal_met(id, progress, records) else 0  # Done or not.
			what = "Hard Level passed"  # One Hard pass.
		"star_collector":  # 50 Stars.
			now = progress.total_stars()  # Stars so far.
			goal = STAR_GOAL  # 50.
			what = "Stars"  # Stars.
		"practice_pro":  # 25 Levels played.
			now = records.levels_played  # Plays so far.
			goal = PLAY_GOAL  # 25.
			what = "Levels played"  # Plays.
		"division_champion":  # Every Star.
			now = progress.total_stars()  # Stars so far.
			goal = Progress.MAX_STARS  # 180.
			what = "Stars"  # Stars.
		_:  # The four "pass Easy Level 5" Trophies.
			if EASY_FIVE.has(id):  # One of them ...
				now = _easy_passed(progress, EASY_FIVE[id])  # ... counts that Episode's Easy Levels passed,
				goal = Progress.LEVEL_COUNT  # ... out of 5,
				what = "Levels passed"  # ... as passes.
	return "%d of %d %s" % [mini(now, goal), goal, what]  # For example "2 of 50 Stars".


# Returns how many Easy Levels of an Episode have been passed, 0 to 5.
static func _easy_passed(progress: Progress, episode: int) -> int:
	var count := 0  # Passes so far.
	for level in range(1, Progress.LEVEL_COUNT + 1):  # Each Easy Level ...
		if progress.is_passed(episode, Difficulty.Kind.EASY, level):  # ... passed?
			count += 1  # Count it.
	return count  # Hand back the count.


# Returns true when a Trophy's goal is met by the bests and records.
static func is_goal_met(id: String, progress: Progress, records: Records) -> bool:
	match id:  # Each Trophy has its own goal.
		"first_star":  # At least one Star.
			return progress.total_stars() >= 1  # Any Star counts.
		"perfect_10":  # 10 of 10 in some Level.
			return _any_level(progress, func(best: Dictionary) -> bool: return best.stars >= 3)  # Three Stars = 10 of 10.
		"on_a_roll":  # A streak of 5.
			return records.best_streak >= STREAK_GOAL  # The longest streak so far.
		"easy_facts":  # Episode 1 Easy Level 5.
			return progress.is_passed(1, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"middle_facts":  # Episode 2 Easy Level 5.
			return progress.is_passed(2, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"hard_facts":  # Episode 3 Easy Level 5.
			return progress.is_passed(3, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"fact_families":  # Episode 4 Easy Level 5.
			return progress.is_passed(4, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"medium_ready":  # Any Medium Level.
			return _any_passed_in(progress, Difficulty.Kind.MEDIUM)  # One pass is enough.
		"hard_hero":  # Any Hard Level.
			return _any_passed_in(progress, Difficulty.Kind.HARD)  # One pass is enough.
		"star_collector":  # 50 Stars.
			return progress.total_stars() >= STAR_GOAL  # Stars over all Levels.
		"practice_pro":  # 25 Levels played.
			return records.levels_played >= PLAY_GOAL  # Plays, passed or not.
		"division_champion":  # Every Star.
			return progress.total_stars() >= Progress.MAX_STARS  # All 180.
	return false  # An unknown id is never earned.


# Returns a Trophy's name from its id, for the Level end banner.
static func name_of(id: String) -> String:
	for trophy: Dictionary in ALL:  # Look through the list ...
		if trophy.id == id:  # ... for this id,
			return trophy.name  # ... and hand back its name.
	return id  # Not found: show the id itself.


# Returns true when any one Level of a Difficulty, in any Episode, has been passed.
static func _any_passed_in(progress: Progress, difficulty: int) -> bool:
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		for level in range(1, Progress.LEVEL_COUNT + 1):  # ... each Level ...
			if progress.is_passed(episode, difficulty, level):  # ... passed?
				return true  # One is enough.
	return false  # None passed.


# Returns true when the test is true for the bests of any one Level in the game.
static func _any_level(progress: Progress, test: Callable) -> bool:
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		for difficulty: int in Difficulty.Kind.values():  # ... each Difficulty ...
			for level in range(1, Progress.LEVEL_COUNT + 1):  # ... each Level ...
				if test.call(progress.best(episode, difficulty, level)):  # ... does it pass the test?
					return true  # One is enough.
	return false  # None did.
