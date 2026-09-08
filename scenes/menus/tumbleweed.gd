extends TextureRect

var animation_number_1
var animation_number_2

func _on_tumbleweed_cooldown_1_timeout() -> void:
	animation_number_1 = randi_range(1,3)
	print("Animation Number 1 = " , animation_number_1)
	tumbleweed_1()
	$"../TumbleweedCooldown_1".wait_time = randf_range(5,15)
	print("Timer 1 = " , $"../TumbleweedCooldown_1".wait_time)

func _on_tumbleweed_cooldown_2_timeout() -> void:
	animation_number_2 = randi_range(1,3)
	print("Animation Number 2 = " , animation_number_2)
	tumbleweed_1()
	$"../TumbleweedCooldown_2".wait_time = randf_range(5,15)
	print("Timer 2 = " , $"../TumbleweedCooldown_2".wait_time)

func tumbleweed_1():
	if animation_number_1 == 1:
		$"../Tumbleweed Animation_1".play("Tumbleweed_1")
		$"../TumbleweedCooldown_1".start()
	if animation_number_1 == 2:
		$"../Tumbleweed Animation_2".play("Tumbleweed_2")
		$"../TumbleweedCooldown_1".start()
	if animation_number_1 == 3:
		$"../Tumbleweed Animation_3".play("Tumbleweed_3")
		$"../TumbleweedCooldown_1".start()

func tumbleweed_2():
	if animation_number_2 == 1:
		$"../Tumbleweed Animation_1".play("Tumbleweed_1")
		$"../TumbleweedCooldown_2".start()
	if animation_number_2 == 2:
		$"../Tumbleweed Animation_2".play("Tumbleweed_2")
		$"../TumbleweedCooldown_2".start()
	if animation_number_2 == 3:
		$"../Tumbleweed Animation_3".play("Tumbleweed_3")
		$"../TumbleweedCooldown_2".start()
