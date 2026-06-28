# Documentation images

Screenshots referenced by the docs. These must be captured from the running Godot
4.7 editor (they can't be generated headlessly). Neutral gray **placeholder**
PNGs (`dock.png`, `dock-preview.png`) are committed so the site builds; replace
them with real captures. The alt text describes what each image should show.

## To capture

Open this repo in Godot 4.7 with the Input Forge plugin enabled, then capture:

1. **`dock.png`** - the Input Forge dock open in the editor (left, upper-right
   slot), showing the action-set picker and the four movement / join / buttons
   dropdowns. Capture just the dock panel (plus a little surrounding editor for
   context).

2. **`dock-preview.png`** - the dock after assigning an `InputForgeActionSet` and
   clicking **Apply + Save**, with the derived per-device bindings preview visible
   in the output area (keyboard zones + joypad buttons listed).

Optional but nice:

3. **`couch-coop.png` / `couch-coop.gif`** - the `examples/couch_coop` scene
   running with two or more squares joined and moving.

## Social preview

`social-preview.png` (1280x640) is the GitHub Open Graph / social card image (the
preview shown when the repo link is shared). GitHub has no API for this, so upload
it once via the web UI: **repo Settings > General > Social preview > Edit > Upload
an image**.

## Conventions

- PNG, trimmed to the relevant UI, reasonable width (<= ~1600px).
- Use the default editor theme for consistency.
- Keep file sizes modest (optimize PNGs); GIFs short (<= ~5s, looping).
