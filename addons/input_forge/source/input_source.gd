class_name InputForgeSource
extends Node
## The seam between input and behaviour. Produces a InputForgeCommand each tick.
## Subclasses: InputForgeLocalSource (reads a device) and, later, a network source
## that applies replicated commands. A Player consumes whatever InputForgeSource it is
## given, so local and remote players share identical behaviour code.

func poll() -> InputForgeCommand:
	return InputForgeCommand.new()
