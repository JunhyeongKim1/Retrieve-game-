extends BaseItem
class_name FanPendant

signal collected

func _ready() -> void:
	super._ready()
	item_name = "호리병박 무늬로 장식한 노리개"
	item_description = "부채의 고리나 자루에 달았던 장식품입닏다.\n나무로 만든 몸통에는 호리병박이 새겨져 있습니다. 호리병박은 신선이 지니는 물건으로도 알려져 나쁜 기운을 막고 장수를 기원하는 뜻도 함게 지녔다.\n\n특정 블럭을 움직일 수 있습니다"

func _apply_effect(player: Node) -> void:
	player.unlock_fan_pendant()
	collected.emit()
