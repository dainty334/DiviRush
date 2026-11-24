# The 26 Trophies and their goals (D-023, D-031): rewards for progress, accuracy and practice, never
# for speed, like the Stars. A Trophy is earned once and kept. A plain class with no scene, so tests
# can check every goal.
class_name Trophies  # Lets the Save autoload, the screens and tests write Trophies.award(...).
extends RefCounted  # Only its constants and static functions are used.

const ALL := [  # Every Trophy, in the order the Trophies screen shows them: id, name, goal and group (its ring colour, D-031).
	{"id": "first_star", "name": "First Star", "goal": "Earn your first Star", "group": "progress"},  # The first Star.
	{"id": "perfect_10", "name": "Perfect 10", "goal": "Get 10 of 10 in a Level", "group": "accuracy"},  # Three Stars once.
	{"id": "on_a_roll", "name": "On a Roll", "goal": "Get 5 right in a row", "group": "accuracy"},  # A streak of 5.
	{"id": "easy_facts", "name": "Easy Facts", "goal": "Pass Episode 1 Easy Level 5", "group": "progress"},  # Episode 1 Easy done.
	{"id": "middle_facts", "name": "Middle Facts", "goal": "Pass Episode 2 Easy Level 5", "group": "progress"},  # Episode 2 Easy done.
	{"id": "hard_facts", "name": "Hard Facts", "goal": "Pass Episode 3 Easy Level 5", "group": "progress"},  # Episode 3 Easy done.
	{"id": "fact_families", "name": "Fact Families", "goal": "Pass Episode 4 Easy Level 5", "group": "progress"},  # Episode 4 Easy done.
	{"id": "medium_ready", "name": "Medium Ready", "goal": "Pass a Medium Level", "group": "progress"},  # Any Medium pass.
	{"id": "hard_hero", "name": "Hard Hero", "goal": "Pass a Hard Level", "group": "progress"},  # Any Hard pass.
	{"id": "star_collector", "name": "Star Collector", "goal": "Earn 50 Stars", "group": "progress"},  # 50 Stars.
	{"id": "practice_pro", "name": "Practice Pro", "goal": "Play 25 Levels", "group": "practice"},  # 25 plays.
	{"id": "division_champion", "name": "Division Champion", "goal": "Earn all 180 Stars", "group": "progress"},  # Every Star.
	{"id": "easy_explorer", "name": "Easy Explorer", "goal": "Pass every Easy Level", "group": "progress"},  # All 20 Easy Levels (D-031).
	{"id": "medium_master", "name": "Medium Master", "goal": "Pass every Medium Level", "group": "progress"},  # All 20 Medium Levels.
	{"id": "hard_master", "name": "Hard Master", "goal": "Pass every Hard Level", "group": "progress"},  # All 20 Hard Levels.
	{"id": "episode_star", "name": "Episode Star", "goal": "Earn all 45 Stars in an Episode", "group": "progress"},  # One whole Episode.
	{"id": "perfect_five", "name": "Perfect Five", "goal": "Get 10 of 10 in 5 Levels", "group": "accuracy"},  # Five Levels at three Stars.
	{"id": "perfect_twenty", "name": "Perfect Twenty", "goal": "Get 10 of 10 in 20 Levels", "group": "accuracy"},  # Twenty Levels at three Stars.
	{"id": "hard_perfect", "name": "Hard Perfect", "goal": "Get 10 of 10 in a Hard Level", "group": "accuracy"},  # A Hard Level at three Stars.
	{"id": "missing_number", "name": "Missing Number", "goal": "Get 10 of 10 in an Episode 4 Level", "group": "accuracy"},  # The missing-number Episode.
	{"id": "hundred_right", "name": "Hundred Right", "goal": "Get 100 answers right", "group": "practice"},  # 100 right answers.
	{"id": "five_hundred", "name": "Five Hundred", "goal": "Get 500 answers right", "group": "practice"},  # 500 right answers.
	{"id": "try_again", "name": "Try Again", "goal": "Pass a Level you missed before", "group": "practice"},  # A comeback.
	{"id": "three_days", "name": "Three Days", "goal": "Play on 3 different days", "group": "practice"},  # Practice spread over days.
	{"id": "super_streak", "name": "Super Streak", "goal": "Get 30 right in a row", "group": "accuracy"},  # A streak across Levels.
	{"id": "perfect_run", "name": "Perfect Run", "goal": "Get 10 of 10 in all 5 Levels of a Difficulty", "group": "accuracy"},  # A whole perfect set.
]  # End of the list.
const PERFECT_FIVE := 5  # "Perfect Five": 5 Levels at 10 of 10.
const PERFECT_TWENTY := 20  # "Perfect Twenty": 20 Levels at 10 of 10.
const HUNDRED := 100  # "Hundred Right": 100 right answers.
const FIVE_HUNDRED := 500  # "Five Hundred": 500 right answers.
const DAY_GOAL := 3  # "Three Days": 3 different days.
const RUN_GOAL := 30  # "Super Streak": 30 right in a row, across Levels.
const EPISODE_STARS := 45  # "Episode Star": all Stars in one Episode, 3 Difficulties x 5 Levels x 3 Stars.
const DIFFICULTY_TROPHIES := {"easy_explorer": Difficulty.Kind.EASY, "medium_master": Difficulty.Kind.MEDIUM, "hard_master": Difficulty.Kind.HARD}  # Trophies for passing every Level of a Difficulty.
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
		"easy_explorer", "medium_master", "hard_master":  # Every Level of one Difficulty (D-031).
			now = _passed_in(progress, DIFFICULTY_TROPHIES[id])  # That Difficulty's Levels passed.
			goal = Progress.EPISODE_COUNT * Progress.LEVEL_COUNT  # 20.
			what = "Levels passed"  # Passes.
		"episode_star":  # All Stars of one Episode.
			now = _best_episode_stars(progress)  # The best Episode's Stars.
			goal = EPISODE_STARS  # 45.
			what = "Stars"  # Stars.
		"perfect_five", "perfect_twenty":  # Levels at 10 of 10.
			now = _perfect_levels(progress)  # Levels with three Stars.
			goal = PERFECT_FIVE if id == "perfect_five" else PERFECT_TWENTY  # 5 or 20.
			what = "Levels with 10 of 10"  # Perfect Levels.
		"hard_perfect":  # A Hard Level at 10 of 10.
			now = 1 if is_goal_met(id, progress, records) else 0  # Done or not.
			what = "Hard Level with 10 of 10"  # One such Level.
		"missing_number":  # An Episode 4 Level at 10 of 10.
			now = 1 if is_goal_met(id, progress, records) else 0  # Done or not.
			what = "Episode 4 Level with 10 of 10"  # One such Level.
		"hundred_right", "five_hundred":  # Right answers.
			now = records.correct_total  # Right answers so far.
			goal = HUNDRED if id == "hundred_right" else FIVE_HUNDRED  # 100 or 500.
			what = "right answers"  # Answers.
		"try_again":  # A comeback.
			now = mini(records.comebacks, 1)  # Done or not.
			what = "Level passed after trying again"  # One comeback.
		"three_days":  # Different days.
			now = records.days_played  # Days so far.
			goal = DAY_GOAL  # 3.
			what = "days"  # Days.
		"super_streak":  # 30 in a row, across Levels.
			now = maxi(records.best_run_streak, records.run_streak)  # The longest carried streak so far.
			goal = RUN_GOAL  # 30.
			what = "right in a row"  # Answers in a row.
		"perfect_run":  # A whole Difficulty at 10 of 10.
			now = _best_perfect_set(progress)  # The best Difficulty's perfect Levels.
			goal = Progress.LEVEL_COUNT  # 5.
			what = "Levels with 10 of 10"  # Perfect Levels.
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
		"easy_explorer", "medium_master", "hard_master":  # Every Level of one Difficulty (D-031).
			return _passed_in(progress, DIFFICULTY_TROPHIES[id]) >= Progress.EPISODE_COUNT * Progress.LEVEL_COUNT  # All 20 passed.
		"episode_star":  # All Stars of one Episode.
			return _best_episode_stars(progress) >= EPISODE_STARS  # 45 in one Episode.
		"perfect_five":  # 5 Levels at 10 of 10.
			return _perfect_levels(progress) >= PERFECT_FIVE  # Three Stars in 5 Levels.
		"perfect_twenty":  # 20 Levels at 10 of 10.
			return _perfect_levels(progress) >= PERFECT_TWENTY  # Three Stars in 20 Levels.
		"hard_perfect":  # A Hard Level at 10 of 10.
			return _any_level(progress, func(best: Dictionary) -> bool: return best.stars >= 3, -1, Difficulty.Kind.HARD)  # Any Hard Level.
		"missing_number":  # An Episode 4 Level at 10 of 10.
			return _any_level(progress, func(best: Dictionary) -> bool: return best.stars >= 3, Progress.EPISODE_COUNT)  # Any Episode 4 Level.
		"hundred_right":  # 100 right answers.
			return records.correct_total >= HUNDRED  # Over all plays.
		"five_hundred":  # 500 right answers.
			return records.correct_total >= FIVE_HUNDRED  # Over all plays.
		"try_again":  # A Level passed after not passing it.
			return records.comebacks >= 1  # One comeback is enough.
		"three_days":  # 3 different days.
			return records.days_played >= DAY_GOAL  # Days with at least one play.
		"super_streak":  # 30 right in a row, across Levels.
			return records.best_run_streak >= RUN_GOAL  # The longest carried streak.
		"perfect_run":  # All 5 Levels of one Difficulty at 10 of 10.
			return _best_perfect_set(progress) >= Progress.LEVEL_COUNT  # A whole set.
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


