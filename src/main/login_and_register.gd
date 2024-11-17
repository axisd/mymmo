extends Node

@onready var email_text_line : LineEdit = \
	$MarginContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/GridContainer/EmailEditLine
	
@onready var password_text_line : LineEdit = \
	$MarginContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/VBoxContainer/GridContainer/PasswordEditLine
	
@onready var error_label : Label = \
	$MarginContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/Panel/DebugLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.show_login_error.connect(handle_show_login_error)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_login_button_pressed() -> void:
	var email = email_text_line.text
	var password = password_text_line.text
	
	if email.is_empty():
		error_label.text = "email cant be empty"
		return
		
	if password.is_empty():
		error_label.text = "password cant be empty"
		return
		
	Events.login_to_server.emit(email, password, false)


func _on_register_button_pressed() -> void:
	var email = email_text_line.text
	var password = password_text_line.text
	
	if email.is_empty():
		error_label.text = "email cant be empty"
		return
		
	if password.is_empty():
		error_label.text = "password cant be empty"
		return
		
	Events.login_to_server.emit(email, password, true)

func handle_show_login_error(error : String) -> void:
	error_label.text = error
	print(error)
