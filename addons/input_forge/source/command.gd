class_name InputForgeCommand
extends RefCounted
## Abstract input intent for a single player slot, decoupled from the input device
## and from the network peer. Button actions are addressed by their index in the
## InputForgeActionSet so gameplay and netcode do not hardcode jump/dash fields.

var action_set: InputForgeActionSet = null
var move: Vector2 = Vector2.ZERO ## Desired move direction, each axis in [-1, 1].
var pressed_mask: int = 0 ## Bit i set = button i had a press edge this tick.
var held_mask: int = 0 ## Bit i set = button i is currently held.


func _init(p_action_set: InputForgeActionSet = null) -> void:
	action_set = p_action_set


func is_pressed(action: StringName) -> bool:
	if action_set == null:
		return false
	var index: int = action_set.button_index(action)
	return index >= 0 and (pressed_mask & (1 << index)) != 0


func is_held(action: StringName) -> bool:
	if action_set == null:
		return false
	var index: int = action_set.button_index(action)
	return index >= 0 and (held_mask & (1 << index)) != 0


func set_button(index: int, pressed: bool, held: bool) -> void:
	if index < 0:
		return
	var bit: int = 1 << index
	if pressed:
		pressed_mask |= bit
	else:
		pressed_mask &= ~bit
	if held:
		held_mask |= bit
	else:
		held_mask &= ~bit
