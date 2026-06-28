extends Node2D
## Couch co-op example for Input Forge (Godot 4.7).
##
## Run this scene (F6). It sets up a small InputMap at runtime, then lets devices
## join by pressing their join key/button:
##   - Keyboard zone 0: WASD to move, Space to join + jump.
##   - Keyboard zone 1: Arrow keys to move, Enter to join + jump.
##   - Any gamepad: left stick / D-pad to move, A or Start to join + jump.
## Each joined device gets a colored square it drives independently - the whole
## point of Input Forge: per-device input without a `device` field on actions.
##
## This example is NOT part of the shipped addon; it lives under examples/.

const MOVE_SPEED: float = 320.0

var _action_set: InputForgeActionSet = null
var _listener: InputForgeJoinListener = null
var _sources: Dictionary[String, InputForgeDeviceSource] = {}
var _avatars: Dictionary[String, ColorRect] = {}

var _colors: Array[Color] = [
	Color.CRIMSON, Color.DODGER_BLUE, Color.LIME_GREEN, Color.GOLD,
	Color.MEDIUM_PURPLE, Color.ORANGE,
]


func _ready() -> void:
	_setup_input_map()

	_action_set = InputForgeActionSet.new()
	_action_set.move_left = &"if_demo_left"
	_action_set.move_right = &"if_demo_right"
	_action_set.move_up = &"if_demo_up"
	_action_set.move_down = &"if_demo_down"
	_action_set.buttons = [&"if_demo_jump"]
	_action_set.join_action = &"if_demo_jump"

	_listener = InputForgeJoinListener.new()
	_listener.action_set = _action_set
	add_child(_listener)
	_listener.join_requested.connect(_on_join_requested)
	_listener.leave_requested.connect(_on_leave_requested)

	_add_instructions()


## Populate the LIVE InputMap (the runtime derivation source). The Nth keyboard
## event of each action becomes keyboard zone N.
func _setup_input_map() -> void:
	_bind(&"if_demo_left", [
		InputForgeMapWriter.key(KEY_A), InputForgeMapWriter.key(KEY_LEFT),
		InputForgeMapWriter.motion(JOY_AXIS_LEFT_X, -1.0),
	])
	_bind(&"if_demo_right", [
		InputForgeMapWriter.key(KEY_D), InputForgeMapWriter.key(KEY_RIGHT),
		InputForgeMapWriter.motion(JOY_AXIS_LEFT_X, 1.0),
	])
	_bind(&"if_demo_up", [
		InputForgeMapWriter.key(KEY_W), InputForgeMapWriter.key(KEY_UP),
		InputForgeMapWriter.motion(JOY_AXIS_LEFT_Y, -1.0),
	])
	_bind(&"if_demo_down", [
		InputForgeMapWriter.key(KEY_S), InputForgeMapWriter.key(KEY_DOWN),
		InputForgeMapWriter.motion(JOY_AXIS_LEFT_Y, 1.0),
	])
	_bind(&"if_demo_jump", [
		InputForgeMapWriter.key(KEY_SPACE), InputForgeMapWriter.key(KEY_ENTER),
		InputForgeMapWriter.button(JOY_BUTTON_A),
	])


func _bind(action: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


func _on_join_requested(device: InputForgeDeviceId, profile: InputForgeBindingProfile) -> void:
	var key: String = device.to_key()
	if _sources.has(key):
		return
	var source := InputForgeDeviceSource.new(device, profile, _action_set)
	add_child(source)
	_sources[key] = source

	var avatar := ColorRect.new()
	avatar.size = Vector2(48.0, 48.0)
	avatar.color = _colors[_avatars.size() % _colors.size()]
	avatar.position = get_viewport_rect().size * 0.5
	add_child(avatar)
	_avatars[key] = avatar


func _on_leave_requested(device: InputForgeDeviceId) -> void:
	var key: String = device.to_key()
	if _sources.has(key):
		_sources[key].queue_free()
		var _removed_source: bool = _sources.erase(key)
	if _avatars.has(key):
		_avatars[key].queue_free()
		var _removed_avatar: bool = _avatars.erase(key)


func _physics_process(delta: float) -> void:
	for key: String in _sources:
		var command: InputForgeCommand = _sources[key].poll()
		var avatar: ColorRect = _avatars[key]
		avatar.position += command.move * MOVE_SPEED * delta
		# A jump press flashes the square brighter for one tick.
		if command.is_pressed(&"if_demo_jump"):
			avatar.modulate = Color(1.5, 1.5, 1.5)
		elif not command.is_held(&"if_demo_jump"):
			avatar.modulate = Color.WHITE


func _add_instructions() -> void:
	var label := Label.new()
	label.position = Vector2(16.0, 16.0)
	label.text = (
		"Input Forge - couch co-op demo\n"
		+ "Keyboard 0: WASD + Space to join.  Keyboard 1: Arrows + Enter to join.\n"
		+ "Gamepad: A or Start to join.  Press join again = leave."
	)
	add_child(label)
