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

#점프
@export var coyote_time = 0.1
@export var jump_buffer_time = 0.1

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

# 상태
enum State { IDLE, RUN, JUMP, FALL }
var current_state: State = State.IDLE

#animation
@onready var anim = $AnimatedSprite2D

#collsion
@onready var collision = $CollisionShape2D
var player_width = 0
var player_height = 0

func _ready() -> void:
	# RectangleShape2D 기준
	var shape = collision.shape as RectangleShape2D
	player_width = shape.size.x
	player_height = shape.size.y
	print(player_width, player_height)
	
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

	# 점프
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	# ↓ + 점프 → One-Way Platform 아래로 통과
	_handle_drop_through()

	# 이동
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_check_edge()
	_update_state()

# Stage에서 호출
func set_bounds(left: float, right: float, top: float ,bottom: float) -> void:
	bound_left   = left
	bound_right  = right
	bound_top = top
	bound_bottom = bottom
	
func _check_edge() -> void:
	# 좌우 경계
	if global_position.x - player_width/2 < bound_left:
		global_position.x = bound_left + player_width/2
		#velocity.x = 0

	if global_position.x > bound_right:
		global_position.x = bound_right
		velocity.x = 0


	# 낙사
	if global_position.y > bound_bottom:
		_respawn()

func _respawn() -> void:
	global_position = Vector2(200, 300)
	velocity = Vector2.ZERO


func _handle_drop_through() -> void:
	# 아래 방향키 + 점프키 
	if Input.is_action_pressed("ui_down"):
		# 일시적으로 One-Way collision 무시
		set_collision_mask_value(2, false)  # 2번 레이어 = One-Way Platform 레이어
		await get_tree().create_timer(0.2).timeout
		set_collision_mask_value(2, true)

func _update_state() -> void:
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
		State.IDLE: anim.play("idle")
		State.RUN:  anim.play("run")
		State.JUMP: anim.play("jump")
		State.FALL: anim.play("fall")
