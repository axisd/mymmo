extends Control

signal text_send(text)
signal edit_started
signal edit_ended

const HISTORY_LENGTH : int = 20

var reply_count : int = 0

@onready var chat_log : RichTextLabel = $MarginContainer/Panel/VBoxContainer/ScrollContainer/ChatLog
@onready var chat_line : LineEdit = $MarginContainer/Panel/VBoxContainer/HBoxContainer/ChatLine

func _ready() -> void:
	chat_log.text = ""
	
func add_reply(text : String, sender_name : String, color : Color) -> void:
	if reply_count == HISTORY_LENGTH:
		chat_log.text = chat_log.text.substr(chat_log.text.find("\n"))
	else:
		reply_count += 1
	
	chat_log.text += (
		"\n[color=#%s]%s[/color]: %s"
		% [color.to_html(false), sender_name, text]
	)
	
func send_chat_message() -> void:
	if chat_line.text.length() == 0:
		return
	
	var text : String = chat_line.text.replace("[", "{").replace("]", "}")
	emit_signal("text_send", text)
	chat_line.text = ""


func _on_send_button_pressed() -> void:
	send_chat_message()


func _on_chat_line_text_submitted(new_text: String) -> void:
	send_chat_message()
