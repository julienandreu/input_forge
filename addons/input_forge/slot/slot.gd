class_name InputForgeSlot
extends RefCounted
## A logical player, decoupled from its input device AND its network peer, so
## local and remote players are interchangeable. Local slots carry a
## InputForgeLocalSource; networked slots (later) carry a source fed by replicated
## commands. `peer_id` is the owning multiplayer peer (1 = server/local for now).

var slot_id: int = 0
var peer_id: int = 1
var input_source: InputForgeSource = null


func _init(p_slot_id: int = 0, p_peer_id: int = 1) -> void:
	slot_id = p_slot_id
	peer_id = p_peer_id
