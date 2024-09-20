extends Node

const KEY : String = "defaultkey"

var _session: NakamaSession
var _client : NakamaClient = Nakama.create_client(KEY, "127.0.0.1", 7350, "http")


func auth_async(email : String, password : String) -> int:
	var result : int = OK
	
	var new_session : NakamaSession = await _client.authenticate_email_async(email, password, null, true)
	
	if not new_session.is_exception():
		_session = new_session
	else:
		result = new_session.get_exception().status_code
	
	return result
