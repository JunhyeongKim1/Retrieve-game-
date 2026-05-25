extends BaseItem
class_name GlitbronzeCrown

func _ready() -> void:
	super._ready()
	item_name = "금동관 / 보물 제2018호"
	item_description = "행소박물관의 금동관(金銅冠)은 고령 지역 대가야 지배층의 강력한 권력과 높은 금속 공예 기술을 증명하는 귀중한 유물입니다.  \n 신라나 백제와는 차별화된 가야 고유의 독자적인 양식과 미의식을 보여주는 고고학적 지표입니다.\n\n더블 점프를 사용 할 수 있습니다"

func _apply_effect(player: Node) -> void:
	player.unlock_crown()
