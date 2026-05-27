extends SlimeEnemy
class_name RedSlimeEnemy

# ── 점프 설정 ─────────────────────────────────────────────
const JUMP_VELOCITY := -360.0   # 점프 초기 속도
const JUMP_INTERVAL := 1.5      # 점프 간격 (초)

var _jump_timer: float = 0.6    # 등장 직후 첫 점프까지 딜레이


func _ready() -> void:
	super._ready()
	speed        = 70.0    # 블루슬라임(50)보다 빠름
	chase_speed  = 150.0
	max_hp       = 4
	hp           = max_hp
	damage       = 8

	# ※ 레드슬라임 전용 스프라이트가 없을 경우 색조로 구분
	#   나중에 anim.sprite_frames 를 교체하면 modulate 제거 가능
	anim.modulate = Color(1.8, 0.25, 0.25)


func _physics_process(delta: float) -> void:
	# 점프 쿨타임 감소
	if _jump_timer > 0.0:
		_jump_timer -= delta

	# 바닥 위 + 이동 상태 + 쿨타임 만료 → 점프
	if is_on_floor() and _jump_timer <= 0.0:
		if current_state == State.PATROL or current_state == State.CHASE:
			velocity.y  = JUMP_VELOCITY
			_jump_timer = JUMP_INTERVAL

	super._physics_process(delta)


# 점프 중일 때 fall 애니메이션 표시
func _update_animation() -> void:
	match current_state:
		State.PATROL, State.CHASE:
			if is_on_floor():
				anim.play("walk")
			else:
				anim.play("fall")
		State.FEAR:
			anim.play("fear")
		State.DEAD:
			pass
