extends Node2D

func _ready() -> void:
	$Button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	$Button.disabled = true
	get_tree().change_scene_to_file("res://scenes/story/intro.tscn")
