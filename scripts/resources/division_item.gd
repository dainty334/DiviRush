# One division item, for example 56 ÷ 8 = 7, with its wrong answers.
# Saved inside an Episode item bank (.tres), so items change without code changes.
class_name DivisionItem  # Shows up in the Godot "New Resource" list.
extends Resource  # A data file Godot can save and edit in the Inspector.

enum Hidden { QUOTIENT, DIVISOR, DIVIDEND }  # Which number the learner must find.

@export var dividend: int = 1  # The number being divided, 100 or less (D-007).
@export var divisor: int = 1  # The number it is divided by, 1 to 10.
@export var quotient: int = 1  # The result, 1 to 10.
@export var hidden: Hidden = Hidden.QUOTIENT  # Episodes 1-3 hide the quotient; Episode 4 may hide others.
@export var wrong_easy: Array[int] = []  # 2 far wrong answers for Easy's 3 bubbles.
@export var wrong_medium: Array[int] = []  # 3 near wrong answers for Medium's 4 bubbles (D-011).
@export var wrong_hard: Array[int] = []  # 3 look-alike wrong answers for Hard's 4 bubbles (D-011).


# Returns the number the learner must tap. Used to check an answer.
func correct_answer() -> int:
	match hidden:  # Pick by which number is hidden.
		Hidden.DIVISOR:  # Example: 56 ÷ ☐ = 7.
			return divisor  # The answer is the divisor.
		Hidden.DIVIDEND:  # Example: ☐ ÷ 8 = 7.
			return dividend  # The answer is the dividend.
		_:  # Every other case hides the quotient.
			return quotient  # Example: 56 ÷ 8 = ?


# Returns the text for the item card, for example "56 ÷ 8 = ?".
func question_text() -> String:
	match hidden:  # Pick by which number is hidden.
		Hidden.DIVISOR:  # Missing divisor.
			return "%d ÷ ☐ = %d" % [dividend, quotient]  # Example: 56 ÷ ☐ = 7.
		Hidden.DIVIDEND:  # Missing dividend.
			return "☐ ÷ %d = %d" % [divisor, quotient]  # Example: ☐ ÷ 8 = 7.
		_:  # Missing quotient.
			return "%d ÷ %d = ?" % [dividend, divisor]  # Example: 56 ÷ 8 = ?


# Returns the full fact with the answer filled in, for example "56 ÷ 8 = 7".
# Shown on the item card after an answer or a time-out, so the learner sees the right fact.
func answered_text() -> String:
	return "%d ÷ %d = %d" % [dividend, divisor, quotient]  # Every number shown.


# Returns the stored wrong answers for one Difficulty. Used to fill the bubbles.
func wrong_for(difficulty: int) -> Array[int]:
	match difficulty:  # Pick the list for this Difficulty.
		Difficulty.Kind.MEDIUM:  # Medium.
			return wrong_medium  # Near wrong answers.
		Difficulty.Kind.HARD:  # Hard.
			return wrong_hard  # Look-alike wrong answers.
		_:  # Easy.
			return wrong_easy  # Far wrong answers.
