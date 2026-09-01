extends HSlider

const PITCH_SCALE_MAX = 4.0
const PITCH_SCALE_MIN = 0.01


var has_started_drag = false

func _on_value_changed(value: float) -> void:
	$Grabber.position.x = ((size.x * value) / max_value) - ($Grabber.size.x / 2)
	$Grabber.rotation_degrees = (value * 720) / max_value
	
	$Sound.pitch_scale = (PITCH_SCALE_MAX * value)/ max_value

	if (has_started_drag):
		$Sound.play()


func _on_resized() -> void:
	$Grabber.pivot_offset.x = $Grabber.size.x / 2
	$Grabber.pivot_offset.y = $Grabber.size.y / 2
	$Grabber.rotation_degrees = (value * 360) / max_value
	$Grabber.position.x = ((size.x * value) / max_value) - ($Grabber.size.x / 2)


func _on_drag_started() -> void:
	has_started_drag = true
