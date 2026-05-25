extends Node2D

@export_file("*.tscn") var next_scene: String  # 에디터에서 다음 씬 지정

# Called when the node enters the scene tree for the first time.

func _on_button_pressed() -> void:
	SceneTransition.fade_to_scene(next_scene)
