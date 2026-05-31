extends CharacterBody2D

signal game_over
signal skill_w_used

# 경계값 변수
var bound_left: float = 0.0
var bound_right: float = 3220.0
var bound_top: float = -1050.0
var bound_bottom: float = 1000.0

# 속도
const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const JUMP_RELEASE_MULTIPLIER = 2.5

# 점프
@export var coyote_time = 0.1
@export var jump_buffer_time = 0.1

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

# 상태
enum State { IDLE, RUN, JUMP, FALL, KNOCK }
var current_state: State = State.IDLE

# animation
@onready var anim = $AnimatedSprite2D

# collision
@onready var collision = $CollisionShape2D
var player_width = 0
var player_height = 0

# 리스폰 위치
var spawn_position: Vector2

# 넉백 + 무적
var is_invincible = false
var knockback_velocity = Vector2.ZERO
const KNOCKBACK_FORCE = 400.0
const INVINCIBLE_TIME = 1.7

# 체력
var hp: int = 50
const MAX_HP: int = 30

func _ready() -> void:
	var shape = collision.shape as CapsuleShape2D
	player_width  = shape.radius * 2.0
	player_height = shape.height
	add_to_group("player")
	PlayerData.load_to_player(self)
	spawn_position = global_position


# 청동 검 능력
var has_bronze_sword: bool = false
var sword_cooldown: float = 0.0
const SWORD_COOLDOWN_TIME: float = 5.0
var fear_time = 2.0

# 금동관 능력 (더블점프)
var has_crown: bool = false
var double_jump_available: bool = false

# 노리개 능력 (스킬 W – 무빙 플랫폼 작동)
var has_fan_pendant: bool = false
var skill_w_cooldown: float = 0.0
const SKILL_W_COOLDOWN_TIME: float = 7.0
func _physics_process(delta: float) -> void:
	if sword_cooldown > 0:
		sword_cooldown -= delta
	elif sword_cooldown < 0:
		sword_cooldown = 0

	if skill_w_cooldown > 0:
		skill_w_cooldown -= delta
	elif skill_w_cooldown < 0:
		skill_w_cooldown = 0

	# 청동 검 사용
	if Input.is_action_just_pressed("use_skill1") and has_bronze_sword:
		use_bronze_sword()
	# 노리개 스킬 W 사용
	if Input.is_action_just_pressed("use_skill_w") and has_fan_pendant:
		use_skill_w()
	# 중력
	if not is_on_floor():
		if velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
			velocity += get_gravity() * JUMP_RELEASE_MULTIPLIER * delta
		else:
			velocity += get_gravity() * delta

	# Coyote Time 갱신
	if is_on_floor():
		coyote_timer = coyote_time
		double_jump_available = true  # 착지 시 더블점프 리셋
	else:
		coyote_timer -= delta

	# Input Buffer 갱신
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# 점프 (KNOCK 중 차단)
	if jump_buffer_timer > 0 and coyote_timer > 0 and current_state != State.KNOCK:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
		SoundManager.play_sfx(SoundManager.sfx_jump)
	# 더블점프 (FALL 상태 + 금동관 보유 + 더블점프 가용)
	elif jump_buffer_timer > 0 and has_crown and double_jump_available and current_state == State.FALL:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		double_jump_available = false
		SoundManager.play_sfx(SoundManager.sfx_jump)

	# ↓ + 점프 → One-Way Platform 아래로 통과
	_handle_drop_through()

	# 이동
	if knockback_velocity != Vector2.ZERO:
		if current_state != State.KNOCK:  # 상태 전환 시 1번만
			current_state = State.KNOCK
			_play_animation()
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000 * delta)
		if knockback_velocity.length() < 10:
			knockback_velocity = Vector2.ZERO
	else:
		if current_state == State.KNOCK:
			current_state = State.IDLE
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			anim.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	_update_state()
	move_and_slide()
	_check_edge()

# Stage에서 호출
func set_bounds(left: float, right: float, top: float, bottom: float) -> void:
	bound_left   = left
	bound_right  = right
	bound_top    = top
	bound_bottom = bottom
	var cam = $Camera2D
	cam.limit_right = bound_right

