@tool
extends EditorPlugin
## Input Forge editor plugin entry point.
##
## Editor integration (Godot 4.7):
##   - Public classes carry `class_name` (so they appear in the Create dialog
##     automatically) plus an `@icon` annotation for a recognisable icon. We do
##     NOT call add_custom_type() - that conflicts with already-registered
##     class_names.
##   - A preview dock (editor/dock.gd) shows the per-device bindings derived from
##     the project's Godot InputMap for a chosen InputForgeActionSet. It is hosted
##     in an `EditorDock` (the Godot 4.7-native dock API) registered via
##     `add_dock()` / `remove_dock()`, which gives the panel a titled, icon-bearing
##     dock the user can move and float.

const DOCK_SCRIPT: GDScript = preload("res://addons/input_forge/editor/dock.gd")
const DOCK_ICON: Texture2D = preload("res://addons/input_forge/icon.svg")

var _dock: EditorDock = null


func _enter_tree() -> void:
	# GDScript.new() is typed Variant; the dock script always extends Control, so
	# this single, local narrowing is safe. Quarantined behind a localized ignore
	# (the only such site outside tool/typed_cast.gd).
	@warning_ignore("unsafe_cast")
	var panel: Control = DOCK_SCRIPT.new() as Control
	_dock = EditorDock.new()
	_dock.title = "Input Forge"
	_dock.dock_icon = DOCK_ICON
	_dock.default_slot = EditorDock.DOCK_SLOT_LEFT_UR
	_dock.add_child(panel)
	add_dock(_dock)


func _exit_tree() -> void:
	if _dock != null:
		remove_dock(_dock)
		_dock.free()
		_dock = null
