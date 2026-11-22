# Checks used by the tests: do a list of wrong answers follow the Medium and Hard rules (D-011)?
# This file is not a test itself (its name has no "test_" start), so GUT does not run it.
# Tests load it with preload() and call its functions.
extends RefCounted  # A light object; only its static functions are used.

const LOWEST := 1  # Smallest number a bubble may show (D-011).
const HIGHEST := 20  # Largest number a bubble may show (D-011).


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
