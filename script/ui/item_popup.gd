extends CanvasLayer

var _can_close: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	$Overlay.pressed.connect(_on_confirm_pressed)
	$Panel/VBox/ButtonMargin/ConfirmButton.pressed.connect(_on_confirm_pressed)
	# 팝업 등장 애니메이션
	$Panel.scale = Vector2(0.7, 0.7)
	$Panel.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Panel, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($Panel, "modulate:a", 1.0, 0.15)
	# 1초 후 닫기 허용
	await get_tree().create_timer(0.5).timeout
	_can_close = true

func show_item(_name: String, description: String, icon: Texture2D) -> void:
	$Panel/VBox/ContentMargin/HBox/ItemIcon.texture = icon
	$Panel/VBox/ContentMargin/HBox/TextVBox/ItemName.text = _name
	$Panel/VBox/ContentMargin/HBox/TextVBox/ItemDescription.text = description

func _input(event: InputEvent) -> void:
	if not _can_close:
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_on_confirm_pressed()

func _on_confirm_pressed() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Panel, "scale", Vector2(0.85, 0.85), 0.12)
	tween.tween_property($Panel, "modulate:a", 0.0, 0.12)
	await tween.finished
	get_tree().paused = false
	queue_free()
