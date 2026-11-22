# The points rules for one answer (D-008, D-010).
# A plain class with no scene, so tests can use it directly.
class_name Scoring  # Lets any script call Scoring.points_for().
extends RefCounted  # A light object; only its static function is used.

const POINTS_CORRECT := 10  # Base points for a correct answer.
const STREAK_BONUS := 5  # Extra points for a long streak.
const STREAK_BONUS_FROM := 4  # The 4th correct in a row is the first to earn the bonus (D-010).


# Returns the points for one answer. Called by LevelRun each time an item is answered.
# streak is how many correct answers in a row there are, counting this one.
static func points_for(is_correct: bool, seconds_left: float, streak: int) -> int:
	if not is_correct:  # A wrong answer or a time-out ...
		return 0  # ... earns nothing, so the score never goes down.
	var points := POINTS_CORRECT  # Start with the base 10 points.
	points += maxi(0, floori(seconds_left))  # Add 1 per whole second left, never a negative amount.
	if streak >= STREAK_BONUS_FROM:  # Four or more correct in a row ...
		points += STREAK_BONUS  # ... earns +5 for this answer.
	return points  # Hand back the total for this answer.
