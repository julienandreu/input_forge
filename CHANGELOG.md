# Changelog

All notable changes to Input Forge are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
While the project is pre-1.0, breaking changes may land in minor versions and are
labelled **BREAKING** below.

## [Unreleased]

## [0.2.0] - 2026-06-28

### Breaking

- **Dropped Godot 4.6 support; Input Forge now requires Godot 4.7+.** There is no
  runtime engine-version compatibility branch, so dropping the addon into a
  pre-4.7 project will fail to parse. The last Godot 4.6-compatible release is
  [`0.1.0`](#010---2026-01-01). When installing from the Asset Library, the
  minimum Godot version metadata is set to 4.7.

### Changed

- **Editor dock migrated to the Godot 4.7-native `EditorDock` API.** The dock is
  now registered with `add_dock()` / `remove_dock()` (instead of the older
  `add_control_to_dock()` / `remove_control_from_docks()`), and gains a proper
  dock title ("Input Forge") and icon that the user can move, float, and dock.
- **Strict typing hardened.** The `unsafe_cast`, `unsafe_method_access`,
  `unsafe_property_access`, and `unsafe_call_argument` GDScript warnings are now
  treated as **errors** (previously warnings). The whole addon passes under this
  stricter gate.
- `project.godot` retargeted to Godot 4.7 (`config/features` and the
  `directory_rules` warning gate; the 4.6-only `exclude_addons` key was removed).
- `check.sh` and project metadata updated to reference Godot 4.7.
- `plugin.cfg` version bumped to `0.2.0`.

### Added

- **`addons/input_forge/tool/typed_cast.gd`** - an internal, audited helper that
  quarantines the unavoidable `Variant` -> concrete-type narrowing forced by
  Godot's data-driven APIs (`ConfigFile.get_value`, `ProjectSettings.get_setting`,
  untyped `Dictionary`/`Array` iteration, `InputEvent` polymorphism). Each
  narrowing lives behind a single, documented `@warning_ignore`. See
  `CONTRIBUTING.md` for the full typing contract.
- Documentation set: this `CHANGELOG.md`, a `CONTRIBUTING.md` (dev workflow +
  typing contract), a curated API reference (`docs/api-reference.md`), worked
  example scenes under `examples/`, and a documentation site (mkdocs-material,
  with a GitHub Pages deploy workflow).

### Fixed

- Replaced four `.get()`-on-typed-`Dictionary` lookups (which return `Variant`)
  with statically typed dictionary indexing in `InputForgeActionSet`,
  `InputForgeBindingProfile`, and `InputForgeJoinListener` - removing avoidable
  `Variant` narrowing entirely rather than suppressing it.

## [0.1.0] - 2026-01-01

### Added

- Initial release (Godot 4.6). Multi-device local + online multiplayer input:
  keyboard key-zones and multiple gamepads driving abstract, action-keyed
  commands configured from the project's Godot InputMap; per-device polling,
  lobby join/leave, runtime rebinding, persistence, and a packet-loss-safe
  command codec.
- **This is the last Godot 4.6-compatible release.**

[Unreleased]: https://github.com/julienandreu/input_forge/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/julienandreu/input_forge/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/julienandreu/input_forge/releases/tag/v0.1.0
