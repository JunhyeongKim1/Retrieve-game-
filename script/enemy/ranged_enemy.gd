extends BaseEnemy
class_name RangedEnemy

@export var fire_rate: float = 2.0        # 발사 간격 (초)
@export var bullet_damage: int = 5
@export var chase_linger_time: float = 6.0 # 플레이어가 범위 벗어난 후 chase 유지 시간

var _fire_timer: float = 0.0
var _bullet_scene = preload("res://scenes/Enemy/Bullet.tscn")

func _ready() -> void:
	super._ready()
	speed       = 60.0
	chase_speed = 90.0
	max_hp      = 5
	hp          = max_hp
	anim.modulate = Color(0.2, 1.0, 0.2)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# CHASE 상태일 때만 사격 타이머 처리
	if current_state == State.CHASE and player_ref != null:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_shoot()
			_fire_timer = fire_rate


# CHASE 중: 제자리 고정, 플레이어 방향만 바라봄
func _process_chase(delta: float) -> void:
	if player_ref == null:
		current_state = State.PATROL
		return

	if not _player_in_range:
		_chase_linger_timer -= delta
		if _chase_linger_timer <= 0.0:
			player_ref = null
			current_state = State.PATROL
			return
	else:
		_chase_linger_timer = 0.0

	# 제자리 정지
	velocity.x = 0.0

	# 플레이어 방향으로 얼굴
	var face_dir = sign(player_ref.global_position.x - global_position.x)
	if face_dir != 0:
		anim.flip_h = face_dir > 0
		detection_shape.position.x = abs(detection_shape.position.x) * face_dir


func _shoot() -> void:
	if player_ref == null:
		return
	var bullet = _bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	var dir = player_ref.global_position - global_position
	bullet.init(dir, bullet_damage)


# 플레이어가 감지 범위를 벗어날 때 linger 시간을 override
func _on_area_2d_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_chase_linger_timer = chase_linger_time


func _update_animation() -> void:
	match current_state:
		State.PATROL:
			if is_on_floor():
				anim.play("walk")
			else:
				anim.play("fall")
		State.CHASE:
			anim.play("walk")
		State.FEAR:
			anim.play("fear")
		State.DEAD:
			pass
