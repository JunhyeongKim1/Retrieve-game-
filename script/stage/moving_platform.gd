extends AnimatableBody2D
class_name MovingPlatform

# 인스펙터에서 설정: 시작 위치 기준 이동할 방향과 거리
@export var route_offset: Vector2 = Vector2(200, 0)
@export var move_speed: float = 120.0

enum State { IDLE_AT_START, MOVING_FORWARD, IDLE_AT_END, MOVING_BACKWARD }
var current_state: State = State.IDLE_AT_START

var _start_pos: Vector2
var _end_pos: Vector2

func _ready() -> void:
	_start_pos = global_position
	_end_pos   = global_position + route_offset

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.skill_w_used.connect(_on_skill_w)

func _on_skill_w() -> void:
	match current_state:
		State.IDLE_AT_START:
			current_state = State.MOVING_FORWARD
		State.IDLE_AT_END:
			current_state = State.MOVING_BACKWARD
		# 이동 중에는 무시

func _physics_process(delta: float) -> void:
	match current_state:
		State.MOVING_FORWARD:
			var remaining = _end_pos - global_position
			var step = remaining.normalized() * move_speed * delta
			if step.length() >= remaining.length():
				move_and_collide(remaining)
				current_state = State.IDLE_AT_END
			else:
				move_and_collide(step)

		State.MOVING_BACKWARD:
			var remaining = _start_pos - global_position
			var step = remaining.normalized() * move_speed * delta
			if step.length() >= remaining.length():
				move_and_collide(remaining)
				current_state = State.IDLE_AT_START
			else:
				move_and_collide(step)
