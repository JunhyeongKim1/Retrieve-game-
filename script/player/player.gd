extends CharacterBody2D

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

# 넉백 + 무적
var is_invincible = false
var knockback_velocity = Vector2.ZERO
const KNOCKBACK_FORCE = 400.0
const INVINCIBLE_TIME = 1.7

func _ready() -> void:
	var shape = collision.shape as RectangleShape2D
	player_width = shape.size.x
	player_height = shape.size.y
	print(player_width, player_height)
	add_to_group("player")
	

func _physics_process(delta: float) -> void:
	# 중력
	if not is_on_floor():
		if velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
			velocity += get_gravity() * JUMP_RELEASE_MULTIPLIER * delta
		else:
			velocity += get_gravity() * delta

	# Coyote Time 갱신
	if is_on_floor():
		coyote_timer = coyote_time
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

func _check_edge() -> void:
	if global_position.x - player_width / 2 < bound_left:
		global_position.x = bound_left + player_width / 2

	if global_position.x > bound_right:
		global_position.x = bound_right
		velocity.x = 0

	if global_position.y > bound_bottom:
		_respawn()

func _respawn() -> void:
	global_position = Vector2(200, 300)
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
	match current_state:
		State.IDLE:  anim.play("idle")
		State.RUN:   anim.play("run")
		State.JUMP:  anim.play("jump")
		State.FALL:  anim.play("fall")
		State.KNOCK: anim.play("knock")  

func take_damage(damage, enemy_position: Vector2):
	if is_invincible:
		return

	var dir = sign(global_position.x - enemy_position.x)
	knockback_velocity = Vector2(dir * KNOCKBACK_FORCE, -200.0)

	is_invincible = true
	_start_invincible_flash()
	await get_tree().create_timer(INVINCIBLE_TIME).timeout
	is_invincible = false
	anim.modulate.a = 1.0

func _start_invincible_flash():
	while is_invincible:
		anim.modulate.a = 0.3 if anim.modulate.a > 0.5 else 1.0
		await get_tree().create_timer(0.1).timeout
