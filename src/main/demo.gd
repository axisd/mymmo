extends Node

@onready var server_connection : Node = $ServerConnection
@onready var debug_panel : Panel = $CanvasLayer/DebugPanel

func _ready() -> void:
	var email : String = "email@email.ru"
	var password : String = "password"
	
	debug_panel.write_message("Auth user %s" % email)
	var result : int = await  server_connection.auth_async(email, password)
	
	if result == OK:
		debug_panel.write_message("Auth user %s success" % email)
	else:
		debug_panel.write_message("Could not auth user %s" % email)