# Returns true when the test is true for the bests of any one Level in the game. `only_episode`
# and `only_difficulty` limit the search to one Episode or one Difficulty; -1 means all.
static func _any_level(progress: Progress, test: Callable, only_episode: int = -1, only_difficulty: int = -1) -> bool:
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		if only_episode != -1 and episode != only_episode:  # ... not the one asked for ...
			continue  # ... is skipped.
		for difficulty: int in Difficulty.Kind.values():  # ... each Difficulty ...
			if only_difficulty != -1 and difficulty != only_difficulty:  # ... not the one asked for ...
				continue  # ... is skipped.
			for level in range(1, Progress.LEVEL_COUNT + 1):  # ... each Level ...
				if test.call(progress.best(episode, difficulty, level)):  # ... does it pass the test?
					return true  # One is enough.
	return false  # None did.


# Returns how many Levels of one Difficulty have been passed, over all four Episodes (0 to 20).
static func _passed_in(progress: Progress, difficulty: int) -> int:
	var count := 0  # Passes so far.
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		for level in range(1, Progress.LEVEL_COUNT + 1):  # ... each Level ...
			if progress.is_passed(episode, difficulty, level):  # ... passed?
				count += 1  # Count it.
	return count  # Hand back the count.


# Returns how many Levels in the whole game have three Stars, that is 10 of 10.
static func _perfect_levels(progress: Progress) -> int:
	var count := 0  # Perfect Levels so far.
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		count += _best_perfect_set(progress, episode, true)  # ... adds all its perfect Levels.
	return count  # Hand back the count.


