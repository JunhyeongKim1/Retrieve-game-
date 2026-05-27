extends CanvasLayer

@onready var rect = $ColorRect

var _is_transitioning := false

func _ready() -> void:
	rect.color = Color(0, 0, 0, 0)  # 투명 시작
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_to_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	# 페이드 아웃
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(path)
	# 페이드 인
	tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	await tween.finished
	_is_transitioning = false
