extends Control

var pages: Array[String] = [
	"마침내, 모든 유물이\n행소 박물관으로 돌아왔다.",
	"청동검, 금동관, 노리개.\n\n저마다의 힘을 간직한 채\n제자리를 찾아 돌아온 유물들.",
	"몬스터들은 물러가고\n박물관은 다시 평화로워졌다.",
	"유물을 되찾은 학생은\n아무 말 없이 박물관 문을 나섰다.\n\n그것으로 충분했다.",
	"유물 회수 완료.\n\n— 계명대학교 행소박물관 —"
]

var current_page: int = 0

func _ready() -> void:
	$ContinueButton.pressed.connect(_on_continue_pressed)
	_show_page(current_page)

func _show_page(index: int) -> void:
	$StoryLabel.text = pages[index]
	$ContinueButton.text = "메인메뉴로" if index >= pages.size() - 1 else "다음 >"

func _on_continue_pressed() -> void:
	$ContinueButton.disabled = true
	current_page += 1
	if current_page >= pages.size():
		SceneTransition.fade_to_scene("res://scenes/main/main_menu.tscn")
	else:
		_show_page(current_page)
		$ContinueButton.disabled = false
