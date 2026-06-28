@tool
extends Control
## Input Forge editor dock. Create/assign an InputForgeActionSet, choose which of
## the project's Godot InputMap actions are the four movement directions, the
## buttons, and the join action, save it, and preview the per-device bindings
## Input Forge will DERIVE from the InputMap.
##
## All InputMap reads use ProjectSettings "input/*" (the editor-safe source -
## InputMap.action_get_events() returns EDITOR actions inside a @tool context,
## verified Godot 4.6). At runtime the same derivation reads the live InputMap and
## is guaranteed to agree (see test/derive_bindings.gd).

const NONE_LABEL: String = "(none)"

var _picker: EditorResourcePicker = null
var _left: OptionButton = null
var _right: OptionButton = null
var _up: OptionButton = null
var _down: OptionButton = null
var _join: OptionButton = null
var _buttons_list: ItemList = null
var _add_option: OptionButton = null
var _add_button: Button = null
var _remove_button: Button = null
var _apply_button: Button = null
var _output: RichTextLabel = null
var _action_names: PackedStringArray = PackedStringArray()
var _built: bool = false


func _ready() -> void:
	if _built:
		return
	_built = true
	name = "Input Forge"
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"separation", 6)
	add_child(root)

	var title := Label.new()
	title.text = "Input Forge - action set"
	root.add_child(title)

	# --- Resource row -------------------------------------------------------
	_picker = EditorResourcePicker.new()
	_picker.base_type = "InputForgeActionSet"
	_picker.resource_changed.connect(_on_resource_changed)
	root.add_child(_picker)

	var resource_row := HBoxContainer.new()
	root.add_child(resource_row)
	var new_button := Button.new()
	new_button.text = "New action set..."
	new_button.pressed.connect(_on_new_pressed)
	resource_row.add_child(new_button)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh actions"
	refresh_button.tooltip_text = "Reload the action list from the project InputMap"
	refresh_button.pressed.connect(_on_refresh_actions_pressed)
	resource_row.add_child(refresh_button)

	root.add_child(HSeparator.new())

	# --- Movement + join dropdowns -----------------------------------------
	var grid := GridContainer.new()
	grid.columns = 2
	root.add_child(grid)
	_left = _add_action_row(grid, "Move left")
	_right = _add_action_row(grid, "Move right")
	_up = _add_action_row(grid, "Move up")
	_down = _add_action_row(grid, "Move down")
	_join = _add_action_row(grid, "Join action")

	# --- Buttons list -------------------------------------------------------
	var buttons_label := Label.new()
	buttons_label.text = "Button actions (ordered)"
	root.add_child(buttons_label)

	_buttons_list = ItemList.new()
	_buttons_list.custom_minimum_size = Vector2(0.0, 90.0)
	_buttons_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_buttons_list)

	var add_row := HBoxContainer.new()
	root.add_child(add_row)
	_add_option = OptionButton.new()
	_add_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(_add_option)
	_add_button = Button.new()
	_add_button.text = "Add"
	_add_button.pressed.connect(_on_add_pressed)
	add_row.add_child(_add_button)
	_remove_button = Button.new()
	_remove_button.text = "Remove"
	_remove_button.pressed.connect(_on_remove_pressed)
	add_row.add_child(_remove_button)

	# --- Apply + preview ----------------------------------------------------
	_apply_button = Button.new()
	_apply_button.text = "Apply + Save"
	_apply_button.pressed.connect(_on_apply_pressed)
	root.add_child(_apply_button)

	root.add_child(HSeparator.new())
	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.fit_content = true
	_output.selection_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_output)

	_refresh_action_names()
	_sync_from_resource()


func _add_action_row(grid: GridContainer, label_text: String) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	grid.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(option)
	return option


## --- Project action names --------------------------------------------------


func _refresh_action_names() -> void:
	_action_names = _project_action_names()
	_fill_option(_left, true)
	_fill_option(_right, true)
	_fill_option(_up, true)
	_fill_option(_down, true)
	_fill_option(_join, true)
	_fill_option(_add_option, false)


## All custom InputMap action names from ProjectSettings (editor-safe source).
func _project_action_names() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for prop: Dictionary in ProjectSettings.get_property_list():
		var setting: String = String(prop.get("name", ""))
		if setting.begins_with("input/"):
			names.append(setting.substr("input/".length()))
	names.sort()
	return names


func _fill_option(option: OptionButton, include_none: bool) -> void:
	if option == null:
		return
	option.clear()
	if include_none:
		option.add_item(NONE_LABEL)
	for action_name: String in _action_names:
		option.add_item(action_name)


func _select_action(option: OptionButton, action: StringName) -> void:
	for index: int in option.item_count:
		if option.get_item_text(index) == String(action):
			option.select(index)
			return
	option.select(0)


func _selected_action(option: OptionButton) -> StringName:
	var index: int = option.selected
	if index < 0:
		return &""
	var text: String = option.get_item_text(index)
	return &"" if text == NONE_LABEL else StringName(text)


