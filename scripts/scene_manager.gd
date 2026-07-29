class_name SceneManager
extends CanvasLayer

var _tween: Tween
var _loading: bool

@export var scene: Node
@export var scene_map: Dictionary[String, PackedScene]

@export var fade_out: ColorRect
@export var fade_duration: float = 0.25

func change_scene(scene_id: String) -> void:
	if _loading or not scene_id in scene_map:
		return
	
	_loading = true
	
	_fade_screen(fade_duration, Color.TRANSPARENT, Color.WHITE)
	await _tween.finished
	
	var scene_instance = scene_map[scene_id].instantiate()
	
	scene.get_child(0).queue_free()
	scene.add_child(scene_instance)
	
	_fade_screen(fade_duration, Color.WHITE, Color.TRANSPARENT)
	_loading = false

func _fade_screen(duration: float, start_color: Color, target_color: Color) -> void:
	if _tween:
		_tween.kill()
	
	fade_out.modulate = start_color
	
	_tween = create_tween()
	_tween.tween_property(fade_out, "modulate", target_color, duration)
