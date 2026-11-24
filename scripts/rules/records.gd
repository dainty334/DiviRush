# The learner's game records for the Records tab, and the Trophies earned with their dates (D-023, D-030).
# They are records of play, not grades: Levels played, correct answers, the best streak and time played.
class_name Records  # Lets the Save autoload, the screens and tests use Records.
extends RefCounted  # A light object that frees itself when no longer used.

var levels_played := 0  # Levels finished, passed or not.
var correct_total := 0  # Correct answers in all those Levels.
var best_streak := 0  # Most correct answers in a row, in any one Level.
var seconds_played := 0.0  # Seconds spent answering items in Levels.
var trophies: Array[String] = []  # Ids of the Trophies earned, in the order they were earned.
var trophy_dates: Dictionary = {}  # The day each Trophy was earned, as "2026-11-24", by id (D-030). Older Trophies have none.
var failed_levels: Array[String] = []  # Levels played but never passed yet, by Level key, for "Try Again" (D-031).
var comebacks := 0  # Levels passed after being played without passing, for "Try Again".
var days_played := 0  # Different days with at least one play, for "Three Days".
var last_day := ""  # The last day with a play, as "2026-11-24".
var run_streak := 0  # Right answers in a row now, carried from Level to Level, for "Super Streak".
var best_run_streak := 0  # The longest carried streak so far.


# Adds one finished play. Called when a Level ends, passed or not.
func add_play(correct: int, streak: int, seconds: float) -> void:
	levels_played += 1  # One more Level played.
	correct_total += correct  # Its correct answers.
	best_streak = maxi(best_streak, streak)  # Keep the longest streak.
	seconds_played += seconds  # Its time.


# Counts the day of a play, once per day, for "Three Days" (D-031). `day` is "2026-11-24".
func note_day(day: String) -> void:
	if day != last_day:  # The first play on this day ...
		days_played += 1  # ... adds a day,
		last_day = day  # ... and becomes the last day.


# Notes whether a Level was passed, for "Try Again" (D-031). A Level played without passing, and
# never passed before, is remembered; passing it later counts one comeback.
func note_result(level_key: String, passed: bool, passed_before: bool) -> void:
	if passed:  # Passed now ...
		if failed_levels.has(level_key):  # ... after not passing it before ...
			comebacks += 1  # ... is a comeback,
			failed_levels.erase(level_key)  # ... and the Level is no longer waiting.
	elif not passed_before and not failed_levels.has(level_key):  # Not passed, and never passed before ...
		failed_levels.append(level_key)  # ... so remember it.


# Carries the streak from Level to Level, for "Super Streak" (D-031). `lead` is the right answers in
# a row from the Level's first item, `tail` those in a row at its end, `correct` all right answers,
# and `total` the Level's items. A Level with every answer right adds to the streak; otherwise the
# streak ends after its opening run, and the run at the end starts a new one.
func carry_streak(lead: int, tail: int, correct: int, total: int) -> void:
	if correct >= total:  # Every answer right ...
		run_streak += total  # ... so the streak goes on.
	else:  # A wrong answer or a time-out somewhere ...
		best_run_streak = maxi(best_run_streak, run_streak + lead)  # ... the streak reached this far,
		run_streak = tail  # ... and the right answers at the end start a new one.
	best_run_streak = maxi(best_run_streak, run_streak)  # Keep the longest.


# Returns true when the Trophy with this id has been earned.
func has_trophy(id: String) -> bool:
	return trophies.has(id)  # Earned Trophies are kept in the list.


# Returns the day a Trophy was earned, as "2026-11-24", or "" when no day was kept (D-030).
func earned_date(id: String) -> String:
	return str(trophy_dates.get(id, ""))  # The kept day, or nothing.
