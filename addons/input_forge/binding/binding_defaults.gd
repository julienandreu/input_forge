class_name InputForgeBindingDefaults
## Code-built default binding profiles derived from the project's InputMap. This
## keeps device defaults in one source of truth: edit the InputMap and the couch
## keyboard zones / gamepad button defaults follow.

const Cast := preload("res://addons/input_forge/tool/typed_cast.gd")


## Keyboard key-zone profiles, in InputMap order. A zone's index doubles as the
## KEYBOARD InputForgeDeviceId.index.
static func keyboard_zones(
	action_set: InputForgeActionSet, use_project_settings: bool = false
) -> Array[InputForgeBindingProfile]:
	var zones: Array[InputForgeBindingProfile] = []
	var zone_count: int = InputForgeMapBindings.keyboard_zone_count(action_set, use_project_settings)
	for zone: int in zone_count:
		var profile := InputForgeBindingProfile.new()
		profile.kind = InputForgeDeviceId.Kind.KEYBOARD
		profile.display_name = "Keyboard zone %d" % zone
		profile.keyboard = _typed_bindings(
			InputForgeMapBindings.keyboard_zone(action_set, zone, use_project_settings))
		profile.join_action = action_set.join_action if action_set != null else &""
		zones.append(profile)
	return zones


## Default layout applied to ANY joypad index (overrides are stored per-GUID).
static func joypad_default(
	action_set: InputForgeActionSet, use_project_settings: bool = false
) -> InputForgeBindingProfile:
	var profile := InputForgeBindingProfile.new()
	profile.kind = InputForgeDeviceId.Kind.JOYPAD
	profile.display_name = "Gamepad"
	profile.joy_buttons = _typed_bindings(
		InputForgeMapBindings.joypad_buttons(action_set, use_project_settings))
	if action_set != null:
		var axis_x: int = InputForgeMapBindings.joypad_axis(action_set.move_right, use_project_settings)
		var axis_y: int = InputForgeMapBindings.joypad_axis(action_set.move_down, use_project_settings)
		profile.joy_axis_x = (axis_x if axis_x != -1 else JOY_AXIS_LEFT_X) as JoyAxis
		profile.joy_axis_y = (axis_y if axis_y != -1 else JOY_AXIS_LEFT_Y) as JoyAxis
		profile.join_action = action_set.join_action
	profile.joy_use_dpad_fallback = true
	profile.joy_deadzone = 0.3
	return profile


static func _typed_bindings(raw: Dictionary) -> Dictionary[StringName, int]:
	var bindings: Dictionary[StringName, int] = {}
	for key: Variant in raw:
		if key is StringName:
			bindings[Cast.to_string_name(key)] = Cast.to_int(raw[key])
		elif key is String:
			bindings[StringName(Cast.to_str(key))] = Cast.to_int(raw[key])
	return bindings