# Returns the most Levels at 10 of 10 inside one Difficulty of one Episode (0 to 5), for Perfect Run.
# With `episode` given, looks only in that Episode; with `add_up`, adds its Difficulties together instead.
static func _best_perfect_set(progress: Progress, episode: int = -1, add_up: bool = false) -> int:
	var best := 0  # The best set so far, or the sum.
	for each in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		if episode != -1 and each != episode:  # ... not the one asked for ...
			continue  # ... is skipped.
		for difficulty: int in Difficulty.Kind.values():  # ... each Difficulty ...
			var perfect := 0  # ... counts its Levels at 10 of 10.
			for level in range(1, Progress.LEVEL_COUNT + 1):  # Each Level ...
				if progress.best(each, difficulty, level).stars >= 3:  # ... with three Stars ...
					perfect += 1  # ... counts.
			best = best + perfect if add_up else maxi(best, perfect)  # Add up, or keep the best set.
	return best  # Hand back the result.


# Returns the most Stars earned in any one Episode (0 to 45), for Episode Star.
static func _best_episode_stars(progress: Progress) -> int:
	var best := 0  # The best Episode so far.
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		var stars := 0  # ... adds up its Stars ...
		for difficulty: int in Difficulty.Kind.values():  # ... over Easy, Medium and Hard.
			stars += progress.stars_in(episode, difficulty)  # One Difficulty's Stars.
		best = maxi(best, stars)  # Keep the best Episode.
	return best  # Hand back the most Stars.


# Returns a Trophy's place in ALL, which is also its picture's frame in the Trophy sheet, or -1.
static func index_of(id: String) -> int:
	for i in range(ALL.size()):  # Each Trophy ...
		if ALL[i].id == id:  # ... with this id ...
			return i  # ... is at this place.
	return -1  # Not found.
