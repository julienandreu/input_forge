class_name InputForgeMapWriter
## Reusable, game-agnostic InputMap writer. Building InputEvent objects by hand in
## project.godot is error-prone, so let the engine serialise them: a game or tool
## builds events with key()/button()/motion(), assigns them per action with
## set_action(), then calls save(). No game action names are baked in here.
##
## Intended to run from a SceneTree script, @tool, or EditorScript. set_action()
## mutates ProjectSettings in memory; save() persists project.godot.
##
## KEYBOARD-ZONE CONTRACT: list the keyboard events of each action in ZONE ORDER
## (the Nth keyboard event becomes keyboard zone N for InputForgeMapBindings).
## Joypad events may follow in any order; only keyboard events define zones.

const DEFAULT_DEADZONE: float = 0.5


## A physical-keycode key event (layout-independent; matches is_physical_key_pressed).
static func key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


static func button(button_index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	return event


static func motion(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


## Writes (or overwrites) one action's events + deadzone into ProjectSettings.
static func set_action(
	action: StringName, events: Array[InputEvent], deadzone: float = DEFAULT_DEADZONE
) -> void:
	var entry: Dictionary = {"deadzone": deadzone, "events": events}
	ProjectSettings.set_setting("input/" + String(action), entry)


## Removes an action if present (no-op otherwise).
static func remove_action(action: StringName) -> void:
	var setting: String = "input/" + String(action)
	if ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, null)


## Persists the in-memory ProjectSettings to project.godot.
static func save() -> Error:
	return ProjectSettings.save()
