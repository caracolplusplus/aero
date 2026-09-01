extends Control


@onready var scene_manager = get_tree().get_nodes_in_group("Manager")[0]


func _on_press_any_key_tree_exited() -> void:
	$Transition.play("game_start_transition")

func _on_singleplayer_pressed() -> void:
	scene_manager.change_scene("GameMenu")

func _on_multiplayer_pressed() -> void:
	scene_manager.change_scene("MultiplayerMenu")

func _on_settings_pressed() -> void:
	scene_manager.change_scene("SettingsMenu")

func _on_quit_pressed() -> void:
	get_tree().quit()
