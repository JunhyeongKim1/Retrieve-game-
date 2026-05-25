extends Control

# 스토리 페이지 목록 — 내용은 자유롭게 수정
var pages: Array[String] = [
	"먼 과거의 물건, '유물'에는 신비한 힘이 담겨져 있다.\n시간이 흘러 대한민국에 흩어져 있던 유물은\n계명대학교 행소 박물관에 보관되어 있었다.",
	"그러나, 유물의 힘을 탐낸 몬스터들이\n 행소 박물관에서 유물을 훔쳐 세상 곳곳에 던져버렸다.",
	"행소 박물관의 유물들을 찾기위해",
	"계명대의 한 학생이\n잃어버린 유물을 되찾기 위한\n여정을 시작했다.",
	"당신의 여정이 지금 시작된다."
]

var current_page: int = 0

func _ready() -> void:
	$ContinueButton.pressed.connect(_on_continue_pressed)
	_show_page(current_page)

func _show_page(index: int) -> void:
	$StoryLabel.text = pages[index]
	$ContinueButton.text = "시작하기" if index >= pages.size() - 1 else "다음 >"

func _on_continue_pressed() -> void:
	current_page += 1
	if current_page >= pages.size():
		SceneTransition.fade_to_scene("res://scenes/stage/stage1.tscn")
	else:
		_show_page(current_page)
