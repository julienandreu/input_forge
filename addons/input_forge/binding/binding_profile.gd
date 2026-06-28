@icon("res://addons/input_forge/icon.svg")
class_name InputForgeBindingProfile
extends Resource
## Data definition for one device layout. KEYBOARD profiles are action-keyed key
## zones on the single shared keyboard; JOYPAD profiles apply to any joypad index.
## Defaults are derived from the project InputMap by InputForgeBindingDefaults, and
## user overrides are layered on top by InputForgeBindingsStore.load_profile().

@export var kind: InputForgeDeviceId.Kind = InputForgeDeviceId.Kind.JOYPAD
@export var display_name: String = ""

@export_group("Keyboard")
## Action -> physical keycode. Covers movement directions and button actions.
@export var keyboard: Dictionary[StringName, int] = {}
## The action whose keyboard binding doubles as the lobby join key. It is never
## persisted or rebound so lobby hints stay true and zones stay non-overlapping.
@export var join_action: StringName = &""

@export_group("Joypad", "joy_")
@export var joy_axis_x: JoyAxis = JOY_AXIS_LEFT_X
@export var joy_axis_y: JoyAxis = JOY_AXIS_LEFT_Y
@export var joy_buttons: Dictionary[StringName, int] = {}
@export var joy_use_dpad_fallback: bool = true
@export_range(0.0, 0.9, 0.01) var joy_deadzone: float = 0.3


func key_for(action: StringName) -> int:
	# Typed-dict indexing is statically `int`; avoids narrowing a Variant from .get().
	return keyboard[action] if keyboard.has(action) else 0


func joy_button_for(action: StringName) -> int:
	return joy_buttons[action] if joy_buttons.has(action) else -1
