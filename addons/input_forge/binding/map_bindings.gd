class_name InputForgeMapBindings
## Derives default per-device bindings from the project's Godot InputMap, given an
## InputForgeActionSet. This is the "configure via the regular InputMap" mechanism: a
## game dev edits the Input Map and the per-device defaults follow.
##
## TWO SOURCES, same result (asserted by test/derive_bindings.gd):
##   - RUNTIME (game): read the InputMap singleton.
##   - EDITOR (@tool dock, M4): read ProjectSettings "input/<action>" directly,
##     because InputMap.action_get_events() returns EDITOR actions inside a
##     @tool/EditorPlugin context (verified against Godot 4.7 docs).
##
## Keyboard "zones" fall straight out of the InputMap: zone N uses the Nth keyboard
## event bound to each action (zone 0 = first key, zone 1 = second key, ...). So two
## players on one keyboard come from binding two keys per action in the Input Map.

const Cast := preload("res://addons/input_forge/tool/typed_cast.gd")

const NO_KEY: int = 0  # KEY_NONE
const NO_BUTTON: int = -1  # JOY_BUTTON_INVALID


## Ordered list of InputEvents for an action, from the chosen source.
static func events_for(action: StringName, use_project_settings: bool) -> Array[InputEvent]:
	if action == &"":
		return []
	if use_project_settings:
		return _events_from_project(action)
	return _events_from_runtime(action)


static func _events_from_runtime(action: StringName) -> Array[InputEvent]:
	if not InputMap.has_action(action):
		return []
	return InputMap.action_get_events(action)


static func _events_from_project(action: StringName) -> Array[InputEvent]:
	var setting: String = "input/" + String(action)
	if not ProjectSettings.has_setting(setting):
		return []
	var entry: Variant = ProjectSettings.get_setting(setting)
	if not (entry is Dictionary):
		return []
	var dict: Dictionary = Cast.to_dictionary(entry)
	if not dict.has("events"):
		return []
	var raw: Variant = dict["events"]
	if not (raw is Array):
		return []
	var out: Array[InputEvent] = []
	for item: Variant in Cast.to_array(raw):
		if item is InputEvent:
			out.append(Cast.to_input_event(item))
	return out


## Physical keycodes bound to an action, in InputMap order (zone selection).
static func keyboard_keycodes(action: StringName, use_project_settings: bool) -> Array[int]:
	var out: Array[int] = []
	for event: InputEvent in events_for(action, use_project_settings):
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			var code: int = int(key_event.physical_keycode)
			if code == NO_KEY:
				code = int(key_event.keycode)
			out.append(code)
	return out


## First joypad button bound to an action, or NO_BUTTON.
static func joypad_button(action: StringName, use_project_settings: bool) -> int:
	for event: InputEvent in events_for(action, use_project_settings):
		if event is InputEventJoypadButton:
			return int((event as InputEventJoypadButton).button_index)
	return NO_BUTTON


## First joypad-motion axis bound to an action (sign ignored), or -1.
static func joypad_axis(action: StringName, use_project_settings: bool) -> int:
	for event: InputEvent in events_for(action, use_project_settings):
		if event is InputEventJoypadMotion:
			return int((event as InputEventJoypadMotion).axis)
	return -1


## How many keyboard zones the InputMap supports for this action set: the smallest
## number of keyboard events bound across the four movement actions (each zone needs
## a full directional set). 0 if movement is unconfigured.
static func keyboard_zone_count(action_set: InputForgeActionSet, use_project_settings: bool) -> int:
	if action_set == null or not action_set.has_movement():
		return 0
	var dirs: Array[StringName] = [
		action_set.move_left, action_set.move_right, action_set.move_up, action_set.move_down,
	]
	var min_count: int = -1
	for dir: StringName in dirs:
		var count: int = keyboard_keycodes(dir, use_project_settings).size()
		if min_count < 0 or count < min_count:
			min_count = count
	return maxi(min_count, 0)


## Keyboard bindings for one zone: { action_name(StringName): physical_keycode(int) }
## covering the four movement actions plus every button action that has a keycode
## at this zone index. Missing keys are simply absent from the dictionary.
static func keyboard_zone(
	action_set: InputForgeActionSet, zone: int, use_project_settings: bool
) -> Dictionary:
	var bindings: Dictionary = {}
	if action_set == null:
		return bindings
	var actions: Array[StringName] = []
	if action_set.has_movement():
		actions.append_array([
			action_set.move_left, action_set.move_right,
			action_set.move_up, action_set.move_down,
		])
	actions.append_array(action_set.buttons)
	for action: StringName in actions:
		var codes: Array[int] = keyboard_keycodes(action, use_project_settings)
		if zone >= 0 and zone < codes.size():
			bindings[action] = codes[zone]
	return bindings


## Joypad button bindings: { button_action(StringName): button_index(int) } for the
## set's button actions that have a joypad button bound.
static func joypad_buttons(action_set: InputForgeActionSet, use_project_settings: bool) -> Dictionary:
	var bindings: Dictionary = {}
	if action_set == null:
		return bindings
	for action: StringName in action_set.buttons:
		var button: int = joypad_button(action, use_project_settings)
		if button != NO_BUTTON:
			bindings[action] = button
	return bindings
