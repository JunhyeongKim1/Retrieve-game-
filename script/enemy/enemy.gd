extends CharacterBody2D
class_name BaseEnemy

@export var speed: float = 80.0
@export var max_hp: int = 3

var hp: int
var direction: float = 1.0
var fear_timer: float = 0.0

@onready var anim = $AnimatedSprite2D
@onready var ray_left  = $RayCastLeft
@onready var ray_right = $RayCastRight

enum State { PATROL, FEAR, DEAD }
var current_state: State = State.PATROL

func _ready() -> void:
	hp = max_hp
	ray_left.target_position  = Vector2(-30, 40)
	ray_right.target_position = Vector2(30, 40)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		State.PATROL: _process_patrol()
		State.FEAR:   _process_fear(delta)
		State.DEAD:   pass

	move_and_slide()
	_update_animation()

# ── 공통 로직 ──────────────────

func _process_patrol() -> void:
	if direction > 0 and not ray_right.is_colliding():
		direction = -1.0
	elif direction < 0 and not ray_left.is_colliding():
		direction = 1.0
	if is_on_wall():
		direction *= -1.0
	velocity.x = direction * speed
	anim.flip_h = direction < 0

func _process_fear(delta: float) -> void:
	fear_timer -= delta
	if fear_timer <= 0:
		current_state = State.PATROL
	velocity.x = -direction * speed * 1.5
	anim.flip_h = velocity.x < 0

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	hp -= amount
	if hp <= 0:
		_die()

func apply_fear(duration: float) -> void:
	if current_state == State.DEAD:
		return
	fear_timer = duration
	current_state = State.FEAR

func _die() -> void:
	current_state = State.DEAD
	anim.play("die")
	await anim.animation_finished
	queue_free()

# ── 자식에서 오버라이드 ──────────

func _update_animation() -> void:
	pass  # 자식에서 구현

func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(1)
