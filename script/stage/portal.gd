extends Area2D

@export_file("*.tscn") var next_scene: String  # 에디터에서 다음 씬 지정

@export var text = "stage"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Label.text = text

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		monitoring = false
		body.set_physics_process(false)
		PlayerData.save_from_player(body)
		SoundManager.play_sfx(SoundManager.sfx_portal)
		SceneTransition.fade_to_scene(next_scene)
