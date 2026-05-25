extends BaseItem
class_name BronzeSword

func _ready() -> void:
	super._ready()
	item_name = "청동검"
	item_description = "청동검(靑銅劍)은 구리에 주석을 혼합한 청동으로 만들어진 검으로, 인류사 가운데 청동기 시대에 사용되었다. \n 청동기 시대에는 군장의 권력의 상징이었을 것으로 추정된다.\n\n적을 공포 상태로 만든다. (재사용 대기시간 5초)"

func _apply_effect(player: Node) -> void:
	player.unlock_bronze_sword()
