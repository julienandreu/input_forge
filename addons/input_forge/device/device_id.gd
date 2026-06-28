class_name InputForgeDeviceId
extends RefCounted
## Identifies one logical local input device: a specific joypad, or one
## key-zone of the single shared keyboard. The OS merges all physical keyboards
## into one stream, so KEYBOARD `index` is a key-zone slot (0 = WASD,
## 1 = arrows, ...), never an OS device id (the OS merges all keyboards into one).

enum Kind { KEYBOARD, JOYPAD }

var kind: Kind = Kind.JOYPAD
var index: int = 0  ## JOYPAD: Input device index. KEYBOARD: key-zone slot.


func _init(p_kind: Kind = Kind.JOYPAD, p_index: int = 0) -> void:
	kind = p_kind
	index = p_index


func equals(other: InputForgeDeviceId) -> bool:
	return other != null and kind == other.kind and index == other.index


## Stable string key for dictionaries and ConfigFile sections, e.g. "joy:1".
func to_key() -> String:
	return ("kb:%d" if kind == Kind.KEYBOARD else "joy:%d") % index


## UI label. Joypads use the SDL controller database name.
func describe() -> String:
	if kind == Kind.KEYBOARD:
		return "Keyboard (zone %d)" % index
	return "%s (#%d)" % [Input.get_joy_name(index), index]


## The keyboard is always "connected"; joypad indices are only valid while the
## pad stays plugged in (indices are reused after a disconnect).
func is_connected_device() -> bool:
	if kind == Kind.KEYBOARD:
		return true
	return Input.get_connected_joypads().has(index)
