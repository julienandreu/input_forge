extends SceneTree
## Headless unit test for the network command codec (InputForgeNetworkSource).
## The smoke tests do not stream button presses, so this exercises the codec
## directly: self-baseline (no phantom press), single-press survival across loss,
## multi-press preservation, cap coalescing, and held/move pass-through.
##
## Run: godot --headless --path . --script res://test/network_codec.gd

var _failures: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var actions := InputForgeActionSet.new()
	actions.buttons = [&"a", &"b"]
	var b: int = actions.button_index(&"b")

	var source := InputForgeNetworkSource.new()
	source.action_set = actions

	# First packet adopts the baseline WITHOUT emitting a press (M3).
	source.apply(Vector2.ZERO, 0, PackedByteArray([5, 9]))
	_check(source.poll().pressed_mask == 0, "first packet adopts baseline (no phantom press)")

	# Single press on 'a': counter 5 -> 6 -> exactly one edge.
	source.apply(Vector2.ZERO, 0, PackedByteArray([6, 9]))
	var first: InputForgeCommand = source.poll()
	_check(first.is_pressed(&"a") and not first.is_pressed(&"b"), "single press on a")
	_check(source.poll().pressed_mask == 0, "press consumed (one edge only)")

	# Isolated press survives a lost packet: we only see counter 7 (6 was dropped).
	source.apply(Vector2.ZERO, 0, PackedByteArray([7, 9]))
	_check(source.poll().is_pressed(&"a"), "isolated press survives packet loss")

	# Burst of 3 in one window (7 -> 10) drains as 3 edges across ticks (M1).
	source.apply(Vector2.ZERO, 0, PackedByteArray([10, 9]))
	var burst: int = 0
	for _i: int in 6:
		if source.poll().is_pressed(&"a"):
			burst += 1
	_check(burst == 3, "burst of 3 preserved across ticks (got %d)" % burst)

	# Beyond the cap (delta 10) coalesces to MAX_PENDING.
	source.apply(Vector2.ZERO, 0, PackedByteArray([20, 9]))
	var capped: int = 0
	for _i: int in 9:
		if source.poll().is_pressed(&"a"):
			capped += 1
	_check(
		capped == InputForgeNetworkSource.MAX_PENDING,
		"burst beyond cap coalesces to MAX_PENDING (got %d)" % capped,
	)

	# Held mask + move pass through; no spurious press when counters are unchanged.
	source.apply(Vector2(0.5, -0.25), 1 << b, PackedByteArray([20, 9]))
	var held: InputForgeCommand = source.poll()
	_check(held.is_held(&"b") and not held.is_held(&"a"), "held mask passes through")
	_check(held.move == Vector2(0.5, -0.25), "move passes through")
	_check(held.pressed_mask == 0, "unchanged counters emit no press")

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok: %s" % label)
	else:
		_failures.append(label)
		push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures.is_empty():
		print("NETWORK CODEC PASSED")
		quit(0)
	else:
		print("NETWORK CODEC FAILED: %s" % ", ".join(_failures))
		quit(1)
