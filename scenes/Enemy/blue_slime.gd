extends BaseEnemy
class_name SlimeEnemy




func _ready() -> void:
	super._ready()   # 부모 _ready() 호출
	speed = 50.0     # 슬라임은 느리게
	max_hp = 2
	hp = max_hp



# 애니메이션 오버라이드
func _update_animation() -> void:
	match current_state:
		State.PATROL:
			if is_on_floor():
				anim.play("walk")
			else:
				anim.play("fall")
		State.CHASE:  
			anim.play("walk")
		State.FEAR:
			anim.play("walk")  # 공포 시 빠르게 도망
		State.DEAD:
			pass  # _die()에서 처리
