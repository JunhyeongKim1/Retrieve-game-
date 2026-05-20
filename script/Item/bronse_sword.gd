extends BaseItem
class_name BronzeSword

func _ready() -> void:
	super._ready()
	item_name = "청동 검"
	item_description = "고대 청동으로 만들어진 검.\n적을 공포 상태로 만든다. (재사용 대기시간 30초)"

func _apply_effect(player: Node) -> void:
	player.unlock_bronze_sword()
