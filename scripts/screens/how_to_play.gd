# How to Play (D-032): picture lessons taught by the learner's Buddy. Seven short pages, turned with
# the arrows and "1 / 7": each has a title, a picture made from the real game parts, and the Buddy at
# half size saying one line in plain words for Grade 4 learners. The last page, "Try it!", is one
# practice item with no timer, tried until right; nothing is saved. The points rules are left out,
# because they do not change the Stars. Opened from the Main menu, and once after the Welcome screen.
extends ScreenBase  # Shared background, margins and column.

const LESSONS := [  # Each page: its title and what the Buddy says (D-032).
	{"title": "1. Read the division", "line": "Each Level has 10 division questions. Read the one on the card."},  # Page 1.
	{"title": "2. Tap the right bubble", "line": "Tap the bubble with the right answer. Be quick! The timer bar gets shorter."},  # Page 2.
	{"title": "3. Right or wrong?", "line": "Right answer? You get a sparkle! Wrong? Don't worry, I will show you the right one."},  # Page 3.
	{"title": "4. Earn Stars", "line": "Get 8 right to earn a Star. 9 right gets 2 Stars. 10 right gets 3 Stars! One Star opens the next Level."},  # Page 4.
	{"title": "5. The times-table trick", "line": "Stuck? Use your times tables! For 56 ÷ 8, think: 8 times what is 56?"},  # Page 5.
	{"title": "6. Easy, Medium, Hard", "line": "Easy has 3 bubbles. Medium and Hard have 4 bubbles and less time."},  # Page 6.
	{"title": "7. Try it!", "line": "Your turn! What is 12 ÷ 3? Tap the right bubble."},  # Page 7.
]  # End of the list.
const TRY_ANSWER := 4  # 12 ÷ 3 = 4, the practice item's answer.
const TRY_CHOICES := [2, 4, 6]  # The practice bubbles: the answer and two wrong ones.
const TRY_HINT := "Not quite! Think: 3 times what is 12? Try again."  # Said after a wrong tap.
const TRY_CHEER := "Yes! 12 ÷ 3 = 4, because 3 × 4 = 12. You are ready to play!"  # Said after the right tap.
const TEACHER_SCALE := 0.6  # The Buddy at a bit over half its Main menu size, so it fits beside the bubble.
const STAGE_SIZE := Vector2(1000, 640)  # The space for each page's picture.

var _pager: Pager  # The arrows and "1 / 7".
var _title: Label  # The page's title.
var _stage: CenterContainer  # Holds the page's picture.
var _teacher_box: Control  # Holds the Buddy, at half size.
var _teachers: Dictionary = {}  # The Buddy for each name, made the first time it teaches.
var _teacher: Mascot  # The Buddy teaching this page.
var _words: Label  # What the Buddy says, in the big speech bubble.
var _got_it: Button  # Leaves the lessons; shown on the last page.
var _try_bubbles: Array[AnswerBubble] = []  # The practice bubbles on the "Try it!" page.
var _try_done := false  # true once the practice item is answered right.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020); it keeps playing from the Main menu.
	column.add_theme_constant_override("separation", 22)  # Close together, so everything fits.
	add_header("How to Play")  # Back button and title.
	_title = UiKit.label("", 60, Palette.YELLOW, 14)  # The page's title.
	column.add_child(_title)  # Under the header.
	_stage = CenterContainer.new()  # The picture's place.
	_stage.custom_minimum_size = STAGE_SIZE  # Always the same size, so nothing jumps.
	column.add_child(_stage)  # Show it.
	column.add_child(_make_teacher_row())  # The Buddy and the speech bubble.
	add_spacer(1.0)  # Push the arrows down.
	_pager = Pager.new(LESSONS.size())  # Seven pages.
	_pager.page_changed.connect(_show_lesson)  # Show the page chosen.
	column.add_child(_pager)  # Near the bottom.
	_got_it = UiKit.button("Got it!", Palette.GREEN, Vector2(700, 140))  # Leave the lessons.
	_got_it.pressed.connect(go_back)  # Back to the Main menu.
	column.add_child(_got_it)  # Under the arrows, shown on the last page.
	_show_lesson(0)  # Start on page 1.


# Makes the row with the Buddy on the left and a big white speech bubble on the right.
func _make_teacher_row() -> HBoxContainer:
	var row := HBoxContainer.new()  # Buddy and bubble side by side.
	row.add_theme_constant_override("separation", 20)  # Space between them.
	_teacher_box = Control.new()  # The Buddy's place.
	_teacher_box.custom_minimum_size = Mascot.PICTURE_SIZE * TEACHER_SCALE  # Half the Main menu size.
	row.add_child(_teacher_box)  # On the left.
	var bubble := PanelContainer.new()  # The speech bubble.
	var style := UiKit.box(Palette.WHITE, 48)  # White, round and outlined.
	style.set_content_margin_all(30)  # Room inside.
	bubble.add_theme_stylebox_override("panel", style)  # Use this look.
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the rest of the row.
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Centred up and down.
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	_words = UiKit.label("", 48, Palette.INK)  # The Buddy's words, big and dark.
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap long lines.
	_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Read from the left.
	bubble.add_child(_words)  # Put the words in the bubble.
	row.add_child(bubble)  # On the right.
	return row  # Hand back the row.


