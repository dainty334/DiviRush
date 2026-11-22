# Checks used by the tests: do a list of wrong answers follow the Medium and Hard rules (D-011)?
# This file is not a test itself (its name has no "test_" start), so GUT does not run it.
# Tests load it with preload() and call its functions.
extends RefCounted  # A light object; only its static functions are used.

const LOWEST := 1  # Smallest number a bubble may show (D-011).
const HIGHEST := 20  # Largest number a bubble may show (D-011).
const DIVIDEND_HIGHEST := 100  # Largest number a bubble may show when the dividend is hidden (D-013).


# Checks one list of wrong answers and returns "" when it follows the rules,
# or a short message saying what is wrong, so a failing test explains itself.
# `partner` is the fact family answer Hard must include (the divisor); pass 0 for Medium.
static func problem(correct: int, values: Array[int], count: int, partner: int = 0) -> String:
	var label := "answer %d, wrong %s" % [correct, str(values)]  # Names the case in every message.
	if values.size() != count:  # Wrong number of wrong answers ...
		return "%s: has %d, wants %d" % [label, values.size(), count]  # ... say so.
	var seen := {}  # Numbers met so far, to find repeats.
	for value in values:  # Look at each wrong answer.
		if value == correct:  # The right answer must never be a wrong answer.
			return "%s: contains the answer" % label  # Say so.
		if value < LOWEST or value > HIGHEST:  # Outside the 1-20 range.
			return "%s: %d is outside %d-%d" % [label, value, LOWEST, HIGHEST]  # Say so.
		if seen.has(value):  # Already met: two bubbles would show the same number.
			return "%s: %d appears twice" % [label, value]  # Say so.
		seen[value] = true  # Remember this number.
	var has_partner := partner != correct and partner >= LOWEST and partner <= HIGHEST  # Can the partner be used?
	if has_partner and not seen.has(partner):  # Hard must show the fact family answer when it can.
		return "%s: missing fact family answer %d" % [label, partner]  # Say so.
	var rest: Array[int] = []  # The wrong answers picked "closest first".
	for value in values:  # Every wrong answer ...
		if not (has_partner and value == partner):  # ... except the partner ...
			rest.append(value)  # ... must follow the closest-first rule.
	var far_gap := 0  # The largest distance among the closest-first answers.
	for value in rest:  # Look at each one.
		far_gap = maxi(far_gap, absi(value - correct))  # Keep the largest distance.
	for number in range(LOWEST, HIGHEST + 1):  # Every allowed number.
		var gap := absi(number - correct)  # How far it is from the answer.
		if gap == 0 or gap >= far_gap or (has_partner and number == partner):  # Not a closer candidate ...
			continue  # ... so it does not matter.
		if not rest.has(number):  # A closer number was skipped for a farther one.
			return "%s: skips %d, which is closer" % [label, number]  # Say so.
	return ""  # Every rule holds.


# Checks the wrong answers of a hidden-dividend item (☐ ÷ divisor = quotient) for one Difficulty
# (D-013) and returns "" when they follow the rules, or a short message saying what is wrong.
# `kind` is "easy", "medium" or "hard". All wrong answers are inside 1-100, all different and never
# the answer. Hard first shows the neighbouring facts (divisor - 1) x quotient and (divisor + 1) x quotient;
# every other wrong answer is a multiple of the divisor: far for Easy, nearest first for Medium and Hard.
static func dividend_problem(divisor: int, quotient: int, values: Array[int], kind: String) -> String:
	var answer := divisor * quotient  # The hidden dividend, for example 56.
	var label := "☐ ÷ %d = %d, %s wrong %s" % [divisor, quotient, kind, str(values)]  # Names the case in every message.
	var count := 2 if kind == "easy" else 3  # Easy has 2 wrong answers; Medium and Hard have 3.
	if values.size() != count:  # Wrong number of wrong answers ...
		return "%s: has %d, wants %d" % [label, values.size(), count]  # ... say so.
	var seen := {}  # Numbers met so far, to find repeats.
	for value in values:  # Look at each wrong answer.
		if value == answer:  # The right answer must never be a wrong answer.
			return "%s: contains the answer" % label  # Say so.
		if value < LOWEST or value > DIVIDEND_HIGHEST:  # Outside 1-100.
			return "%s: %d is outside %d-%d" % [label, value, LOWEST, DIVIDEND_HIGHEST]  # Say so.
		if seen.has(value):  # Already met: two bubbles would show the same number.
			return "%s: %d appears twice" % [label, value]  # Say so.
		seen[value] = true  # Remember this number.
	var rest: Array[int] = values.duplicate()  # The wrong answers still to check as multiples.
	if kind == "hard":  # Hard: the neighbouring facts must come first.
		for value: int in [(divisor - 1) * quotient, (divisor + 1) * quotient]:  # The facts of the tables just below and above.
			if value < LOWEST or value > DIVIDEND_HIGHEST or value == answer:  # It cannot be shown ...
				continue  # ... so it is not needed.
			if not rest.has(value):  # It can be shown but is missing.
				return "%s: missing neighbouring fact %d" % [label, value]  # Say so.
			rest.erase(value)  # It is explained.
	var steps: Array[int] = []  # The other wrong answers as "how many times the divisor", for example 48 -> 6.
	for value in rest:  # Each other wrong answer ...
		if value % divisor != 0:  # ... must be a multiple of the divisor.
			return "%s: %d is not a multiple of %d" % [label, value, divisor]  # Say so.
		@warning_ignore("integer_division")  # Exact here, since the value is a multiple of the divisor.
		steps.append(value / divisor)  # Keep it as a step.
	if kind == "easy":  # Easy: far multiples.
		for step in steps:  # Each one ...
			if absi(step - quotient) < 3:  # ... must be at least 3 multiples away.
				return "%s: %d is too near" % [label, step * divisor]  # Say so.
		return ""  # Easy rules hold.
	var far_gap := 0  # The largest distance among the steps.
	for step in steps:  # Look at each one.
		far_gap = maxi(far_gap, absi(step - quotient))  # Keep the largest distance.
	@warning_ignore("integer_division")  # Whole-number division is wanted: 100 / 8 = 12 multiples.
	for step in range(1, DIVIDEND_HIGHEST / divisor + 1):  # Every multiple of the divisor inside 1-100.
		var gap := absi(step - quotient)  # How far it is from the answer, in multiples.
		if gap == 0 or gap >= far_gap or values.has(step * divisor):  # Not a closer unused candidate ...
			continue  # ... so it does not matter.
		return "%s: skips %d, which is closer" % [label, step * divisor]  # A closer multiple was skipped.
	return ""  # Every rule holds.
