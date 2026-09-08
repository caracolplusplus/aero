extends Button

func _on_pressed() -> void:
	start_game()

func _unhandled_input(event):
	if event.is_action_pressed("start_game"):
		start_game()

func start_game():
	print("Game Start")
	$"../VBoxContainer".show()
	$"../../Backdrop".get_node("CameraMovement").play("menu_game_start")
	$".".queue_free()
