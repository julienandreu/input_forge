# Input Forge - API reference

Curated reference for the public `class_name` types Input Forge exposes. Requires
**Godot 4.7+**. For the conceptual overview and setup, see the
[addon README](https://github.com/julienandreu/input_forge/blob/main/addons/input_forge/README.md);
for end-to-end walkthroughs see the [tutorials](tutorials.md).

All public classes carry a `class_name`, so they appear in the editor Create
dialog and are usable without `preload`. Internal helpers (e.g. `tool/typed_cast.gd`)
deliberately have no `class_name`.

## Contents

- [Configuration](#configuration) - `InputForgeActionSet`, `InputForgeBindingProfile`
- [Derivation](#derivation) - `InputForgeBindingDefaults`, `InputForgeMapBindings`, `InputForgeMapWriter`
- [Persistence and rebinding](#persistence-and-rebinding) - `InputForgeBindingsStore`, `InputForgeRebindCapture`
- [Devices](#devices) - `InputForgeDeviceId`, `InputForgeIconProvider`
- [Lobby](#lobby) - `InputForgeJoinListener`
- [Sources and commands](#sources-and-commands) - `InputForgeSource` and subclasses, `InputForgeCommand`, `InputForgeSlot`

---

## Configuration

### `InputForgeActionSet` (Resource)

Selects and orders the project's Godot InputMap actions this layer manages. Holds
no keycodes - per-device bindings are derived from the InputMap.

| Member | Type | Notes |
|--------|------|-------|
| `move_left/right/up/down` | `StringName` | The four directional actions (empty = no axis). |
| `buttons` | `Array[StringName]` | Ordered button actions. **Index == bit index** in command masks and codec counters; keep stable for a session. |
| `join_action` | `StringName` | The button action that doubles as the lobby join gesture. |
| `MAX_BUTTONS` | `const int = 32` | Wire limit: the codec packs held state as a 32-bit mask. |

| Method | Returns | Notes |
|--------|---------|-------|
| `has_movement()` | `bool` | True when the horizontal+vertical pairs are set. |
| `button_index(action: StringName)` | `int` | Stable bit index of a button action, or `-1`. Cached. |
| `button_count()` | `int` | Number of button actions (bits used). |

### `InputForgeBindingProfile` (Resource)

One device layout. KEYBOARD profiles map actions to key-zones on the shared
keyboard; JOYPAD profiles apply to any joypad index.

| Member | Type | Notes |
|--------|------|-------|
| `kind` | `InputForgeDeviceId.Kind` | `KEYBOARD` or `JOYPAD`. |
| `display_name` | `String` | UI label. |
| `keyboard` | `Dictionary[StringName, int]` | action -> physical keycode. |
| `join_action` | `StringName` | Keyboard join key; never persisted or rebound. |
| `joy_axis_x` / `joy_axis_y` | `JoyAxis` | Movement axes. |
| `joy_buttons` | `Dictionary[StringName, int]` | action -> joypad button index. |
| `joy_use_dpad_fallback` | `bool` | D-pad as movement when sticks are neutral. |
| `joy_deadzone` | `float` | `0.0 .. 0.9`. |

| Method | Returns | Notes |
|--------|---------|-------|
| `key_for(action: StringName)` | `int` | Keycode for an action, or `0`. |
| `joy_button_for(action: StringName)` | `int` | Button index for an action, or `-1`. |

---

## Derivation

### `InputForgeBindingDefaults`

Builds default profiles by deriving from the InputMap (static).

| Method | Returns |
|--------|---------|
| `keyboard_zones(action_set, use_project_settings := false)` | `Array[InputForgeBindingProfile]` |
| `joypad_default(action_set, use_project_settings := false)` | `InputForgeBindingProfile` |

`use_project_settings = true` reads `ProjectSettings input/*` (editor-safe inside a
`@tool` context); `false` reads the live `InputMap` at runtime. Both agree.

### `InputForgeMapBindings`

The derivation itself (static): keyboard zones, joypad buttons/axes from the
InputMap. Key methods: `events_for`, `keyboard_keycodes`, `joypad_button`,
`joypad_axis`, `keyboard_zone_count`, `keyboard_zone`, `joypad_buttons`.

### `InputForgeMapWriter`

Reusable, game-agnostic helper to write the project InputMap from code (static).
Run from a SceneTree script, `@tool`, or `EditorScript`.

| Method | Returns | Notes |
|--------|---------|-------|
| `key(keycode: Key)` | `InputEventKey` | Physical-keycode key event. |
| `button(button_index: JoyButton)` | `InputEventJoypadButton` | |
| `motion(axis: JoyAxis, value: float)` | `InputEventJoypadMotion` | |
| `set_action(action, events: Array[InputEvent], deadzone := 0.5)` | `void` | Writes one action into ProjectSettings (in memory). |
| `remove_action(action)` | `void` | |
| `save()` | `Error` | Persists `project.godot`. |

> Keyboard-zone contract: list each action's keyboard events in **zone order** -
> the Nth keyboard event becomes keyboard zone N.

---

## Persistence and rebinding

### `InputForgeBindingsStore`

Persists profile overrides to `user://input_bindings.cfg` via `ConfigFile`
(static). Joypad sections are keyed by SDL GUID; keyboard sections by zone slot.
The keyboard join action is deliberately not persisted.

| Method | Returns |
|--------|---------|
| `section_for(device: InputForgeDeviceId)` | `String` |
| `save_profile(device, profile)` | `Error` |
| `load_profile(device, defaults)` | `InputForgeBindingProfile` |

### `InputForgeRebindCapture` (Node)

While armed, captures the next key / button / axis flick. Listens in `_input()`
(before the join listener), so arm it for interactive rebinding UIs.

Signals: `key_captured(physical_keycode: Key)`,
`button_captured(button_index: JoyButton)`,
`axis_captured(axis: JoyAxis, positive: bool)`.

Methods: `arm(device: InputForgeDeviceId)`, `disarm()`.

---

## Devices

### `InputForgeDeviceId` (RefCounted)

Identifies one logical device: a joypad index, or one keyboard key-zone slot.

`enum Kind { KEYBOARD, JOYPAD }`; `kind`, `index`. Methods: `equals(other)`,
`to_key() -> String` (e.g. `"joy:1"`), `describe() -> String`,
`is_connected_device() -> bool`.

### `InputForgeIconProvider` (RefCounted)

Default, game-agnostic device-prompt provider. Ships no art. Subclass and override
`texture_for()` to inject button-prompt textures.

| Method | Returns | Notes |
|--------|---------|-------|
| `texture_for(device)` | `Texture2D` | Override to return art; `null` = no art. |
| `label_for(device)` | `String` | `"KB0"`, `"P1"`, ... |
| `make_prompt(device)` | `Control` | `TextureRect` when art exists, else a `Label`. |

---

## Lobby

### `InputForgeJoinListener` (Node)

"Press to join / leave / ready" handler. Set `action_set` before `add_child()`.

Signals: `join_requested(device, profile)`, `leave_requested(device)`,
`device_lost(device)`, `claimed_join_pressed(device)`.

Key members: `action_set`, `keyboard_profiles`, `joypad_default_profile`.
Methods: `claimed() -> Array[InputForgeDeviceId]`, `is_claimed(device)`,
`release_all()`, `claim_existing(device)`, `release_claim(device)`.

---

## Sources and commands

### `InputForgeSource` (Node)

Base class. `poll() -> InputForgeCommand`, called once per physics tick.

### `InputForgeDeviceSource` (InputForgeSource)

Polls ONE device into a command. `_init(device, profile, action_set)`.
Computes press edges from previous-tick held state - poll exactly once per tick.
`describe() -> String` returns the device label.

### `InputForgeLocalSource` (InputForgeSource)

Reads the shared action map (single-local-player / testing). `_init(action_set)`.

### `InputForgeNetworkSource` (InputForgeSource)

Server-side source fed by the codec. `apply(move: Vector2, held_mask: int,
counters: PackedByteArray)` ingests a packet; `poll()` drains at most one press per
button per tick. `MAX_PENDING = 4`. Self-baselining (first packet adopts the
counter baseline without emitting a press). Use an ordered channel
(`unreliable_ordered`).

### `InputForgeCommand` (RefCounted)

Abstract per-tick intent. `_init(action_set := null)`. Members: `action_set`,
`move: Vector2`, `pressed_mask: int`, `held_mask: int`. Methods:
`is_pressed(action) -> bool`, `is_held(action) -> bool`,
`set_button(index, pressed, held)`.

### `InputForgeSlot` (RefCounted)

Optional logical-player-slot helper. `_init(slot_id := 0, peer_id := 1)`.
Members: `slot_id`, `peer_id`, `input_source: InputForgeSource`.
