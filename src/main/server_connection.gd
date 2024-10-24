extends Node

const KEY : String = "defaultkey"

var _session: NakamaSession
var _client : NakamaClient = Nakama.create_client(KEY, "127.0.0.1", 7350, "http")

var _socket : NakamaSocket
var _world_id : String
var _presences : Dictionary

func auth_async(email : String, password : String, need_create : bool) -> int:
	var result : int = OK
	
	var token = SessionFile.read_auth(email, password)
	if token != "":
		var new_session : NakamaSession = await _client.restore_session(token)
		if new_session.valid and not new_session.expired:
			_session = new_session
			return result
	
	var new_session : NakamaSession = await _client.authenticate_email_async(email, password, null, need_create)
	if not new_session.is_exception():
		_session = new_session
		SessionFile.write_auth(email, _session.token, password)
	else:
		result = new_session.get_exception().status_code
	
	return result
	
func connect_to_server_async() -> int:
	_socket = Nakama.create_socket_from(_client)
	var result : NakamaAsyncResult = await _socket.connect_async(_session)
	if not result.is_exception():
		_socket.closed.connect(_on_NakamaSocked_closed)
		_socket.connected.connect(_on_NakamaSocked_connected)
		_socket.received_channel_message.connect(_on_NakamaSocked_channel_message)
		_socket.received_match_presence.connect(_on_NakamaSocked_match_presence)
		_socket.received_match_state.connect(_on_NakamaSocked_match_state)
		return OK
	return ERR_CANT_CONNECT
	
	
func _on_NakamaSocked_closed() -> void:
	_socket = null
	
func _on_NakamaSocked_connected() -> void:
	pass
	
func _on_NakamaSocked_error(error: String) -> void:
	_socket = null

func _on_NakamaSocked_channel_message() -> void:
	pass
	
func _on_NakamaSocked_match_presence(new_presence : NakamaRTAPI.MatchPresenceEvent) -> void:
	for leave in new_presence.leaves:
		_presences.erase(leave.user_id)
		
	for join in new_presence.joins:
		if not join.user_id == get_user_id():
			_presences[join.user_id] = join
			
	emit_signal("presences_changed")
	
func _on_NakamaSocked_match_state() -> void:
	pass
	
func get_user_id() -> int:
	return -1
	
func join_world_async() -> Dictionary:
	var world: NakamaAPI.ApiRpc = await _client.rpc_async(_session, "get_world_id", "")
	
	if not world.is_exception():
		_world_id = world.payload
	
	var match_join_result : NakamaRTAPI.Match = await _socket.join_match_async(_world_id)
	if match_join_result.is_exception():
		var exeption : NakamaException = match_join_result.get_exception()
		printerr("Error joining the match: %s - %s" % [exeption.status_code, exeption.message])
		return {}
	
	for presence in match_join_result.presences:
		_presences[presence.user_id] = presence
		
	return _presences
		
		
# ********************************************
class SessionFile:
	const AUTH : String = "res://auth"
	
	static func write_auth(email: String, token: String, password: String) -> void:
		var file := FileAccess.open_encrypted_with_pass(AUTH, FileAccess.WRITE, password)
		
		if file != null:
			file.store_line(email)
			file.store_line(token)
			file.close()
	
	static func read_auth(email: String, password: String) -> String:
		var file := FileAccess.open_encrypted_with_pass(AUTH, FileAccess.READ, password)
		
		if file != null:
			var auth_email : String = file.get_line()
			var auth_token : String = file.get_line()
			file.close()
			
			if auth_email == email:
				return auth_token
				
		return ""
