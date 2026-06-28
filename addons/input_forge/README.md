# Input Forge

A Godot **4.7** editor plugin for **multi-device local + online multiplayer input**.

Input Forge turns a shared keyboard (split into key-zones) and any number of
gamepads into abstract, **action-keyed commands**, configured from the project's
regular Godot **InputMap** - no game-specific action names are baked into the
plugin. It provides per-device polling, lobby join/leave, runtime rebinding,
persistence, and a packet-loss-safe command codec for streaming input to an
authoritative server.

Requires **Godot 4.7+**. (Godot's `plugin.cfg` has no engine-version field, so the
4.7 floor is enforced via the Asset Library minimum-version metadata. The plugin
uses the Godot 4.7-native `EditorDock` API; the last 4.6-compatible release is
`0.1.0`.)

## Why it exists

Godot's action API has no `device` parameter, so per-player couch co-op cannot use
the shared action map directly. Input Forge polls each device individually while
still letting you define your controls in the normal Godot Input Map: it *derives*
its per-device binding defaults from those actions.

## Install

1. Copy `addons/input_forge/` into your project's `addons/` folder.
2. Enable **Input Forge** under `Project > Project Settings > Plugins`.

If you keep typed GDScript as errors, also set the Godot 4.7
`debug/gdscript/warnings/directory_rules` so `res://addons` is held to the same
standard (see this repo's `project.godot`).

## Configure via the InputMap

1. Define your actions in `Project > Project Settings > Input Map` as usual
   (e.g. `move_left/right/up/down`, `jump`, `dash`).
2. For multiple keyboard players, bind one key per **zone** to each action: the
   Nth keyboard event of an action becomes keyboard zone N. Example - bind `jump`
   to `Space` (zone 0) and `Enter` (zone 1); `move_left` to `A` (zone 0) and
   `Left` (zone 1).
3. Create an `InputForgeActionSet` resource and fill in which actions are the four
   movement directions, which are buttons (ordered), and which is the join action.
4. Open the **Input Forge** dock (left). Create or assign an action set, pick the
   four movement actions, the join action, and the ordered button actions from
   dropdowns populated by your InputMap, then **Apply + Save**. The dock previews
   the per-device bindings derived from the InputMap. Use **Refresh actions** after
   editing the Input Map to repopulate the dropdowns.

The dock reads `ProjectSettings` `input/*` (the editor-safe source, since
`InputMap.action_get_events()` returns *editor* actions inside a `@tool` context).
At runtime the same derivation reads the live `InputMap` - the two are guaranteed
to agree.

To script the InputMap itself (e.g. a project bootstrap), use the reusable
`InputForgeMapWriter` (`key()` / `button()` / `motion()` / `set_action()` /
`save()`) instead of hand-editing `project.godot`.

## Public API (class_name)

- `InputForgeActionSet` (Resource) - selects/orders the InputMap actions to manage.
- `InputForgeBindingProfile` (Resource) - per-device action->key / action->button map.
- `InputForgeBindingDefaults` - builds default profiles by deriving from the InputMap.
- `InputForgeMapBindings` - the derivation (keyboard zones, joypad buttons/axes).
- `InputForgeBindingsStore` - persists overrides to `user://input_bindings.cfg`.
- `InputForgeRebindCapture` (Node) - captures the next key/button/axis for rebinding.
- `InputForgeJoinListener` (Node) - lobby "press to join / leave / ready" handler.
- `InputForgeDeviceId` - one logical device (a joypad, or one keyboard key-zone).
- `InputForgeSource` (Node) and subclasses:
  - `InputForgeDeviceSource` - polls ONE device into an `InputForgeCommand`.
  - `InputForgeLocalSource` - reads the shared action map (single-player fallback).
  - `InputForgeNetworkSource` - server-side; fed by the command codec over RPC.
- `InputForgeCommand` - the abstract per-tick intent (move + action-indexed
  pressed/held masks); `is_pressed(action)` / `is_held(action)`.
- `InputForgeSlot` - an optional logical-player-slot helper.
- `InputForgeIconProvider` - default device-prompt provider (text labels, no art);
  subclass and override `texture_for()` to inject your own button-prompt art.
- `InputForgeMapWriter` - reusable helper to write the project InputMap from code.

## Minimal usage

```gdscript
# 1. A shared action set (define once).
var actions := InputForgeActionSet.new()
actions.move_left = &"move_left" ; actions.move_right = &"move_right"
actions.move_up = &"move_up" ; actions.move_down = &"move_down"
actions.buttons = [&"jump", &"dash"]
actions.join_action = &"jump"

# 2. Lobby: let devices join.
var listener := InputForgeJoinListener.new()
listener.action_set = actions
add_child(listener)
listener.join_requested.connect(func(device, profile):
    var source := InputForgeDeviceSource.new(device, profile, actions)
    add_child(source)
    # ... attach `source` to a player; call source.poll() each physics tick.
)

# 3. Each physics tick:
var cmd := source.poll()
var move: Vector2 = cmd.move
if cmd.is_pressed(&"jump"): pass # jump edge this tick
if cmd.is_held(&"jump"): pass    # variable jump height
```

## Networking

`InputForgeCommand` is streamed compactly: per slot a move vector, a held bitmask,
and per-button wrapping 8-bit press counters. The server-side
`InputForgeNetworkSource` turns counter deltas back into press edges and drains one
press per button per tick, so an isolated press is never lost to a dropped packet
and rapid presses are preserved up to a small cap (presses beyond the cap inside a
single loss window may coalesce). It is self-baselining - the first packet seeds
the counter baseline without emitting a press - so it does not depend on how the
host creates or resets sources. Use an ordered channel (e.g. `unreliable_ordered`)
so counters never regress. You own the transport (ENet / `@rpc`); the plugin owns
the codec. The reference wire format packs held state as a 32-bit mask, so keep the
action set to at most 32 buttons (see `InputForgeActionSet.MAX_BUTTONS`).

## Device prompts / icons

Input Forge ships **no** button-prompt art (to stay game-agnostic and license-
clean). The default `InputForgeIconProvider` returns short text labels ("KB0",
"P1", ...) and `make_prompt(device)` returns a ready-to-add `Label`, so roster
rows have something to show out of the box. To use your own art, subclass it and
override `texture_for()`; `make_prompt()` then returns a `TextureRect` when art is
available and falls back to the text `Label` otherwise:

```gdscript
class_name MyIcons extends InputForgeIconProvider
func texture_for(device: InputForgeDeviceId) -> Texture2D:
    return my_art_for(device)  # return null to fall back to a text label
```

## License

MIT - see `LICENSE`.
