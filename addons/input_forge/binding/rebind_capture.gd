@icon("res://addons/input_forge/icon.svg")
class_name InputForgeRebindCapture
extends Node
## While armed, captures the next key / joypad button / joypad axis flick and
## reports what to store: physical_keycode, button_index, or axis (+ sign).
## Listens in _input() - BEFORE _unhandled_input - so the InputForgeJoinListener never
## sees the captured event. The UI writes the result through
## InputForgeBindingsStore.save_profile(); it should offer Escape-to-cancel (call
## disarm()) and reject keys already used by another keyboard zone.

signal key_captured(physical_keycode: Key)
signal button_captured(button_index: JoyButton)
signal axis_captured(axis: JoyAxis, positive: bool)

const AXIS_CAPTURE_THRESHOLD: float = 0.5

var _armed: bool = false
var _device: InputForgeDeviceId = null


func _ready() -> void:
	set_process_input(false)  # Only listen while armed.


## Starts listening for the next binding on the given device. KEYBOARD devices
## capture keys (any zone - uniqueness is the UI's job); JOYPAD devices capture
## buttons/axes from that pad's index only.
func arm(device: InputForgeDeviceId) -> void:
	_device = device
	_armed = true
	set_process_input(true)


## Cancels an armed capture without emitting anything (e.g. UI pressed Escape).
func disarm() -> void:
	_finish()


func _input(event: InputEvent) -> void:
	if not _armed or _device == null:
		return
	if _device.kind == InputForgeDeviceId.Kind.KEYBOARD and event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_finish()
			# Store physical_keycode (never keycode/unicode): layout-independent
			# and it is what Input.is_physical_key_pressed() matches.
			key_captured.emit(key_event.physical_keycode)
			get_viewport().set_input_as_handled()
	elif _device.kind == InputForgeDeviceId.Kind.JOYPAD and event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed and button_event.device == _device.index:
			_finish()
			button_captured.emit(button_event.button_index)
			get_viewport().set_input_as_handled()
	elif _device.kind == InputForgeDeviceId.Kind.JOYPAD and event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if motion.device == _device.index and absf(motion.axis_value) >= AXIS_CAPTURE_THRESHOLD:
			_finish()
			axis_captured.emit(motion.axis, motion.axis_value > 0.0)
			get_viewport().set_input_as_handled()


func _finish() -> void:
	_armed = false
	set_process_input(false)
