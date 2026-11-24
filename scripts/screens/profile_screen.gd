# Profile screen (D-030, D-031): the learner's own page, opened from the pill at the top left of the
# Main menu. It shows the Buddy's face, the Nickname with a pencil to change it, "Your buddy" with Ana,
# Migo and Both, the counts of Stars, Trophies and Levels passed, and the Featured Trophy the learner
# picks to show. Kept only on the phone.
extends ScreenBase  # Shared background, margins and column.

const FACE_SIDE := 250.0  # The big face at the top, a little smaller to leave room for the Featured Trophy.
const CHOICE_SIZE := Vector2(240, 230)  # Each Trophy on the Featured Trophy picker.

var _face_box: CenterContainer  # Holds the big face, so it can be swapped when the Buddy changes.
var _name_label: Label  # The Nickname.
var _pencil: Button  # Opens the Nickname card.
var _picker: BuddyPicker  # Ana, Migo or Both.
var _edit_card: Control  # The card for changing the Nickname, hidden until the pencil is tapped.
var _edit_box: NicknameBox  # The text box on that card.
var _save_button: Button  # Saves the new Nickname; off while it breaks the rules.
var _featured_box: CenterContainer  # Holds the Featured Trophy button, so it can be swapped after a pick (D-031).
var _featured_button: Button  # Shows the Featured Trophy and opens the picker.
var _featured_card: Control  # The picker: every earned Trophy, and None.
var _featured_choices: Array[Button] = []  # One button per earned Trophy on the picker, in screen order.
var _featured_none: Button  # The picker's None button.


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
	add_spacer(0.3)  # Space before the Featured Trophy.
	column.add_child(UiKit.label("Featured Trophy", 56, Palette.WHITE, 12))  # Its heading (D-031).
	_featured_box = CenterContainer.new()  # The place for its button.
	column.add_child(_featured_box)  # Show it.
	_show_featured()  # The picked Trophy, or what to do.
	add_spacer(1.0)  # Space at the bottom.
	_edit_card = _make_edit_card()  # The hidden Nickname card ...
	add_child(_edit_card)  # ... added last, so it draws on top.
	_featured_card = _make_featured_card()  # The hidden Featured Trophy picker ...
	add_child(_featured_card)  # ... also on top.


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


# Shows the Featured Trophy button (D-031): the picked Trophy with its name; "Tap to pick a Trophy"
# when none is picked; and, before any Trophy is earned, what to do, with the button off.
func _show_featured() -> void:
	for old in _featured_box.get_children():  # The button shown before ...
		old.queue_free()  # ... goes.
	_featured_button = UiKit.card_button(Palette.WHITE, Vector2(760, 200), 48)  # A wide white card button.
	_featured_button.pressed.connect(_open_featured_card)  # Tapping it opens the picker.
	var row := HBoxContainer.new()  # Picture beside the words.
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the button ...
	row.offset_left = 26  # ... with room at the left,
	row.offset_right = -26  # ... and at the right.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.add_theme_constant_override("separation", 24)  # Space between them.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the button.
	_featured_button.add_child(row)  # Put the row on the button.
	var id := Save.profile.featured  # The picked Trophy, or "".
	if id != "" and Save.records.has_trophy(id):  # A Trophy is picked ...
		var picture := UiKit.trophy_picture(id, 150, true)  # ... its picture,
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # ... centred up and down,
		row.add_child(picture)  # ... on the left.
		var words := VBoxContainer.new()  # Its name above a hint.
		words.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the button.
		words.add_child(UiKit.label(Trophies.name_of(id), 56, Palette.INK))  # The Trophy's name.
		words.add_child(UiKit.label("Tap to change", 36, Palette.BLUE))  # How to change it.
		row.add_child(words)  # Beside the picture.
	elif Save.records.trophies.is_empty():  # No Trophy earned yet ...
		row.add_child(UiKit.label("Earn a Trophy to show it here.", 44, Palette.INK))  # ... say what to do,
		_featured_button.disabled = true  # ... and leave the button off.
	else:  # Trophies earned, none picked ...
		row.add_child(UiKit.label("Tap to pick a Trophy", 48, Palette.INK))  # ... invite a pick.
	_featured_box.add_child(_featured_button)  # Show the button.


# Makes the hidden Featured Trophy picker: every earned Trophy as a button, then None and Cancel.
func _make_featured_card() -> Control:
	var grid := GridContainer.new()  # The earned Trophies, three per row.
	grid.columns = 3  # Three columns.
	grid.add_theme_constant_override("h_separation", 16)  # Space between the columns.
	grid.add_theme_constant_override("v_separation", 16)  # Space between the rows.
	for trophy: Dictionary in Trophies.ALL:  # Each Trophy, in screen order ...
		if not Save.records.has_trophy(trophy.id):  # ... not earned ...
			continue  # ... cannot be picked.
		var choice := UiKit.card_button(Palette.WHITE, CHOICE_SIZE, 36)  # A button for it.
		var lines := VBoxContainer.new()  # Picture above name.
		lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the button.
		lines.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
		lines.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the button.
		var picture := UiKit.trophy_picture(trophy.id, 130, true)  # Its picture.
		picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
		lines.add_child(picture)  # Add it.
		var name_label := UiKit.label(trophy.name, 32, Palette.INK)  # Its name.
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Long names wrap.
		name_label.custom_minimum_size.x = CHOICE_SIZE.x - 20.0  # As wide as the button's inside.
		lines.add_child(name_label)  # Add it.
		choice.add_child(lines)  # Put them on the button.
		choice.pressed.connect(_on_featured_chosen.bind(trophy.id))  # Picking it features it.
		grid.add_child(choice)  # Show it.
		_featured_choices.append(choice)  # Remember it.
	var scroll := ScrollContainer.new()  # Scrolls when many Trophies are earned.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # Only up and down.
	var rows := ceili(_featured_choices.size() / 3.0)  # Rows of Trophies.
	scroll.custom_minimum_size = Vector2(CHOICE_SIZE.x * 3 + 32, minf(rows * (CHOICE_SIZE.y + 16), 760.0))  # Up to about three rows, then scroll.
	scroll.add_child(grid)  # Put the grid in it.
	_featured_none = UiKit.button("None", Palette.WHITE, Vector2(600, 130), 56)  # Show no Trophy.
	_featured_none.pressed.connect(_on_featured_chosen.bind(""))  # None takes it away.
	var cancel := UiKit.button("Cancel", Palette.GREEN, Vector2(600, 130), 56)  # Leave it as it was.
	cancel.pressed.connect(_close_featured_card)  # Just close the picker.
	return make_card("Pick a Trophy", [scroll, _featured_none, cancel], 84)  # The same card look as the Exit card.


# Opens the Featured Trophy picker.
func _open_featured_card() -> void:
	_featured_card.visible = true  # Show it.


# Closes the Featured Trophy picker without changing anything.
func _close_featured_card() -> void:
	_featured_card.visible = false  # Hide it.


# A Trophy (or None, "") was picked: save it, close the picker and show it.
func _on_featured_chosen(id: String) -> void:
	Save.set_featured(id)  # Saved on the phone; only an earned Trophy is kept.
	_close_featured_card()  # Done picking.
	_show_featured()  # Show the new choice.


# Android Back closes an open card first; otherwise it leaves the Profile.
func back_pressed() -> void:
	if _featured_card.visible:  # The Featured Trophy picker is open ...
		_close_featured_card()  # ... so close it and stay.
	elif _edit_card.visible:  # The Nickname card is open ...
		_close_edit_card()  # ... so close it and stay.
	else:  # No card ...
		super.back_pressed()  # ... so go back as usual.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
