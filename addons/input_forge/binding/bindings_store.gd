class_name InputForgeBindingsStore
extends RefCounted
## Persists InputForgeBindingProfile overrides to user://input_bindings.cfg via
## ConfigFile. Values are plain ints/floats (enum ordinals) - never serialized
## Objects. Joypad sections are keyed by SDL GUID (survives reconnect/index
## shuffle; all XInput pads on Windows share "__XINPUT_DEVICE__" and therefore
## share bindings - accepted). Keyboard sections are keyed by zone slot.
##
## The keyboard join action is deliberately NOT persisted: the lobby's "press
## <key> to join" hint is derived from the InputMap defaults, so a rebound join
## key would orphan that hint and could silently collide with another zone.

const Cast := preload("res://addons/input_forge/tool/typed_cast.gd")

const PATH: String = "user://input_bindings.cfg"


static func section_for(device: InputForgeDeviceId) -> String:
	if device.kind == InputForgeDeviceId.Kind.KEYBOARD:
		return "kb:%d" % device.index
	var guid: String = Input.get_joy_guid(device.index)
	return "joy:%s" % (guid if not guid.is_empty() else "unknown")


static func save_profile(device: InputForgeDeviceId, profile: InputForgeBindingProfile) -> Error:
	var cfg := ConfigFile.new()
	var _ignored: Error = cfg.load(PATH)  # Missing file on first run is fine.
	var section: String = section_for(device)
	if profile.kind == InputForgeDeviceId.Kind.KEYBOARD:
		for action: StringName in profile.keyboard:
			if action == profile.join_action:
				continue
			cfg.set_value(section, "kb/" + String(action), int(profile.keyboard[action]))
	else:
		cfg.set_value(section, "axis_x", int(profile.joy_axis_x))
		cfg.set_value(section, "axis_y", int(profile.joy_axis_y))
		cfg.set_value(section, "deadzone", profile.joy_deadzone)
		for action: StringName in profile.joy_buttons:
			cfg.set_value(section, "joy/" + String(action), int(profile.joy_buttons[action]))
	return cfg.save(PATH)


## Applies any stored overrides onto a deep duplicate of the default profile.
## get_value returns Variant; explicit int(...)/float(...) conversions satisfy
## strict typing and tolerate hand-edited cfg files.
static func load_profile(device: InputForgeDeviceId, defaults: InputForgeBindingProfile) -> InputForgeBindingProfile:
	if defaults == null:
		return InputForgeBindingProfile.new()  # Degrade to code defaults, never crash.
	var profile: InputForgeBindingProfile = defaults.duplicate(true) as InputForgeBindingProfile
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return profile  # First run / unreadable: defaults.
	var section: String = section_for(device)
	if not cfg.has_section(section):
		return profile
	if profile.kind == InputForgeDeviceId.Kind.KEYBOARD:
		for action: StringName in profile.keyboard:
			if action == profile.join_action:
				continue
			var key_name: String = "kb/" + String(action)
			profile.keyboard[action] = Cast.to_int(cfg.get_value(section, key_name, profile.key_for(action)))
	else:
		profile.joy_axis_x = Cast.to_int(cfg.get_value(section, "axis_x", int(profile.joy_axis_x))) as JoyAxis
		profile.joy_axis_y = Cast.to_int(cfg.get_value(section, "axis_y", int(profile.joy_axis_y))) as JoyAxis
		# Clamp so a hand-edited deadzone >= 1.0 cannot divide-by-zero the
		# radial rescale in InputForgeDeviceSource.
		profile.joy_deadzone = clampf(
			Cast.to_float(cfg.get_value(section, "deadzone", profile.joy_deadzone)), 0.0, 0.9)
		for action: StringName in profile.joy_buttons:
			var button_name: String = "joy/" + String(action)
			profile.joy_buttons[action] = Cast.to_int(
				cfg.get_value(section, button_name, profile.joy_button_for(action)))
	return profile
