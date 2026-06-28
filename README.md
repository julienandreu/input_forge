# Input Forge

A Godot **4.6** plugin for **multi-device local + online multiplayer input**.

Input Forge turns a shared keyboard (split into key-zones) and any number of
gamepads into abstract, **action-keyed commands**, configured from the project's
regular Godot **InputMap** - no game-specific action names are baked into the
plugin. It provides per-device polling, lobby join/leave, runtime rebinding,
persistence, and a packet-loss-tolerant command codec for streaming input to an
authoritative server.

The plugin itself lives in [`addons/input_forge/`](addons/input_forge). This
repository is a tiny dev project that exists only to develop and test the addon
in isolation; consumers just copy the addon folder into their game.

## Why it exists

Godot's action API has no `device` parameter, so per-player couch co-op cannot use
the shared action map directly. Input Forge polls each device individually while
still letting you define your controls in the normal Godot Input Map: it *derives*
its per-device binding defaults from those actions.

## Install

Requires **Godot 4.6.x**.

- **Manual:** copy the `addons/input_forge/` folder into your project's `addons/`
  folder, then enable **Input Forge** under `Project > Project Settings > Plugins`.
- **Asset Library:** install, then enable the plugin.

If your project treats GDScript warnings as errors, set
`debug/gdscript/warnings/exclude_addons=false` (and, on Godot 4.7+,
`directory_rules`) so the addon is held to the same standard.

## Quick start

1. Define your controls in `Project > Project Settings > Input Map` as usual
   (e.g. `move_left/right/up/down`, `jump`, `dash`).
2. For multiple keyboard players, bind one key per **zone** to each action - the
   Nth keyboard event of an action becomes keyboard zone N (e.g. `jump` = `Space`
   for zone 0 and `Enter` for zone 1).
3. Open the **Input Forge** dock, create an `InputForgeActionSet`, pick the four
   movement actions, the ordered button actions, and the join action from the
   dropdowns (populated from your InputMap), then **Apply + Save**. The dock
   previews the per-device bindings Input Forge derives.
4. In code:

```gdscript
var actions := InputForgeActionSet.new()
actions.move_left = &"move_left" ; actions.move_right = &"move_right"
actions.move_up = &"move_up" ; actions.move_down = &"move_down"
actions.buttons = [&"jump", &"dash"]
actions.join_action = &"jump"

var listener := InputForgeJoinListener.new()
listener.action_set = actions
add_child(listener)
listener.join_requested.connect(func(device, profile):
    var source := InputForgeDeviceSource.new(device, profile, actions)
    add_child(source)
    # Attach `source` to a player; call source.poll() once per physics tick:
    #   var cmd := source.poll()
    #   var move: Vector2 = cmd.move
    #   if cmd.is_pressed(&"jump"): ...
)
```

See [`addons/input_forge/README.md`](addons/input_forge/README.md) for the full
API, the network codec details, and the device-prompt provider.

## Develop / test this repo

The addon is kept to strict, typed GDScript. With Godot 4.6.x on your PATH (or set
`$GODOT`):

```bash
./check.sh                                                   # parse + strict typing
godot --headless --path . --script res://test/network_codec.gd   # codec unit test
```

`check.sh` type-checks every addon script (the `exclude_addons=false` /
`directory_rules` settings make untyped declarations hard errors).

## License

MIT - see [`LICENSE`](LICENSE).
