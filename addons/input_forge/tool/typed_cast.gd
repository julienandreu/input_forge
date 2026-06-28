extends RefCounted
## Centralised, audited `Variant` -> concrete-type conversions (INTERNAL).
##
## Godot's data-driven APIs are untyped by nature: `ConfigFile.get_value()`,
## `ProjectSettings.get_setting()`, `Dictionary`/`Array` iteration and `[]` access
## on untyped containers, `InputEvent` polymorphism and `Object.new()` all return
## `Variant`. Under Input Forge's strict gate (`unsafe_*` warnings = errors) every
## narrowing of such a `Variant` is a hard error.
##
## The UNAVOIDABLE narrowings are quarantined here, one per function, each behind a
## single localised `@warning_ignore` with a comment, so the unsafe surface is
## auditable in ONE file instead of scattered across the addon. Call sites stay
## fully typed. Avoidable narrowings (e.g. `.get()` on a *typed* dictionary) are
## fixed at the source instead of routed through here.
##
## This is an internal helper: it deliberately has no `class_name`, so it does not
## appear in the editor Create dialog or the public API. Consumers `preload()` it.

## Variant -> int. For values Godot returns as Variant but that are numeric
## (ConfigFile/Dictionary lookups, JoyAxis/Key enums stored as ints).
static func to_int(value: Variant) -> int:
	@warning_ignore("unsafe_call_argument")
	return int(value)


## Variant -> float (deadzones and other ConfigFile-stored floats).
static func to_float(value: Variant) -> float:
	@warning_ignore("unsafe_call_argument")
	return float(value)


## Variant -> String (display/debug text built from Variant dictionary keys).
## Named `to_str` (not `to_string`) to avoid shadowing native `Object.to_string()`.
static func to_str(value: Variant) -> String:
	@warning_ignore("unsafe_call_argument")
	return String(value)


## Variant -> StringName (action names used as untyped dictionary keys).
static func to_string_name(value: Variant) -> StringName:
	@warning_ignore("unsafe_cast")
	return value as StringName


## Variant -> Dictionary (ProjectSettings `input/*` action entries).
static func to_dictionary(value: Variant) -> Dictionary:
	@warning_ignore("unsafe_cast")
	return value as Dictionary


## Variant -> Array (the `events` array inside a ProjectSettings action entry).
static func to_array(value: Variant) -> Array:
	@warning_ignore("unsafe_cast")
	return value as Array


## Variant -> InputEvent (polymorphic events pulled from an untyped Array).
## Returns null when the value is not an InputEvent (callers null-check).
static func to_input_event(value: Variant) -> InputEvent:
	@warning_ignore("unsafe_cast")
	return value as InputEvent
