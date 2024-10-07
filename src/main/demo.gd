extends Node

@onready var server_connection : Node = $ServerConnection
@onready var debug_panel : Panel = $CanvasLayer/DebugPanel

func _ready() -> void:	
	Events.login_to_server.connect(handle_login_to_server)
	
func handle_login_to_server(email : String, password : String, need_create : bool) -> void:
	
	Events.show_login_error.emit("Auth user %s" % email)

	var result : int = await  server_connection.auth_async(email, password, need_create)
	
	if result == OK:
		Events.show_login_error.emit("Auth user %s success" % email)
	else:
		Events.show_login_error.emit("Could not auth user %s" % email)
