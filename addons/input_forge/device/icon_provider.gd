class_name InputForgeIconProvider
extends RefCounted
## Default, game-agnostic device-prompt provider. Input Forge ships NO button-prompt
## art (to stay license-clean and small): texture_for() returns null and
## label_for() returns a short text label, so a roster row always has SOMETHING to
## show out of the box.
##
## Games with their own prompt art subclass this and override texture_for() (and
## optionally label_for()). make_prompt() then returns a TextureRect when art is
## available and falls back to a text Label otherwise - so UI code can be written
## once against the provider and work with or without art.


## Override in a subclass to return button-prompt art for a device; null = no art.
func texture_for(_device: InputForgeDeviceId) -> Texture2D:
	return null


## Short text label for a device, used when there is no art. Keyboard zones read
## "KB0", "KB1", ...; joypads read "P1", "P2", ... (1-based for players).
func label_for(device: InputForgeDeviceId) -> String:
	if device == null:
		return "?"
	if device.kind == InputForgeDeviceId.Kind.KEYBOARD:
		return "KB%d" % device.index
	return "P%d" % (device.index + 1)


## A ready-to-add prompt Control: a TextureRect when texture_for() returns art,
## otherwise a Label with label_for() text. The caller owns the returned node.
func make_prompt(device: InputForgeDeviceId) -> Control:
	var texture: Texture2D = texture_for(device)
	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP
		return rect
	var label := Label.new()
	label.text = label_for(device)
	return label
