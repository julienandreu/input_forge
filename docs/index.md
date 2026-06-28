# Input Forge

A Godot **4.7** plugin for **multi-device local + online multiplayer input**.

Input Forge turns a shared keyboard (split into key-zones) and any number of
gamepads into abstract, **action-keyed commands**, configured from the project's
regular Godot **InputMap** - no game-specific action names are baked into the
plugin. It provides per-device polling, lobby join/leave, runtime rebinding,
persistence, and a packet-loss-tolerant command codec for streaming input to an
authoritative server.

!!! warning "Requires Godot 4.7+"
    Input Forge 0.2.0 uses the Godot 4.7-native editor dock API and is held to
    strict, fully typed GDScript. The last Godot 4.6-compatible release is `0.1.0`.

## Why it exists

Godot's action API has no `device` parameter, so per-player couch co-op cannot use
the shared action map directly. Input Forge polls each device individually while
still letting you define your controls in the normal Godot Input Map: it *derives*
its per-device binding defaults from those actions.

## Where to go next

- **[Tutorials](tutorials.md)** - configure the InputMap, use the dock, build
  couch co-op, wire up netcode, rebinding, and device prompts.
- **[API reference](api-reference.md)** - every public `class_name` type.
- **[Examples](https://github.com/julienandreu/input_forge/tree/main/examples)** -
  runnable couch-co-op and netcode scenes.
- **[Contributing](https://github.com/julienandreu/input_forge/blob/main/CONTRIBUTING.md)** -
  dev workflow and the typing contract.

## Install

1. Copy `addons/input_forge/` into your project's `addons/` folder.
2. Enable **Input Forge** under `Project > Project Settings > Plugins`.

See the
[addon README](https://github.com/julienandreu/input_forge/blob/main/addons/input_forge/README.md)
for the full setup and the
[CHANGELOG](https://github.com/julienandreu/input_forge/blob/main/CHANGELOG.md)
for release notes.
