extends Control


@onready var scene_manager = get_tree().get_nodes_in_group("Manager")[0]


func _on_back_pressed() -> void:
	scene_manager.change_scene("MainMenu")
