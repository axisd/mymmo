extends Node

@export var user_color : Color = Color.LIME

@onready var server_connection : Node = $ServerConnection
@onready var debug_panel : Panel = $CanvasLayer/DebugPanel
@onready var chat_box : Control = $CanvasLayer/ChatUI
@onready var login_box : Node = $LoginUI

func _ready() -> void:	
	Events.login_to_server.connect(handle_login_to_server)
	
	var characters : Array = [
		{name = "Jack", color = Color.BLUE.to_html(false)},
		{name = "Lisa", color = Color.RED.to_html(false)},
	]
	
func handle_login_to_server(email : String, password : String, need_create : bool) -> void:
	
	Events.show_login_error.emit("Auth user %s" % email)

	var result : int = await  server_connection.auth_async(email, password, need_create)
	
	if result == OK:
		Events.show_login_error.emit("Auth user %s success" % email)
		
		handle_connect_to_server()
	else:
		Events.show_login_error.emit("Could not auth user %s" % email)

func handle_connect_to_server() -> void:
	var result : int = await server_connection.connect_to_server_async()
	if result == OK:
		Events.show_login_error.emit("connected to server")
		
		handle_join_world()
	else:
		Events.show_login_error.emit("could not connect")
		
func handle_join_world() -> void:
	var presences : Dictionary = await server_connection.join_world_async()
	
	if not presences.is_empty():
		Events.show_login_error.emit("joined to world")
		
		handle_join_chat()	
	else:
		Events.show_login_error.emit("could not join to world")
		
func handle_join_chat() -> void:
	var result : int = await server_connection.join_chat_async()
	if result == OK:
		Events.show_login_error.emit("joined to chat")
		
		login_box.queue_free()
		chat_box.show()
	else:
		Events.show_login_error.emit("could not join to chat")


# slots
func _on_chat_ui_text_send(text: Variant) -> void:
	var result : int = await server_connection.send_text_async(text)
	if result == OK:
		Events.show_login_error.emit("joined to chat")
	else:
		Events.show_login_error.emit("could not join to chat")

func _on_server_connection_chat_message_received(username: Variant, text: Variant) -> void:
	chat_box.add_reply(text, username, user_color)
