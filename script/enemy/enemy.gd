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

var _player_in_range: bool = false
var _chase_linger_timer: float = 0.0
const CHASE_LINGER_TIME: float = 2.0

var _exclamation: Sprite2D = null

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
	hitbox.body_exited.connect(_on_hitbox_body_exited)
	add_to_group("enemy")
	_build_exclamation()


func _build_exclamation() -> void:
	_exclamation = Sprite2D.new()
	_exclamation.texture = load("res://asset/particle/!_sprite.png")
	_exclamation.visible = false
	add_child(_exclamation)

	# 스프라이트가 완전히 초기화된 뒤 실제 텍스처 크기로 위치 계산
	await get_tree().process_frame
	_place_exclamation()


func _place_exclamation() -> void:
	const MARGIN = 14.0

	# CollisionShape2D 상단 = 실제 몸통 윗부분(눈 근처)
	# 콜리전은 flip_h와 무관하게 위치가 고정되므로 그대로 사용
	var col = $CollisionShape2D
	if col and col.shape is RectangleShape2D:
		var rect = col.shape as RectangleShape2D
		var top_y = col.position.y - rect.size.y * 0.5
		_exclamation.position = Vector2(0.0, top_y - MARGIN)
		_exclamation.flip_h = anim.flip_h
		return

	# 폴백: 텍스처 높이 기반
	if anim.sprite_frames and anim.sprite_frames.has_animation(anim.animation):
		var frame_tex = anim.sprite_frames.get_frame_texture(anim.animation, 0)
		if frame_tex:
			var sprite_h = frame_tex.get_height() * abs(anim.scale.y)
			_exclamation.position = Vector2(anim.position.x,
											anim.position.y - sprite_h * 0.5 - MARGIN)


func _show_exclamation() -> void:
	if _exclamation == null:
		return
	# 표시 직전 현재 flip 상태로 위치 재계산
	_place_exclamation()
	_exclamation.modulate.a = 1.0
	_exclamation.scale      = Vector2(0.0, 0.0)
	_exclamation.visible    = true

	var tw := create_tween()
	# 팡 튀어나오는 느낌
	tw.tween_property(_exclamation, "scale", Vector2(0.4, 0.4), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 잠깐 유지
	tw.tween_interval(0.45)
	# 페이드아웃
	tw.tween_property(_exclamation, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func() -> void: _exclamation.visible = false)


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
		State.CHASE:  _process_chase(delta)
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
	detection_shape.position.x = abs(detection_shape.position.x) * direction

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

	# 벽/낭떠러지 감지는 바닥 위일 때만 — 공중에서 검사하면 direction이 매 프레임 교번함
	if is_on_floor():
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
	if body.is_in_group("player"):
		player_ref = body
		_player_in_range = true
		_chase_linger_timer = 0.0
		if current_state == State.PATROL:
			current_state = State.CHASE
			_show_exclamation()


func _on_area_2d_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_chase_linger_timer = CHASE_LINGER_TIME

func _update_animation() -> void:
	pass
