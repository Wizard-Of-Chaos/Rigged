extends Node

const SECONDS_PER_FRAME := 0.05
const MAX_PACKET_SIZE := 1024
var packet: GameUpdatePacket
var accumulator := 0.0


func _ready() -> void:
	packet = GameUpdatePacket.new()

func _process(delta: float) -> void:
	accumulator += delta
	if accumulator >= SECONDS_PER_FRAME:
		network_frame()

func network_frame() -> void:
	var offset = 0
	# TODO: prio accumulator stuff
	for node: Node in get_tree().get_nodes_in_group("serializable"):
		assert(node.has("serializer"))
		var serializer: Serializable = node.serializer
		if offset + serializer.serialized_size() > MAX_PACKET_SIZE:
			break
		offset += serializer.serialize(node, packet.data, offset)
	
	
	

class GameUpdatePacket:
	var data: PackedByteArray
	func _init():
		data = PackedByteArray()
		data.resize(MAX_PACKET_SIZE)
