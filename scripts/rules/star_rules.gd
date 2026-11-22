# The Star and Pass rules for a finished Level (D-008).
# A plain class with no scene, so tests can use it directly.
class_name StarRules  # Lets any script call StarRules.stars_for().
extends RefCounted  # A light object; only its static functions are used.

const PASS_MARK := 8  # 8 of 10 correct = 1 Star, the pass mark (D-008).


# Returns 0 to 3 Stars for the number of correct answers out of 10. Called at Level end.
static func stars_for(correct_count: int) -> int:
	if correct_count >= 10:  # All 10 correct ...
		return 3  # ... is a perfect 3 Stars.
	if correct_count == 9:  # 9 correct ...
		return 2  # ... is 2 Stars.
	if correct_count == PASS_MARK:  # 8 correct ...
		return 1  # ... is 1 Star.
	return 0  # 0 to 7 correct is not passed.


# Returns true when the Level is passed, that is, it earns at least 1 Star.
static func is_pass(correct_count: int) -> bool:
	return stars_for(correct_count) >= 1  # Passing means at least one Star.
