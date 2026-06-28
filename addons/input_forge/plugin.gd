@tool
extends EditorPlugin
## Input Forge editor plugin entry point.
##
## Editor integration:
##   - Public classes carry `class_name` (so they appear in the Create dialog
##     automatically) plus an `@icon` annotation for a recognisable icon. We do
##     NOT call add_custom_type() - that conflicts with already-registered
##     class_names.
##   - A preview dock (editor/dock.gd) shows the per-device bindings derived from
##     the project's Godot InputMap for a chosen InputForgeActionSet.

const DOCK_SCRIPT: GDScript = preload("res://addons/input_forge/editor/dock.gd")

var _dock: Control = null


func _enter_tree() -> void:
	_dock = DOCK_SCRIPT.new() as Control
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, _dock)


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.free()
		_dock = null
