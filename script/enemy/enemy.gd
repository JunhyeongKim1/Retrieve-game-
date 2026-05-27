extends CharacterBody2D
class_name BaseEnemy

@export var speed: float = 80.0
@export var chase_speed: float = 120.0
@export var max_hp: int = 3

@export var damage = 5

var can_damage = true
var fall_death_y: float = 1200.0

func set_fall_death_y(y: float) -> void:
	fall_death_y = y

var hp: int
var direction: float = 1.0
var fear_timer: float = 0.0
var player_ref: Node = null

@onready var anim = $AnimatedSprite2D
@onready var ray_left  = $Left_Raycast
@onready var ray_right = $Right_Raycast
@onready var detection_shape = $ViewFiled/CollisionShape2D
@onready var detection_area  = $ViewFiled

@onready var hitbox = $HitboxArea2D
var player_in_hitbox: Node = null

enum State { PATROL, CHASE, FEAR, DEAD }
var current_state: State = State.PATROL

func _ready() -> void:
	hp = max_hp
	ray_left.target_position  = Vector2(-30, 40)
	ray_right.target_position = Vector2(30, 40)
	# 시그널 코드로 연결 (에디터에서 이미 연결했으면 이 줄 제거)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)  # 누락된 부분
	add_to_group("enemy")


func _on_damage_cooldown():
	can_damage = true;
	
func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_hitbox = body

func _on_hitbox_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_hitbox = null

#func _on_hitbox_body_entered(body) -> void:
	#print("dsds" + body.name)
	#if body.is_in_group("player") and can_damage:
		#body.take_damage(damage, position)
		#can_damage = false
		#await get_tree().create_timer(1.0).timeout
		#can_damage = true

func _physics_process(delta: float) -> void:
	if current_state != State.DEAD and position.y > fall_death_y:
		current_state = State.DEAD
		queue_free()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		State.PATROL: _process_patrol()
		State.CHASE:  _process_chase()
		State.FEAR:   _process_fear(delta)
		State.DEAD:   pass

	move_and_slide()
	_update_animation()

	if player_in_hitbox != null and can_damage:
		player_in_hitbox.take_damage(damage, global_position)
		can_damage = false
		get_tree().create_timer(1.0).timeout.connect(_on_damage_cooldown, CONNECT_ONE_SHOT)
		
func _process_patrol() -> void:
	# 벽/낭떠러지 감지는 바닥 위일 때만 → 공중(점프 중)엔 방향 유지
	if is_on_floor():
		if is_on_wall():
			direction *= -1.0
		elif direction > 0 and not ray_right.is_colliding():
			direction = -1.0
		elif direction < 0 and not ray_left.is_colliding():
			direction = 1.0

	velocity.x = direction * speed
	anim.flip_h = direction > 0

	# 감지 영역 방향 전환
	detection_shape.position.x = abs(detection_shape.position.x) * direction

func _process_chase() -> void:
	if player_ref == null:
		current_state = State.PATROL
		return

	var chase_dir = sign(player_ref.global_position.x - global_position.x)

	# 낭떠러지 감지는 바닥 위일 때만 → 공중(점프 중)엔 추격 유지
	if is_on_floor():
		if chase_dir > 0 and not ray_right.is_colliding():
			current_state = State.PATROL
			return
		elif chase_dir < 0 and not ray_left.is_colliding():
			current_state = State.PATROL
			return

	direction = chase_dir
	velocity.x = direction * chase_speed
	anim.flip_h = direction > 0

func _process_fear(delta: float) -> void:
	fear_timer -= delta
	if fear_timer <= 0:
		current_state = State.PATROL
		return
	var flee_dir: float
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		flee_dir = sign(global_position.x - player.global_position.x)
		if flee_dir == 0.0:
			flee_dir = -direction
	else:
		flee_dir = -direction
	velocity.x = flee_dir * speed * 1.5
	anim.flip_h = velocity.x > 0
	
		# 벽/낭떠러지 감지 → 방향 전환
	if is_on_wall():
		direction *= -1.0
	elif direction > 0 and not ray_right.is_colliding():
		direction = -1.0
	elif direction < 0 and not ray_left.is_colliding():
		direction = 1.0

	# 감지 영역 방향 전환
	detection_shape.position.x = abs(detection_shape.position.x) * direction
	
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
	print("die")
	queue_free()
	

func _on_area_2d_body_entered(body: Node) -> void:
	print("감지된 body: ", body.name)
	print("body 그룹: ", body.get_groups())
	print("is_in_group 결과: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		print("dfd")
		player_ref = body
		if current_state == State.PATROL:
			current_state = State.CHASE


func _on_area_2d_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		print("sed")
		player_ref = null
		if current_state == State.CHASE:
			current_state = State.PATROL

func _update_animation() -> void:
	pass
