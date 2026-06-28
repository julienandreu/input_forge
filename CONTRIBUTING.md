# Contributing to Input Forge

Thanks for helping improve Input Forge. This document covers the dev workflow and
the project's typing contract.

## Requirements

- **Godot 4.7+** (the addon uses 4.7-native APIs; see the README).
- Optional: `gdtoolkit` (`gdformat` / `gdlint`) for formatting and linting.

## Repository layout

```
addons/input_forge/      the shipped addon (this is what consumers copy)
  plugin.gd              EditorPlugin entry point (registers the EditorDock)
  editor/dock.gd         the preview dock UI
  binding/               action sets, profiles, defaults, derivation, persistence
  source/               per-device polling, command model, network codec
  lobby/                 join/leave listener
  device/               device identity + prompt/icon provider
  slot/                  logical player-slot helper
  tool/                  reusable helpers (InputMap writer, typed_cast)
examples/                runnable example scenes (NOT part of the addon)
test/                    headless tests
docs/                    curated documentation (also published as a site)
check.sh                 strict parse + typing gate
```

## Dev workflow

With Godot 4.7 on your `PATH`, or with `$GODOT` pointing at the binary:

```bash
export GODOT="/path/to/Godot"            # e.g. .../Godot.app/Contents/MacOS/Godot
./check.sh                                # parse + strict typing on every .gd
"$GODOT" --headless --path . --script res://test/network_codec.gd   # codec unit test
```

`check.sh` is the authoritative gate. Godot's `--check-only` exit code is
unreliable, so the script log-scans for `SCRIPT ERROR` / `Parse Error` text. With
the strict warning settings below, untyped or unsafe code prints
"Warning treated as error" and fails the gate.

> Note: the codec test prints "ObjectDB instances were leaked at exit" - this is
> benign SceneTree-teardown noise from the standalone test harness (objects are
> created for assertions and not explicitly freed before the tree quits). It does
> not affect the pass/fail result.

## Typing contract

Input Forge is **fully statically typed**. `project.godot` enforces:

```
gdscript/warnings/directory_rules = { "res://addons": 1 }   # gate res://addons
gdscript/warnings/untyped_declaration   = 2   # error
gdscript/warnings/unsafe_property_access = 2   # error
gdscript/warnings/unsafe_method_access   = 2   # error
gdscript/warnings/unsafe_cast            = 2   # error
gdscript/warnings/unsafe_call_argument   = 2   # error
```

Every variable, parameter, and return type must be typed, and every `Variant`
narrowing must be statically safe. Two rules keep this honest:

1. **Avoid the narrowing if you can.** Godot's typed containers
   (`Array[T]`, `Dictionary[K, V]`) preserve element types, so index them
   directly instead of `.get()` (whose return is always `Variant`):

   ```gdscript
   # avoid:  return int(dict.get(key, -1))          # Variant -> unsafe
   # prefer: return dict[key] if dict.has(key) else -1   # statically typed
   ```

2. **Quarantine the unavoidable narrowing.** Godot's data-driven APIs return
   `Variant` by design (`ConfigFile.get_value`, `ProjectSettings.get_setting`,
   untyped `Dictionary`/`Array` iteration, `InputEvent` polymorphism,
   `Object.new()`). These narrowings are isolated in one audited place,
   `addons/input_forge/tool/typed_cast.gd`, each behind a single documented
   `@warning_ignore`. Call sites stay clean.

### Residual `@warning_ignore` inventory

The ONLY suppressed unsafe operations in the addon (each justified by a
Godot-API that returns `Variant`):

| Site | Warning | Why it is unavoidable |
|------|---------|-----------------------|
| `tool/typed_cast.gd` `to_int()` | `unsafe_call_argument` | `int(Variant)` from `ConfigFile`/`Dictionary` numeric lookups |
| `tool/typed_cast.gd` `to_float()` | `unsafe_call_argument` | `float(Variant)` from `ConfigFile` deadzone |
| `tool/typed_cast.gd` `to_str()` | `unsafe_call_argument` | `String(Variant)` from `Variant` dictionary keys |
| `tool/typed_cast.gd` `to_string_name()` | `unsafe_cast` | `Variant as StringName` for untyped dictionary keys |
| `tool/typed_cast.gd` `to_dictionary()` | `unsafe_cast` | `ProjectSettings.get_setting()` returns `Variant` |
| `tool/typed_cast.gd` `to_array()` | `unsafe_cast` | the `events` array inside a ProjectSettings action entry |
| `tool/typed_cast.gd` `to_input_event()` | `unsafe_cast` | polymorphic events pulled from an untyped `Array` |
| `plugin.gd` `_enter_tree()` | `unsafe_cast` | `GDScript.new()` is typed `Variant`; the dock script always extends `Control` |

If you add a new `@warning_ignore`, it must be a genuinely unavoidable Godot-API
narrowing, it must be localized to a single statement with a comment, and it must
be added to this table. Prefer extending `typed_cast.gd` over scattering ignores.

## Pull requests

- Keep `check.sh` green and the codec test passing.
- Match the existing doc-comment style (`##` on public classes and members).
- Update `CHANGELOG.md` under `[Unreleased]`.
- Examples go under `examples/`, never inside `addons/`.

## License

By contributing you agree your contributions are licensed under the MIT License
(see `LICENSE`).
