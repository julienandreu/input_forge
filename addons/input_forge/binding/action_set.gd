@icon("res://addons/input_forge/icon.svg")
class_name InputForgeActionSet
extends Resource
## Describes the set of Godot InputMap actions this input layer manages, as DATA -
## no specific game action (jump/dash/...) is hardcoded. A 2D movement is built
## from four directional actions; everything else is an ordered list of button
## actions. The button order is load-bearing: it defines the bit index each button
## occupies in InputForgeCommand and in the network codec, so it must stay stable for
## the lifetime of a session.
##
## Action NAMES live in the project's Godot InputMap; this resource only selects
## and orders them. Per-device key/button bindings are DERIVED from the InputMap
## by InputForgeMapBindings - this resource holds no keycodes.
##
## Wire limit: the reference network codec packs held state as a 32-bit mask, so
## keep button_count() <= MAX_BUTTONS (32) if you stream commands over the network.

const MAX_BUTTONS: int = 32

# Declared BEFORE `buttons` so the buttons setter can clear it safely during member
# initialisation (initialisers run top-to-bottom). action -> bit index, built lazily.
var _index_cache: Dictionary[StringName, int] = {}

## The four directional movement actions (empty StringName = "no movement axis").
@export var move_left: StringName = &""
@export var move_right: StringName = &""
@export var move_up: StringName = &""
@export var move_down: StringName = &""

## Ordered button actions. Index in this array == bit index in command bitmasks
## and codec counters. Keep stable across a session.
@export var buttons: Array[StringName] = []:
	set(value):
		buttons = value
		_index_cache.clear()

## The button action whose per-device binding doubles as the lobby "press to join"
## gesture. Must be one of `buttons` (or empty to disable name-based join). For a
## keyboard zone this is the zone's join key; for a joypad the listener also
## accepts the platform Start/face button (see the join listener).
@export var join_action: StringName = &""


## True when at least the horizontal movement pair is configured.
func has_movement() -> bool:
	return move_left != &"" and move_right != &"" and move_up != &"" and move_down != &""


## Stable bit index of a button action, or -1 if not part of this set. Cached.
func button_index(action: StringName) -> int:
	if _index_cache.is_empty() and not buttons.is_empty():
		for i: int in buttons.size():
			_index_cache[buttons[i]] = i
	return int(_index_cache.get(action, -1))


## Number of button actions (== number of bits used by command bitmasks).
func button_count() -> int:
	return buttons.size()
