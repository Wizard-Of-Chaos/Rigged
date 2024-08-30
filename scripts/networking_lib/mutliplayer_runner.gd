extends Node

const SECONDS_PER_FRAME := 0.05
const MAX_PACKET_SIZE := 1024
var packet: GameUpdatePacket
var accumulator := 0.0
var listen_socket := 0
var host_connection := 0
var connected_clients: Array[int] = []


func _ready() -> void:
	packet = GameUpdatePacket.new()
	Steam.network_connection_status_changed.connect(_on_network_connection_status_changed)


func _process(delta: float) -> void:
	accumulator += delta
	if accumulator >= SECONDS_PER_FRAME:
		network_frame()


func is_host() -> bool:
	return listen_socket != 0


func is_networked() -> bool:
	return host_connection != 0 or listen_socket != 0

func network_frame() -> void:
	var offset = 0
	# TODO: prio accumulator stuff
	for node: Node in get_tree().get_nodes_in_group("serializable"):
		assert(node.has("serializer") and node.serializer is Serializable)
		var serializer: Serializable = node.serializer
		if offset + serializer.serialized_size() > MAX_PACKET_SIZE:
			break
		offset += serializer.serialize(node, packet.data, offset)
	
	SteamLobbyGlobal.send_p2p_packet(0, packet, Steam.P2P_SEND_UNRELIABLE_NO_DELAY)


func open_listener_socket(p_port: int = 0, p_options: Array = []) -> void:
	listen_socket = Steam.createListenSocketP2P(p_port, p_options)


func close_host() -> void:
	for connected_client in connected_clients:
		Steam.closeConnection(connected_client, 0, "Host closed", false)
	Steam.closeListenSocket(listen_socket)


func connect_to_host(p_host_steam_id: int) -> void:
	Steam.connectP2P(p_host_steam_id, 0, [])


func begin_game() -> void:
	open_listener_socket()
	


func _on_network_connection_status_changed(p_connect_handle: int, p_connect: Dictionary, p_old_state: int) -> void:
	if is_host():
		if p_connect.connection_state == Steam.CONNECTION_STATE_CONNECTING:
			print("client beginning to connect")
			# TODO: some validation perhaps
			var res := Steam.acceptConnection(p_connect_handle)
			if res != Steam.RESULT_OK:
				print("acceptConnection returned %s" % res)
				Steam.closeConnection(p_connect_handle, Steam.CONNECTION_END_APP_GENERIC, "Failed to accept connection", false)
			connected_clients.append(p_connect_handle)
		elif p_connect.connection_state == Steam.CONNECTION_STATE_CLOSED_BY_PEER:
			print("Client is dropping connection for whatever reason")
			connected_clients.remove_at(connected_clients.find(p_connect_handle))
			Steam.closeConnection(p_connect_handle, Steam.CONNECTION_END_APP_EXCEPTION_GENERIC, "User dropped", false)
	else:
		if p_connect.connection_state == Steam.CONNECTION_STATE_CONNECTED:
			print("Succesfully connected to host")
			host_connection = p_connect_handle
			get_tree().change_scene_to_file("res://basic.tscn")
		elif p_connect.connection_state == Steam.CONNECTION_STATE_CLOSED_BY_PEER:
			print("We've been dropped for some reason")
			Steam.closeConnection(p_connect_handle, p_connect.end_reason, p_connect.end_debug, false)
		elif Steam.CONNECTION_STATE_PROBLEM_DETECTED_LOCALLY:
			print("we've had a local problem, possibly timeout?")
			Steam.closeConnection(p_connect_handle, p_connect.end_reason, p_connect.end_debug, false)

class GameUpdatePacket:
	var data: PackedByteArray
	func _init():
		data = PackedByteArray()
		data.resize(MAX_PACKET_SIZE)
