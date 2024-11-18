extends Node

signal chat_message_received(username, text)
signal user_joined(username)
signal user_left(username)

enum ReadPermissions {
	NO_READ,
	OWNER_READ,
	PUBLIC_READ
}

enum WritePermissions {
	NO_WRITE,
	OWNER_WRITE
}

const KEY : String = "defaultkey"

var _session: NakamaSession
var _client : NakamaClient = Nakama.create_client(KEY, "127.0.0.1", 7350, "http")

var _socket : NakamaSocket
var _world_id : String = ""
var _channel_id : String = ""
var _presences : Dictionary = {}

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

func _on_NakamaSocked_channel_message(message : NakamaAPI.ApiChannelMessage) -> void:
	if message.code != 0:
		return
	var content : Dictionary = JSON.parse_string(message.content)
	emit_signal("chat_message_received", message.username, content.msg)
	
func _on_NakamaSocked_match_presence(new_presence : NakamaRTAPI.MatchPresenceEvent) -> void:
	for user_leave in new_presence.leaves:
		_presences.erase(user_leave.user_id)
		emit_signal("user_leaved", user_leave.username)
		
	for user_join in new_presence.joins:
		_presences[user_join.user_id] = user_join
		emit_signal("user_joined", user_join.username)
	
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
		
func join_chat_async() -> int:
	var chat_join_result : NakamaRTAPI.Channel = await _socket.join_chat_async("world", NakamaSocket.ChannelType.Room, false, false)
	if not chat_join_result.is_exception():
		_channel_id = chat_join_result.id
		return OK
	else:
		return ERR_CONNECTION_ERROR
		
func send_text_async(text : String) -> int:
	var send_text_result : NakamaRTAPI.ChannelMessageAck = await _socket.write_chat_message_async(_channel_id, {"msg" : text})
	
	return ERR_CONNECTION_ERROR if send_text_result.is_exception() else OK

func write_characters_async(characters : Array = []) -> void:
	await _client.write_storage_objects_async(
		_session,
		[
			NakamaWriteStorageObject.new(
				"player_data",
				"characters",
				ReadPermissions.OWNER_READ,
				WritePermissions.OWNER_WRITE,
				JSON.stringify({characters = characters}),
				""
			)
		]
	)
	
func get_characters_async() -> Array:
	var storage_object : NakamaAPI.ApiStorageObjects = await _client.read_storage_objects_async(
		_session, 
		[
			NakamaStorageObjectId.new(
				"player_data",
				"characters",
				_session.user_id
			)
		]
	)
	
	if storage_object.objects:
		var decoded : Array = JSON.parse_string(storage_object.objects[0].value).result.characters
		return decoded
			
	return []
	
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
