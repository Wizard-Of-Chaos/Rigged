extends Node


signal lobby_list_fetched
signal lobby_members_fetched
signal lobby_created
signal lobby_joined

const LOBBY_CMDLINE_ARG := "+connect_lobby"
var lobby_id: int
var lobby_members: Array = []
var lobbies: Array = []


class LobbyInfo:
	var num_members: int
	var lobby_id: int
	# TODO: more info about our lobby
	func _init(p_num_members: int, p_lobby_id: int) -> void:
		self.num_members = p_num_members
		self.lobby_id = p_lobby_id

func _ready() -> void:
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func check_command_line() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	var connect_lobby_idx := args.find(LOBBY_CMDLINE_ARG)
	if connect_lobby_idx < 0:
		return
	var cmdline_lobby_id := 0
	if args.size() > connect_lobby_idx + 2 and args[connect_lobby_idx].is_valid_int():
		cmdline_lobby_id = int(args[connect_lobby_idx])

	if cmdline_lobby_id == 0:
		return
	
	print("Command line lobby ID: %s" % cmdline_lobby_id)
	join_lobby(cmdline_lobby_id)

func create_lobby(p_lobby_type: Steam.LobbyType, p_max_members: int) -> void:
	# you're already in a lobby numbnuts
	if lobby_id != 0:
		return
	Steam.createLobby(p_lobby_type, p_max_members)


func join_lobby(p_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % p_lobby_id)
	
	Steam.joinLobby(p_lobby_id)


func get_lobby_members() -> void:
	lobby_members.clear()
	var num_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for member in range(0, num_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
	
	lobby_members_fetched.emit()



func leave_lobby() -> void:
	# you're not in a lobby numbnuts
	if lobby_id == 0:
		return
	Steam.leaveLobby(lobby_id)
	lobby_id = 0
	
	for member in lobby_members:
		if member['steam_id'] != SteamGlobal.steam_id:
			Steam.closeP2PSessionWithUser(member['steam_id'])

	lobby_members.clear()
	
	
func get_lobby_list_info() -> Array[LobbyInfo]:
	var res: Array[LobbyInfo] = []
	for lobby in lobbies:
		var lobby_info := LobbyInfo.new(Steam.getNumLobbyMembers(lobby), lobby)
		res.append(lobby_info)
	
	return res


func fetch_lobbies() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	print("fetching lobbies")
	Steam.requestLobbyList()

func _on_lobby_created(p_connect: int, p_lobby_id: int) -> void:
	if p_connect != 1:
		print("lobby failed to create? %s" % p_connect)
		return
	lobby_id = p_lobby_id
	print("Succesfully created a lobby: %s" % lobby_id)
	Steam.setLobbyJoinable(lobby_id, true)
	var set_relay: bool = Steam.allowP2PPacketRelay(true)
	print("Allowing Steam to be relay backup: %s" % set_relay)
	lobby_created.emit()

 
func _on_lobby_join_requested(p_lobby_id: int, p_friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(p_friend_id)
	print("Joining %s's lobby..." % owner_name)
	
	join_lobby(p_lobby_id)
 

func _on_lobby_joined(p_lobby_id: int, _permissions: int, _locked: bool, p_response: int) -> void:
	if p_response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var fail_reason: String
		match p_response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
		print("Failed to join lobby: %s" % fail_reason)
		return
	lobby_id = p_lobby_id
	lobby_joined.emit()
	get_lobby_members()


func _on_persona_change(p_steam_id: int, _flag: int) -> void:
	if lobby_id == 0:
		return
	print("A user (%s) had information change, updating the lobby list" % p_steam_id)
	get_lobby_members()


func _on_lobby_chat_update(p_lobby_id: int, p_change_id: int, p_making_change_id: int, p_chat_state: int) -> void:
	if p_lobby_id != lobby_id:
		print("bwuh, lobby chat update from %s which is not the lobby we're in (%s)" % [p_lobby_id, lobby_id])
	var changer_name: String = Steam.getFriendPersonaName(p_change_id)
	var output: String
	
	match p_chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED: output = "%s has joined the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT: output = "%s has left the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED: output = "%s has been kicked from the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED: output = "%s has been banned from the lobby." % changer_name
		_: output = "%s did something??" % changer_name
	
	print(output)
	
	get_lobby_members()


func _on_lobby_match_list(p_lobbies: Array) -> void:
	lobbies.clear()
	lobbies.append_array(p_lobbies)
	
	lobby_list_fetched.emit()