func _check_edge() -> void:
	if global_position.x - player_width / 2 < bound_left:
		global_position.x = bound_left + player_width / 2

	if global_position.x > bound_right:
		global_position.x = bound_right
		velocity.x = 0

	if global_position.y > bound_bottom:
		_on_fall()

func _on_fall() -> void:
	hp -= 10
	hp = max(hp, 0)
	if hp <= 0:
		_trigger_game_over()
		return
	_respawn()

func _respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO

func _handle_drop_through() -> void:
	if Input.is_action_pressed("ui_down"):
		set_collision_mask_value(2, false)
		await get_tree().create_timer(0.2).timeout
		set_collision_mask_value(2, true)

func _update_state() -> void:
	# KNOCK 중엔 상태 변경 차단
	if current_state == State.KNOCK:
		return

	var new_state: State

	if not is_on_floor():
		if velocity.y < 0:
			new_state = State.JUMP
		else:
			new_state = State.FALL
	elif velocity.x != 0:
		new_state = State.RUN
	else:
		new_state = State.IDLE

	if new_state != current_state:
		current_state = new_state
		_play_animation()

func _play_animation() -> void:
	anim.offset = Vector2.ZERO   # dead 이후 다른 애니메이션 재생 시 오프셋 초기화
	match current_state:
		State.IDLE:  anim.play("idle")
		State.RUN:   anim.play("run")
		State.JUMP:  anim.play("jump")
		State.FALL:  anim.play("fall")
		State.KNOCK: anim.play("knock")

func take_damage(damage, enemy_position: Vector2):
	if is_invincible:
		return

	hp -= damage
	hp = max(hp, 0)

	SoundManager.play_sfx(SoundManager.sfx_hit)

	if hp <= 0:
		_die()
		return

	var dir = sign(global_position.x - enemy_position.x)
	knockback_velocity = Vector2(dir * KNOCKBACK_FORCE, -200.0)

	is_invincible = true
	_start_invincible_flash()
	await get_tree().create_timer(INVINCIBLE_TIME).timeout
	is_invincible = false
	anim.modulate.a = 1.0

func _die() -> void:
	_trigger_game_over()

func _trigger_game_over() -> void:
	anim.modulate.a = 1.0
	is_invincible = false
	knockback_velocity = Vector2.ZERO
	set_physics_process(false)
	SoundManager.stop_bgm()
	SoundManager.play_sfx(SoundManager.sfx_gameover)

	# dead 스프라이트는 가로형이라 세로형 애니메이션과 기준점이 다름
	# Y 오프셋으로 눕는 스프라이트를 바닥에 맞춤 (값 조정 필요 시 DEAD_OFFSET_Y 수정)
	const DEAD_OFFSET_Y := 100.0
	anim.offset = Vector2(0.0, DEAD_OFFSET_Y)
	anim.play("dead")

	game_over.emit()

func _start_invincible_flash():
	while is_invincible:
		anim.modulate.a = 0.3 if anim.modulate.a > 0.5 else 1.0
		await get_tree().create_timer(0.1).timeout
		
func unlock_bronze_sword() -> void:
	has_bronze_sword = true
	print("청동 검 획득!")

func unlock_crown() -> void:
	has_crown = true
	double_jump_available = true
	print("금동관 획득! 더블점프 가능")

func use_bronze_sword() -> void:
	if not has_bronze_sword:
		print("bronze_swrod가 없습니다.")
		return
	if sword_cooldown > 0:
		print("bronze_sword가 쿨타임 입니다")
		return
	sword_cooldown = SWORD_COOLDOWN_TIME
	# 범위 내 모든 적에게 공포 적용
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 200.0:
			print("범위 내 적을 공포로 만듭니다.")
			enemy.apply_fear(fear_time)
		else:
			print("범위 내 적이 없습니다.")

func unlock_fan_pendant() -> void:
	has_fan_pendant = true
	print("노리개 획득! 스킬 W 사용 가능")

func use_skill_w() -> void:
	if skill_w_cooldown > 0:
		return
	skill_w_cooldown = SKILL_W_COOLDOWN_TIME
	skill_w_used.emit()
