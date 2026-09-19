extends Path2D


@export var tumbleweed_scene: PackedScene = preload("res://scenes/menus/tumbleweed.tscn")


func spawn_tumbleweed():
	var tumbleweed_instance = tumbleweed_scene.instantiate()
	var tumbleweed_sprite = tumbleweed_instance.get_child(1).get_child(0)
	print($PathFollow2D.progress_ratio)
	tumbleweed_instance.global_position = $PathFollow2D.global_position
	var new_size = (tumbleweed_instance.global_position.y - 864) * 0.01
	tumbleweed_sprite.scale = Vector2(new_size,new_size)
	if tumbleweed_sprite.scale > Vector2(1,1):
		tumbleweed_sprite.scale = Vector2(1,1)
	if tumbleweed_sprite.scale < Vector2(0.4,0.4):
		tumbleweed_sprite.scale = Vector2(0.4,0.4)
	if tumbleweed_instance.global_position.y > 1055:
		tumbleweed_instance.set_z_index(1)
	if tumbleweed_instance.global_position.y < 1055:
		tumbleweed_instance.set_z_index(0)
	print("Scale = " , tumbleweed_sprite.scale)
	$"..".add_child(tumbleweed_instance)


func _on_tumbleweed_cooldown_timeout():
	spawn_tumbleweed()
	$PathFollow2D.progress_ratio = randf_range(0 , 1)
	$"Tumbleweed Cooldown".wait_time = randf_range(3, 10)
	print($"Tumbleweed Cooldown".wait_time)
	$"Tumbleweed Cooldown".start()
