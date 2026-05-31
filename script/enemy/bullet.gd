extends Area2D

var move_velocity: Vector2 = Vector2.ZERO
var damage: int = 5
const SPEED: float = 350.0
var lifetime: float = 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.2, 1.0, 0.2))

# direction: 발사 방향 벡터 (정규화 전 OK), dmg: 데미지
func init(direction: Vector2, dmg: int) -> void:
	move_velocity = direction.normalized() * SPEED
	damage = dmg
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += move_velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage, global_position)
		queue_free()
