extends Timer


func train_cooldown_time():
	$".".wait_time = randf_range(10,40)
	print(wait_time)
	$".".start()

func _on_timeout() -> void:
	$"../TrainAnimation".play("train_animation")
	train_cooldown_time()
