extends CenterContainer

var port: String

@export var port_line_edit: LineEdit

@onready var scene_manager = get_tree().get_nodes_in_group("Manager")[0]
@onready var world = get_tree().get_nodes_in_group("Manager")[1].world

func _ready() -> void:
	Network.peer_created.connect(_go_to_game)

func _on_host_pressed() -> void:
	Network.host_lobby()

func _on_port_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		port_line_edit.text = ""
		port = ""
	elif new_text.is_valid_int():
		port_line_edit.text = new_text
		port_line_edit.caret_column = new_text.length()
		port = new_text
	else:
		port_line_edit.text = port

func _on_join_pressed() -> void:
	Network.join_lobby(port.to_int())

func _on_back_pressed() -> void:
	scene_manager.change_scene("MainMenu")

func _go_to_game() -> void:
	scene_manager.change_scene("GameMenu")
