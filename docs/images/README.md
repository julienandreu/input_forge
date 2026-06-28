# Documentation images

Screenshots referenced by the docs, captured from the running Godot 4.7 editor.

- **`dock.png`** - the Input Forge dock (empty state): action-set picker, the four
  movement / join dropdowns, button-actions list, and Apply + Save.
- **`dock-preview.png`** - the dock with an `InputForgeActionSet` assigned: filled
  dropdowns plus the derived per-device bindings preview ("Keyboard zones derived
  from InputMap").

Both are real captures of the dock. To re-capture after UI changes, open this repo
in Godot 4.7 with the plugin enabled, front the **Input Forge** dock, and grab the
panel (assign an action set first for the preview shot).

Optional, still welcome:

- **`couch-coop.png` / `couch-coop.gif`** - the `examples/couch_coop` scene
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
