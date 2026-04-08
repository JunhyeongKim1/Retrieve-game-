extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const JUMP_RELEASE_MULTIPLIER = 2.0

@export var coyote_time = 0.1
@export var jump_buffer_time = 0.1

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

# 상태 정의
enum State { IDLE, RUN, JUMP, FALL }
var current_state: State = State.IDLE

@onready var anim = $AnimatedSprite2D

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

	# 점프 조건
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	# 이동
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0  # 좌우 반전
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# 상태 갱신 (move_and_slide 이후에 해야 is_on_floor()가 정확)
	_update_state()
	
	

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

	# 상태가 바뀔 때만 애니메이션 교체
	if new_state != current_state:
		current_state = new_state
		_play_animation()

func _play_animation() -> void:
	match current_state:
		State.IDLE: anim.play("idle")
		State.RUN:  anim.play("run")
		State.JUMP: anim.play("jump")
		State.FALL: anim.play("fall")
	print("Animation Change" + str(current_state))
