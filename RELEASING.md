# Releasing Input Forge

Maintainer checklist for cutting a release. Input Forge follows
[Semantic Versioning](https://semver.org/) (pre-1.0: breaking changes may land in
minor versions and are labelled **BREAKING** in the `CHANGELOG`).

## 1. Pre-flight (on `main`, with Godot 4.7)

```bash
export GODOT="/path/to/Godot"     # Godot 4.7
./check.sh                                                        # strict typing gate
"$GODOT" --headless --path . --script res://test/network_codec.gd # codec test -> NETWORK CODEC PASSED
```

- [ ] `check.sh` passes; codec test prints `NETWORK CODEC PASSED`.
- [ ] `addons/input_forge/plugin.cfg` `version` matches the release.
- [ ] `CHANGELOG.md` has a dated entry for the version (move items out of
      `[Unreleased]`); breaking changes are labelled.
- [ ] Real screenshots added under `docs/images/` (replace the placeholders).

## 2. Tag and GitHub release

```bash
git tag -a v0.2.0 -m "Input Forge 0.2.0"
git push origin v0.2.0
gh release create v0.2.0 --title "Input Forge 0.2.0" --notes-file <(sed -n '/## \[0.2.0\]/,/## \[0.1.0\]/p' CHANGELOG.md)
```

The `Docs` workflow publishes the site to GitHub Pages on push to `main`. Enable
Pages once in **repo Settings > Pages > Build and deployment > Source: GitHub
Actions** (one-time, repo-admin).

## 3. Godot Asset Library submission

`plugin.cfg` has no engine-version field, so the **4.7 floor is enforced by the
Asset Library entry**. On <https://godotengine.org/asset-library> (Submit / Edit
asset), use:

| Field | Value |
|-------|-------|
| Title | Input Forge |
| Category | 2D Tools (or Scripts) |
| Godot version | **4.7** (this is the minimum/required version) |
| Version string | 0.2.0 |
| License | MIT |
| Repository host | GitHub |
| Repository URL | https://github.com/julienandreu/input_forge |
| Commit / download | the `v0.2.0` tag commit |
| Icon | `addons/input_forge/icon.svg` |
| Description | from the addon README intro |

> Because 0.2.0 drops Godot 4.6, set the Asset Library **Godot version to 4.7** so
> 4.6 users are not offered an incompatible update. The last 4.6-compatible release
> remains available at the `v0.1.0` tag.
