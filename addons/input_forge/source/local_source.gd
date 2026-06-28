class_name InputForgeLocalSource
extends InputForgeSource
## Reads the SHARED input map and produces a InputForgeCommand. This merges keyboard
## and all gamepads, so it is only suitable for single-local-player sessions and
## quick testing. Per-device couch co-op uses InputForgeDeviceSource instead.

var action_set: InputForgeActionSet = null


func _init(p_action_set: InputForgeActionSet = null) -> void:
	action_set = p_action_set


func poll() -> InputForgeCommand:
	var command := InputForgeCommand.new(action_set)
	if action_set == null:
		return command
	if action_set.has_movement():
		command.move = Input.get_vector(
			action_set.move_left, action_set.move_right,
			action_set.move_up, action_set.move_down,
		)
	for index: int in action_set.buttons.size():
		var action: StringName = action_set.buttons[index]
		command.set_button(
			index,
			Input.is_action_just_pressed(action),
			Input.is_action_pressed(action),
		)
	return command
