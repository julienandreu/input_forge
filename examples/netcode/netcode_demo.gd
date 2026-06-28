extends SceneTree
## Netcode example for Input Forge (Godot 4.7) - the command codec, end to end.
##
## Run headless:
##   godot --headless --path . --script res://examples/netcode/netcode_demo.gd
##
## Shows how an authoritative server reconstructs press edges from a client's
## per-button 8-bit press counters, including recovery of a press whose packet was
## dropped. This example is NOT part of the shipped addon; it lives under examples/.

func _initialize() -> void:
	var action_set := InputForgeActionSet.new()
	action_set.buttons = [&"jump", &"dash"]

	var server := InputForgeNetworkSource.new()
	server.action_set = action_set

	# The client keeps an 8-bit press counter per button, incremented on each
	# fresh press, and streams the whole array every tick with move + held mask.
	# In a real game `_send()` would be an @rpc("unreliable_ordered") call.
	var counters := PackedByteArray([0, 0])

	print("tick 1: first packet -> server adopts the baseline, emits NO press")
	_send(server, counters)
	_drain(server, action_set)

	print("tick 2: client presses jump -> delivered")
	_press(counters, 0)
	_send(server, counters)
	_drain(server, action_set)

	print("tick 3: client presses jump again, but the packet is LOST (not sent)")
	_press(counters, 0)

	print("tick 4: next packet arrives; the counter delta recovers the lost press")
	_send(server, counters)
	_drain(server, action_set)

	server.free()
	print("done")
	quit()


func _press(counters: PackedByteArray, index: int) -> void:
	counters[index] = (counters[index] + 1) & 0xFF


func _send(server: InputForgeNetworkSource, counters: PackedByteArray) -> void:
	server.apply(Vector2.ZERO, 0, counters)


func _drain(server: InputForgeNetworkSource, action_set: InputForgeActionSet) -> void:
	var command: InputForgeCommand = server.poll()
	var pressed: Array[String] = []
	for action: StringName in action_set.buttons:
		if command.is_pressed(action):
			pressed.append(String(action))
	print("  server.poll() pressed = ", pressed)
