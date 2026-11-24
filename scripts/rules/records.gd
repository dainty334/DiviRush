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


# Adds one finished play. Called when a Level ends, passed or not.
func add_play(correct: int, streak: int, seconds: float) -> void:
	levels_played += 1  # One more Level played.
	correct_total += correct  # Its correct answers.
	best_streak = maxi(best_streak, streak)  # Keep the longest streak.
	seconds_played += seconds  # Its time.


# Returns true when the Trophy with this id has been earned.
func has_trophy(id: String) -> bool:
	return trophies.has(id)  # Earned Trophies are kept in the list.


# Returns the day a Trophy was earned, as "2026-11-24", or "" when no day was kept (D-030).
func earned_date(id: String) -> String:
	return str(trophy_dates.get(id, ""))  # The kept day, or nothing.