# Shows one lesson page: its title, its picture, its teacher and its line; "Got it!" on the last page.
func _show_lesson(index: int) -> void:
	_title.text = LESSONS[index].title  # The title.
	for old in _stage.get_children():  # The old picture ...
		old.queue_free()  # ... goes.
	_try_bubbles.clear()  # No practice bubbles unless this is "Try it!".
	_try_done = false  # A fresh try each time the page opens.
	if index == LESSONS.size() - 1:  # The last page ...
		_stage.add_child(_make_try_it())  # ... is the practice item.
	else:  # Any other page ...
		_stage.add_child(LessonPictures.make(index))  # ... has its picture.
	_show_teacher(index)  # Who teaches this page.
	_say(LESSONS[index].line)  # The Buddy says the line.
	_teacher.wave()  # And waves hello.
	_got_it.visible = index == LESSONS.size() - 1  # "Got it!" only on the last page.


# Shows the Buddy for a page: the learner's Buddy, or with Both, Ana and Migo in turn page by page.
func _show_teacher(index: int) -> void:
	var names := Save.profile.mascots()  # One name, or both.
	var who: String = names[index % names.size()]  # This page's teacher.
	if not _teachers.has(who):  # Not made yet ...
		var mascot := Mascot.new(who, [] as Array[String])  # ... a new Buddy,
		mascot.bubble_hidden = true  # ... talking in this screen's big bubble instead of its own,
		mascot.scale = Vector2(TEACHER_SCALE, TEACHER_SCALE)  # ... at half size,
		_teacher_box.add_child(mascot)  # ... in its place,
		_teachers[who] = mascot  # ... remembered.
	for teacher_name: String in _teachers:  # Each Buddy made so far ...
		(_teachers[teacher_name] as Mascot).visible = teacher_name == who  # ... shows only on its own pages.
	_teacher = _teachers[who]  # This page's teacher.


# Shows a line in the speech bubble and moves the Buddy's mouth while it talks.
func _say(text: String) -> void:
	_words.text = text  # The words, all at once, so they are easy to read.
	_teacher.lines.assign([text])  # A tap on the Buddy says it again.
	_teacher.say(text)  # The mouth moves while the line plays.


# Makes the "Try it!" page: the item card for 12 ÷ 3 and three real bubbles to tap, with no timer.
func _make_try_it() -> VBoxContainer:
	var box := VBoxContainer.new()  # Card above bubbles.
	box.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	box.add_theme_constant_override("separation", 30)  # Space between them.
	box.add_child(LessonPictures.item_card("12 ÷ 3", 150, Vector2(760, 320)))  # The question.
	var row := LessonPictures.bubble_row(TRY_CHOICES, 900.0)  # Three bubbles.
	for bubble: AnswerBubble in row.get_children():  # Each bubble ...
		bubble.tapped.connect(_on_try_tapped)  # ... answers when tapped,
		_try_bubbles.append(bubble)  # ... and is remembered.
	box.add_child(row)  # Under the card.
	return box  # Hand back the page.


# A practice bubble was tapped: the right one sparkles and the Buddy cheers; a wrong one shakes,
# stays red, and the Buddy gives the times-table hint, so the learner can try again.
func _on_try_tapped(bubble: AnswerBubble) -> void:
	if _try_done:  # Already answered right ...
		return  # ... so nothing more to do.
	if bubble.value == TRY_ANSWER:  # The right answer ...
		_try_done = true  # ... finishes the try,
		for each: AnswerBubble in _try_bubbles:  # ... every bubble ...
			each.lock()  # ... stops taking taps,
		bubble.mark_correct()  # ... this one turns green and sparkles,
		Audio.play_sfx("correct")  # ... with the right-answer sound,
		_say(TRY_CHEER)  # ... and the Buddy cheers,
		_teacher.wave()  # ... with a wave.
	else:  # A wrong answer ...
		bubble.lock()  # ... cannot be tapped again,
		bubble.mark_wrong()  # ... turns red and shakes,
		Audio.play_sfx("wrong")  # ... with the wrong-answer sound,
		_say(TRY_HINT)  # ... and the Buddy gives the hint.


# Back (and "Got it!") returns to the Main menu, also after the Welcome screen.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
