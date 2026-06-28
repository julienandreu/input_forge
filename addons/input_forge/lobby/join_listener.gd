@icon("res://addons/input_forge/icon.svg")
class_name InputForgeJoinListener
extends Node
## Lobby-only node: "press Jump/Start to join". Event-driven in
## _unhandled_input so UI keeps priority (and InputForgeRebindCapture, which listens in
## _input, always wins). Emits a InputForgeDeviceId + ready-to-use InputForgeBindingProfile per
## claim; the lobby creates a InputForgeSlot with a InputForgeDeviceSource for it.
##
## Devices are identified by event CLASS first (InputEventJoypadButton =>
## joypad event.device; InputEventKey => physical_keycode matched against each
## unclaimed zone's join action binding). Never identify a keyboard by event.device - the
## keyboard/mouse id namespace can collide with joypad index 0.

signal join_requested(device: InputForgeDeviceId, profile: InputForgeBindingProfile)
signal leave_requested(device: InputForgeDeviceId)
signal device_lost(device: InputForgeDeviceId)
## An ALREADY-claimed device pressed its join input again. Lobbies read this as
## the couch "ready/start" gesture - the only keyboard/gamepad path to Start,
## since lobby buttons deliberately never take focus (FOCUS RULE in the menus).
signal claimed_join_pressed(device: InputForgeDeviceId)

const JOIN_BUTTON: JoyButton = JOY_BUTTON_START
const JOIN_BUTTON_ALT: JoyButton = JOY_BUTTON_A
const LEAVE_BUTTON: JoyButton = JOY_BUTTON_BACK

## Key-zone profiles in claim order. Left empty (the normal case), they resolve
## from action_set in _ready; export remains for scene-level experiments.
@export var keyboard_profiles: Array[InputForgeBindingProfile] = []
## Defaults for any joypad. Left null, resolves from action_set in _ready.
@export var joypad_default_profile: InputForgeBindingProfile = null

## Game-agnostic action selection. Callers must set this before add_child(); if
## null, default profile resolution is skipped and no implicit game globals are
## used here.
var action_set: InputForgeActionSet = null

var _claimed: Dictionary[String, InputForgeDeviceId] = {}


func _ready() -> void:
	if keyboard_profiles.is_empty() and action_set != null:
		keyboard_profiles = InputForgeBindingDefaults.keyboard_zones(action_set)
	if joypad_default_profile == null and action_set != null:
		joypad_default_profile = InputForgeBindingDefaults.joypad_default(action_set)
	var joy_error: Error = Input.joy_connection_changed.connect(_on_joy_connection_changed)
	assert(joy_error == OK)


## The currently claimed devices, in no particular order.
func claimed() -> Array[InputForgeDeviceId]:
	var devices: Array[InputForgeDeviceId] = []
	for device: InputForgeDeviceId in _claimed.values():
		devices.append(device)
	return devices


func is_claimed(device: InputForgeDeviceId) -> bool:
	return _claimed.has(device.to_key())


## Clears every claim WITHOUT emitting leave_requested - for lobby
## teardown/reset, where the caller is discarding all slots anyway.
func release_all() -> void:
	_claimed.clear()


## Seeds a claim WITHOUT emitting join_requested - for menus (re)entered while
## the host already holds slots for these devices (e.g. returning from a
## match): leave (pad BACK) and ready presses keep working for kept slots.
func claim_existing(device: InputForgeDeviceId) -> void:
	if device != null:
		_claimed[device.to_key()] = device


## Drops one claim WITHOUT emitting leave_requested - for UI-driven removal
## where the caller vacates its own slot.
func release_claim(device: InputForgeDeviceId) -> void:
	if device != null:
		var _erased: bool = _claimed.erase(device.to_key())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if not button_event.pressed:
			return
		if button_event.device < 0:
			return  # DEVICE_ID_EMULATION / _INTERNAL (negative) are not real pads.
		var device := InputForgeDeviceId.new(InputForgeDeviceId.Kind.JOYPAD, button_event.device)
		if button_event.button_index == JOIN_BUTTON \
				or button_event.button_index == JOIN_BUTTON_ALT:
			if is_claimed(device):
				claimed_join_pressed.emit(device)
				get_viewport().set_input_as_handled()
				return
			if joypad_default_profile == null:
				return
			_try_claim(device, InputForgeBindingsStore.load_profile(device, joypad_default_profile))
		elif button_event.button_index == LEAVE_BUTTON:
			_release(device)
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		for zone: int in keyboard_profiles.size():
			var device := InputForgeDeviceId.new(InputForgeDeviceId.Kind.KEYBOARD, zone)
			if is_claimed(device):
				# A claimed zone's join key reads as the ready/start gesture.
				# The join key always comes from defaults (never persisted).
				if int(key_event.physical_keycode) == _join_key(keyboard_profiles[zone]):
					claimed_join_pressed.emit(device)
					get_viewport().set_input_as_handled()
					return
				continue
			# Loaded profile = InputMap defaults + user overrides; the join key
			# always comes from the defaults (InputForgeBindingsStore never persists it).
			var profile: InputForgeBindingProfile = InputForgeBindingsStore.load_profile(device, keyboard_profiles[zone])
			if int(key_event.physical_keycode) == _join_key(profile):
				_try_claim(device, profile)
				return


func _try_claim(device: InputForgeDeviceId, profile: InputForgeBindingProfile) -> void:
	if _claimed.has(device.to_key()):
		return
	_claimed[device.to_key()] = device
	join_requested.emit(device, profile)
	get_viewport().set_input_as_handled()


func _join_key(profile: InputForgeBindingProfile) -> int:
	if profile == null or profile.join_action == &"":
		return 0
	# Typed-dict indexing is statically `int`; avoids narrowing a Variant from .get().
	return profile.keyboard[profile.join_action] if profile.keyboard.has(profile.join_action) else 0


func _release(device: InputForgeDeviceId) -> void:
	if _claimed.erase(device.to_key()):
		leave_requested.emit(device)


func _on_joy_connection_changed(device_index: int, connected: bool) -> void:
	if connected:
		return
	var key: String = "joy:%d" % device_index
	if _claimed.has(key):
		var lost: InputForgeDeviceId = _claimed[key]
		var _erased: bool = _claimed.erase(key)
		device_lost.emit(lost)  # Lobby pauses the slot / shows "reconnect pad".
