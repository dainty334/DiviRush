# Makes wrong answers for the answer bubbles: far ones for Easy, near ones for Medium,
# and look-alike ones for Hard (D-010, D-011).
# Used by the item bank tool when it builds the .tres files, not during play.
class_name WrongAnswers  # Lets any script call WrongAnswers.far(), near() and look_alike().
extends RefCounted  # A light object; only its static functions are used.

const FAR_GAP := 3  # Easy wrong answers are at least 3 away from the answer (D-010).
const LOWEST := 1  # Smallest number a bubble may show.
const HIGHEST := 20  # Largest number a bubble may show (Medium and Hard too, D-011).


# Returns `count` different wrong answers that are far from `correct`, for Easy items.
# Example: for 56 ÷ 8 = 7 it may return 2 and 15.
static func far(correct: int, count: int, rng: RandomNumberGenerator) -> Array[int]:
	var pool: Array[int] = []  # Every number that is allowed.
	for value in range(LOWEST, HIGHEST + 1):  # Try each number from 1 to 20.
		if absi(value - correct) >= FAR_GAP:  # Keep only numbers far enough away.
			pool.append(value)  # Add it to the allowed list.
	var picked: Array[int] = []  # The wrong answers chosen so far.
	while picked.size() < count and not pool.is_empty():  # Until enough are chosen.
		var index := rng.randi_range(0, pool.size() - 1)  # Pick a random spot in the list.
		picked.append(pool[index])  # Take that number.
		pool.remove_at(index)  # Remove it so it is not picked twice.
	return picked  # Hand back the wrong answers.


# Returns `count` different wrong answers near `correct`, for Medium items (D-011).
# "Closest first": numbers 1 away, then 2 away, then 3 away, until there are enough.
# Example: for 35 ÷ 5 = 7 it returns 6, 8, and 5 or 9.
static func near(correct: int, count: int, rng: RandomNumberGenerator) -> Array[int]:
	var picked: Array[int] = []  # No wrong answers chosen yet.
	_fill_closest(correct, picked, count, rng)  # Fill every place closest first.
	return picked  # Hand back the wrong answers.


# Returns `count` different wrong answers for Hard items: near and look-alike (D-011).
# `partner` is the answer of the swapped fact in the same fact family; for a missing quotient
# it is the divisor (35 ÷ 5 = 7, so 35 ÷ 7 = 5 gives 5). It comes first, because mixing up
# the divisor and the quotient is a real mistake. The rest come closest first: answer -1 and +1
# (the facts just before and after in the same table), then the nearest unused numbers.
# Example: for 35 ÷ 5 = 7 it returns 5, 6, 8.
static func look_alike(correct: int, partner: int, count: int, rng: RandomNumberGenerator) -> Array[int]:
	var picked: Array[int] = []  # No wrong answers chosen yet.
	if count > 0 and _is_allowed(partner, correct):  # The partner can be shown (not the answer, inside 1-20) ...
		picked.append(partner)  # ... so it goes first.
	_fill_closest(correct, picked, count, rng)  # Fill the other places closest first.
	return picked  # Hand back the wrong answers.


# Adds numbers to `picked` closest first until it holds `count` numbers (D-011).
# At each distance it collects the allowed numbers not used yet; when there are more of them
# than places left, it picks among them at random. Used by near() and look_alike().
static func _fill_closest(correct: int, picked: Array[int], count: int, rng: RandomNumberGenerator) -> void:
	var gap := 1  # Start with numbers 1 away from the answer.
	while picked.size() < count and gap <= HIGHEST - LOWEST:  # Until full, or no number is left to try.
		var options: Array[int] = []  # Allowed, unused numbers at this distance.
		for value: int in [correct - gap, correct + gap]:  # The number below and the number above.
			if _is_allowed(value, correct) and not picked.has(value):  # Allowed and not used yet ...
				options.append(value)  # ... so it may be picked.
		while picked.size() < count and not options.is_empty():  # Take them while places are left.
			var index := rng.randi_range(0, options.size() - 1)  # A random one, so the side changes.
			picked.append(options[index])  # Take it.
			options.remove_at(index)  # Do not take it twice.
		gap += 1  # Next, try numbers one step farther away.


# Returns true when `value` may be a wrong answer: inside 1-20 and not the correct answer.
static func _is_allowed(value: int, correct: int) -> bool:
	return value >= LOWEST and value <= HIGHEST and value != correct  # Both rules must hold.
