extends Panel

func write_message(msg : String) -> void:
	var text_label : Label = Label.new()
	text_label.text = msg
	$VBoxContainer.add_child(text_label)
