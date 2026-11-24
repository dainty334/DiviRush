# Profile screen (D-030): the learner's own page, opened from the pill at the top left of the Main
# menu. It shows the Buddy's face, the Nickname with a pencil to change it, "Your buddy" with Ana,
# Migo and Both, and the counts of Stars, Trophies and Levels passed. Kept only on the phone.
extends ScreenBase  # Shared background, margins and column.

const FACE_SIDE := 300.0  # The big face at the top.

var _face_box: CenterContainer  # Holds the big face, so it can be swapped when the Buddy changes.
var _name_label: Label  # The Nickname.
var _pencil: Button  # Opens the Nickname card.
var _picker: BuddyPicker  # Ana, Migo or Both.
var _edit_card: Control  # The card for changing the Nickname, hidden until the pencil is tapped.
var _edit_box: NicknameBox  # The text box on that card.
var _save_button: Button  # Saves the new Nickname; off while it breaks the rules.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	add_header("Profile")  # Back button and title.
	add_spacer(0.2)  # A little space under the title.
	_face_box = CenterContainer.new()  # The place for the big face.
	column.add_child(_face_box)  # Show it.
	_show_face()  # The Buddy's face.
	column.add_child(_make_name_row())  # The Nickname and the pencil.
	add_spacer(0.3)  # Space before the Buddy.
	column.add_child(UiKit.label("Your buddy", 56, Palette.WHITE, 12))  # The Buddy heading.
	_picker = BuddyPicker.new(Save.profile.buddy)  # The saved Buddy is picked.
	_picker.chosen.connect(_on_buddy_chosen)  # Save a new choice.
	column.add_child(_picker)  # Show the three tiles.
	add_spacer(0.3)  # Space before the counts.
	column.add_child(_make_counts())  # Stars, Trophies and Levels passed.
	add_spacer(1.0)  # Space at the bottom.
	_edit_card = _make_edit_card()  # The hidden Nickname card ...
	add_child(_edit_card)  # ... added last, so it draws on top.


# Shows the big face of the saved Buddy, in place of the old one.
func _show_face() -> void:
	for old in _face_box.get_children():  # Any face shown before ...
		old.queue_free()  # ... goes.
	_face_box.add_child(BuddyFace.new(Save.profile.buddy, FACE_SIDE))  # The face, or both faces.


# Returns the big face shown now. Used by tests.
func _face() -> BuddyFace:
	for child in _face_box.get_children():  # Each face in the box ...
		if not child.is_queued_for_deletion():  # ... that is not on its way out ...
			return child as BuddyFace  # ... is the one shown.
	return null  # None yet.


# Makes the Nickname row: the Nickname in big outlined letters and a white pencil button.
func _make_name_row() -> HBoxContainer:
	var row := HBoxContainer.new()  # Nickname and pencil side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.add_theme_constant_override("separation", 24)  # Space between them.
	_name_label = UiKit.label(Save.profile.nickname, 80, Palette.WHITE, 16)  # The Nickname.
	row.add_child(_name_label)  # Add it.
	_pencil = UiKit.card_button(Palette.WHITE, Vector2(110, 110), 36)  # A small white button ...
	_pencil.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # ... not stretched tall,
	var picture := UiKit.icon(UiKit.Icon.PENCIL, 72)  # ... with the pencil,
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)  # ... centred on it.
	_pencil.add_child(picture)  # Put the pencil on the button.
	_pencil.pressed.connect(_open_edit_card)  # Tapping it opens the Nickname card.
	row.add_child(_pencil)  # Add it.
	return row  # Hand back the row.


# Makes the row of three count pills: Stars of 180, Trophies of 12 and Levels passed of 60.
func _make_counts() -> HBoxContainer:
	var row := HBoxContainer.new()  # The pills side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.add_theme_constant_override("separation", 20)  # Space between them.
	row.add_child(UiKit.count_pill(UiKit.Icon.STAR, Save.progress.total_stars(), Progress.MAX_STARS))  # Stars earned.
	row.add_child(UiKit.count_pill(UiKit.Icon.TROPHY, Save.records.trophies.size(), Trophies.ALL.size()))  # Trophies earned.
	row.add_child(UiKit.count_pill(UiKit.Icon.CHART, Save.progress.levels_passed(), Progress.LEVEL_TOTAL))  # Levels passed.
	UiKit.pop_in(row, 0.15)  # Bounce in.
	return row  # Hand back the row.


# Makes the hidden Nickname card: the title, the text box, Save, and Cancel.
func _make_edit_card() -> Control:
	_edit_box = NicknameBox.new(Save.profile.nickname)  # The box.
	_edit_box.ready_changed.connect(func(ready: bool) -> void: _save_button.disabled = not ready)  # Save only a good Nickname.
	_save_button = UiKit.button("Save", Palette.GREEN, Vector2(600, 150))  # The big green Save.
	_save_button.pressed.connect(_on_save)  # Keep the new Nickname.
	var cancel := UiKit.button("Cancel", Palette.WHITE, Vector2(600, 130), 56)  # Leave it as it was.
	cancel.pressed.connect(_close_edit_card)  # Just close the card.
	return make_card("Your nickname", [_edit_box, _save_button, cancel], 84)  # The same card look as the Exit card.


# Opens the Nickname card with the saved Nickname in the box, ready to type.
func _open_edit_card() -> void:
	_edit_box.text = Save.profile.nickname  # Start from the saved Nickname.
	_save_button.disabled = not _edit_box.is_ready()  # Save is on for a good Nickname.
	_edit_card.visible = true  # Show the card.
	_edit_box.grab_focus()  # Put the typing line in the box, which opens the phone's keyboard.


# Closes the Nickname card without saving.
func _close_edit_card() -> void:
	_edit_box.release_focus()  # Close the phone's keyboard.
	_edit_card.visible = false  # Hide the card.


# Save: keeps the new Nickname, shows it, and closes the card.
func _on_save() -> void:
	Save.set_nickname(_edit_box.text)  # Saved on the phone (ignored if it breaks the rules).
	_name_label.text = Save.profile.nickname  # Show the saved Nickname.
	_close_edit_card()  # Done.


# A Buddy tile was tapped: save it and show its face.
func _on_buddy_chosen(buddy: String) -> void:
	Save.set_buddy(buddy)  # Saved on the phone.
	_show_face()  # The new face.


# Android Back closes the Nickname card first; otherwise it leaves the Profile.
func back_pressed() -> void:
	if _edit_card.visible:  # The card is open ...
		_close_edit_card()  # ... so close it and stay.
	else:  # No card ...
		super.back_pressed()  # ... so go back as usual.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
