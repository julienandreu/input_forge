class_name InputForgeDeviceSource
extends InputForgeSource
## Polls ONE logical device (a joypad index, or one keyboard key-zone) and
## produces an InputForgeCommand. Bypasses the shared action map on purpose: the
## action API has no device parameter, so per-player input must poll raw
## device state directly.
##
## Press edges are computed here from previous-tick held state. poll() must be
## called exactly once per physics tick: polling faster than the consumer drops
## edges, polling slower doubles them.

var device: InputForgeDeviceId = null
var profile: InputForgeBindingProfile = null
var action_set: InputForgeActionSet = null

var _prev_held_mask: int = 0


func _init(
	p_device: InputForgeDeviceId = null, p_profile: InputForgeBindingProfile = null, p_action_set: InputForgeActionSet = null
) -> void:
	device = p_device
	profile = p_profile
	action_set = p_action_set


func poll() -> InputForgeCommand:
	var command := InputForgeCommand.new(action_set)
	if device == null or profile == null or action_set == null or not device.is_connected_device():
		# Neutral command: missing/unplugged devices degrade to "no input"
		# (slot UI shows "controller lost"). Edge state resets so a button
		# still held on reconnect produces a fresh press edge.
		_prev_held_mask = 0
		return command

	if device.kind == InputForgeDeviceId.Kind.KEYBOARD:
		command.move = _poll_keyboard_move()
	else:
		command.move = _poll_joypad_move()

	for index: int in action_set.buttons.size():
		var action: StringName = action_set.buttons[index]
		var held: bool = _button_held(action)
		var pressed: bool = held and (_prev_held_mask & (1 << index)) == 0
		command.set_button(index, pressed, held)
	_prev_held_mask = command.held_mask
	return command


## UI label for the polled device, e.g. "Keyboard (zone 0)" or "PS5 Controller (#1)".
func describe() -> String:
	if device == null:
		return "No device"
	return device.describe()


func _button_held(action: StringName) -> bool:
	if device.kind == InputForgeDeviceId.Kind.KEYBOARD:
		return _physical_key_pressed(action)
	var button: int = profile.joy_button_for(action)
	return button >= 0 and Input.is_joy_button_pressed(device.index, button as JoyButton)


func _physical_key_pressed(action: StringName) -> bool:
	var keycode: Key = profile.key_for(action) as Key
	return int(keycode) != 0 and Input.is_physical_key_pressed(keycode)


func _poll_keyboard_move() -> Vector2:
	var move := Vector2.ZERO
	if _physical_key_pressed(action_set.move_left):
		move.x -= 1.0
	if _physical_key_pressed(action_set.move_right):
		move.x += 1.0
	if _physical_key_pressed(action_set.move_up):
		move.y -= 1.0
	if _physical_key_pressed(action_set.move_down):
		move.y += 1.0
	return move.limit_length(1.0)


func _poll_joypad_move() -> Vector2:
	var raw := Vector2(
		Input.get_joy_axis(device.index, profile.joy_axis_x),
		Input.get_joy_axis(device.index, profile.joy_axis_y),
	)
	var move: Vector2 = _apply_radial_deadzone(raw, profile.joy_deadzone)
	if move == Vector2.ZERO and profile.joy_use_dpad_fallback:
		if Input.is_joy_button_pressed(device.index, JOY_BUTTON_DPAD_LEFT):
			move.x -= 1.0
		if Input.is_joy_button_pressed(device.index, JOY_BUTTON_DPAD_RIGHT):
			move.x += 1.0
		if Input.is_joy_button_pressed(device.index, JOY_BUTTON_DPAD_UP):
			move.y -= 1.0
		if Input.is_joy_button_pressed(device.index, JOY_BUTTON_DPAD_DOWN):
			move.y += 1.0
	return move.limit_length(1.0)


## Circular deadzone with range rescaling, mirroring Input.get_vector's
## documented behaviour. Per-axis deadzones would distort diagonals. Output is
## continuous: 0 at the deadzone edge up to 1 at full deflection, then clamped
## (cheap pads overshoot the unit circle on diagonals).
func _apply_radial_deadzone(raw: Vector2, deadzone: float) -> Vector2:
	var length: float = raw.length()
	if length <= deadzone:
		return Vector2.ZERO
	var rescaled: float = minf((length - deadzone) / (1.0 - deadzone), 1.0)
	return raw * (rescaled / length)
