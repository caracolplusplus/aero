extends Button


func _on_pressed() -> void:
	start_game()

func _unhandled_input(event):
	if event.is_action_pressed("start_game"):
		start_game()

func start_game():
	print("Game Start")
	$"../../Backdrop".get_node("AnimationPlayer").play("menu_game_start")
	$".".queue_free()
