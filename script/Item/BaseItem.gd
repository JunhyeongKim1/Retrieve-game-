extends Area2D
class_name BaseItem

# 아이템 기본 정보
@export var item_name: String = "아이템"
@export var item_description: String = "아이템 설명"
@export var item_icon: Texture2D = null  # 팝업 UI에 표시할 아이콘

# 둥둥 떠있는 연출
@export var float_amplitude: float = 5.0   # 위아래 이동 폭
@export var float_speed: float = 2.0       # 이동 속도

var base_y: float
var float_timer: float = 0.0
var is_collected: bool = false

func _ready() -> void:
	base_y = global_position.y
	# 시그널 연결
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		return
	# 둥둥 떠있는 연출
	float_timer += delta
	global_position.y = base_y + sin(float_timer * float_speed) * float_amplitude

# ── 공통 획득 로직 ──────────────────────────

func _on_body_entered(body: Node) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		is_collected = true
		_on_collected(body)

func _on_collected(player: Node) -> void:
	# 1. 팝업 UI 표시
	_show_popup()
	# 2. 능력 적용 (자식에서 오버라이드)
	_apply_effect(player)
	# 3. 아이템 획득 SFX
	SoundManager.play_sfx(SoundManager.sfx_item)
	# 3. GameManager에 수집 기록
	# GameManager.register_item(item_name)  ← 나중에 연결
	# 4. 아이템 제거
	_remove_item()

func _show_popup() -> void:
	var popup = preload("res://scenes/ui/ItemPopup.tscn").instantiate()
	get_tree().root.add_child(popup)
	popup.show_item(item_name, item_description, item_icon)

func _remove_item() -> void:
	# 획득 연출 후 제거
	#$Sprite2D.visible = false
	#$CollisionShape2D.disabled = true
	#await get_tree().create_timer(0.5).timeout
	queue_free()

# ── 자식에서 오버라이드 ──────────────────────

func _apply_effect(player: Node) -> void:
	pass  # 자식에서 구현