## --- Resource sync ---------------------------------------------------------


func _current() -> InputForgeActionSet:
	if _picker == null:
		return null
	return _picker.edited_resource as InputForgeActionSet


func _on_resource_changed(_resource: Resource) -> void:
	_sync_from_resource()


func _sync_from_resource() -> void:
	var action_set: InputForgeActionSet = _current()
	var has_resource: bool = action_set != null
	_set_editing_enabled(has_resource)
	if has_resource:
		_select_action(_left, action_set.move_left)
		_select_action(_right, action_set.move_right)
		_select_action(_up, action_set.move_up)
		_select_action(_down, action_set.move_down)
		_select_action(_join, action_set.join_action)
		_buttons_list.clear()
		for action: StringName in action_set.buttons:
			_buttons_list.add_item(String(action))
	_refresh_preview()


func _set_editing_enabled(enabled: bool) -> void:
	for option: OptionButton in [_left, _right, _up, _down, _join, _add_option]:
		option.disabled = not enabled
	_add_button.disabled = not enabled
	_remove_button.disabled = not enabled
	_apply_button.disabled = not enabled


## --- Buttons list edits ----------------------------------------------------


func _on_add_pressed() -> void:
	if _add_option.selected < 0:
		return
	var action: String = _add_option.get_item_text(_add_option.selected)
	for index: int in _buttons_list.item_count:
		if _buttons_list.get_item_text(index) == action:
			return  # already present
	var _added: int = _buttons_list.add_item(action)


func _on_remove_pressed() -> void:
	var selected: PackedInt32Array = _buttons_list.get_selected_items()
	# Remove from the end so indices stay valid.
	var indices: Array[int] = []
	for index: int in selected:
		indices.append(index)
	indices.sort()
	indices.reverse()
	for index: int in indices:
		_buttons_list.remove_item(index)


func _buttons_from_list() -> Array[StringName]:
	var out: Array[StringName] = []
	for index: int in _buttons_list.item_count:
		out.append(StringName(_buttons_list.get_item_text(index)))
	return out


## --- Apply + new -----------------------------------------------------------


func _on_apply_pressed() -> void:
	var action_set: InputForgeActionSet = _current()
	if action_set == null:
		return
	action_set.move_left = _selected_action(_left)
	action_set.move_right = _selected_action(_right)
	action_set.move_up = _selected_action(_up)
	action_set.move_down = _selected_action(_down)
	action_set.join_action = _selected_action(_join)
	action_set.buttons = _buttons_from_list()
	var path: String = action_set.resource_path
	if path.is_empty():
		push_warning("Input Forge: action set has no resource path; save it as a .tres to persist edits.")
	else:
		var err: Error = ResourceSaver.save(action_set, path)
		if err != OK:
			push_warning("Input Forge: could not save action set (%s)." % error_string(err))
	_refresh_preview()


func _on_refresh_actions_pressed() -> void:
	_refresh_action_names()
	_sync_from_resource()  # re-select the current resource's actions in the rebuilt lists


func _on_new_pressed() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.add_filter("*.tres", "Resource")
	dialog.current_file = "input_action_set.tres"
	# Free the dialog on BOTH outcomes (selected and canceled) so it never leaks.
	dialog.file_selected.connect(_on_new_path_selected.bind(dialog))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _on_new_path_selected(path: String, dialog: EditorFileDialog) -> void:
	dialog.queue_free()
	var action_set := InputForgeActionSet.new()
	var err: Error = ResourceSaver.save(action_set, path)
	if err != OK:
		push_warning("Input Forge: could not create action set (%s)." % error_string(err))
		return
	_picker.edited_resource = load(path)
	_sync_from_resource()


## --- Preview ---------------------------------------------------------------


func _refresh_preview() -> void:
	if _output == null:
		return
	var action_set: InputForgeActionSet = _current()
	if action_set == null:
		_output.text = "Assign or create an InputForgeActionSet to begin."
		return
	_output.text = _describe(action_set)


func _describe(action_set: InputForgeActionSet) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var zone_count: int = InputForgeMapBindings.keyboard_zone_count(action_set, true)
	lines.append("[b]Keyboard zones derived from InputMap:[/b] %d" % zone_count)
	for zone: int in zone_count:
		var bindings: Dictionary = InputForgeMapBindings.keyboard_zone(action_set, zone, true)
		lines.append("  [b]Zone %d[/b]" % zone)
		for action: Variant in bindings:
			var key: int = int(bindings[action])
			lines.append("    %s = %s" % [String(action), OS.get_keycode_string(key as Key)])
	lines.append("")
	lines.append("[b]Joypad buttons:[/b]")
	var joy: Dictionary = InputForgeMapBindings.joypad_buttons(action_set, true)
	if joy.is_empty():
		lines.append("  (none)")
	for action: Variant in joy:
		lines.append("    %s = button %d" % [String(action), int(joy[action])])
	return "\n".join(lines)
