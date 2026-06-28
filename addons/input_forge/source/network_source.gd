class_name InputForgeNetworkSource
extends InputForgeSource
## Server-side input for a remote player. The owning client streams move, held
## state, and per-button wrapping 8-bit press counters; this source turns counter
## DELTAS back into press edges and drains at most one press per button per poll(),
## so a rapid multi-press is preserved across ticks rather than coalesced into one.
##
## Loss behaviour: an isolated press is never lost (the counter still differs when
## the next packet arrives). Several presses inside a single window of consecutive
## lost packets are recovered up to MAX_PENDING; beyond that they coalesce. (A full
## 256-press wrap inside one loss window would be missed, but that is impossible at
## real tick rates.) Transport must be ordered (unreliable_ordered) so counters
## never regress and a delta is never double-counted.
##
## Self-contained baseline: the FIRST packet for a source is ADOPTED as the counter
## baseline WITHOUT emitting any press, so correctness does not depend on the sender
## resetting its counters or on when the host creates/frees sources.

const MAX_PENDING: int = 4  ## Cap queued presses per button (avoids buildup after a long stall).

var action_set: InputForgeActionSet = null

var _move: Vector2 = Vector2.ZERO
var _held_mask: int = 0
var _initialized: bool = false
var _last_counters: PackedByteArray = PackedByteArray()
var _pending: PackedInt32Array = PackedInt32Array()


func apply(move: Vector2, held_mask: int, counters: PackedByteArray) -> void:
	_move = move
	_held_mask = held_mask
	if _pending.size() != counters.size():
		_pending.resize(counters.size())
	# First packet (or a button-count change): adopt the baseline, do not latch.
	if not _initialized or _last_counters.size() != counters.size():
		_last_counters = counters.duplicate()
		_initialized = true
		return
	for index: int in counters.size():
		var delta: int = (int(counters[index]) - int(_last_counters[index])) & 0xFF
		if delta > 0:
			_pending[index] = mini(_pending[index] + delta, MAX_PENDING)
	_last_counters = counters.duplicate()


func poll() -> InputForgeCommand:
	var command := InputForgeCommand.new(action_set)
	command.move = _move
	command.held_mask = _held_mask
	var pressed: int = 0
	for index: int in _pending.size():
		if _pending[index] > 0:
			pressed |= 1 << index
			_pending[index] -= 1
	command.pressed_mask = pressed
	return command
