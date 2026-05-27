extends CanvasLayer

var hp_bar: ProgressBar
var hp_label: Label
var player: Node = null

var _last_hp: int = -1
var _hp_tween: Tween = null
var _game_over_panel: Panel

const COLOR_HIGH = Color(0.18, 0.78, 0.22)
const COLOR_MID  = Color(0.92, 0.72, 0.08)
const COLOR_LOW  = Color(0.88, 0.15, 0.15)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_build_game_over_ui()
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.game_over.connect(_on_game_over)

func _build_ui() -> void:
	var panel = Panel.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(256, 54)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.82)
	panel_style.corner_radius_top_left    = 7
	panel_style.corner_radius_top_right   = 7
	panel_style.corner_radius_bottom_left = 7
	panel_style.corner_radius_bottom_right= 7
	panel_style.border_width_left   = 1
	panel_style.border_width_right  = 1
	panel_style.border_width_top    = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1, 1, 1, 0.12)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# "HP" 타이틀
	var title = Label.new()
	title.text = "HP"
	title.position = Vector2(12, 6)
	title.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))
	title.add_theme_font_size_override("font_size", 11)
	panel.add_child(title)

	# ProgressBar
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(12, 24)
	hp_bar.size = Vector2(172, 20)
	hp_bar.max_value = 30
	hp_bar.value = 30
	hp_bar.show_percentage = false

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = COLOR_HIGH
	fill_style.corner_radius_top_left    = 4
	fill_style.corner_radius_top_right   = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right= 4
	hp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.22, 0.06, 0.06)
	bg_style.corner_radius_top_left    = 4
	bg_style.corner_radius_top_right   = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right= 4
	hp_bar.add_theme_stylebox_override("background", bg_style)

	panel.add_child(hp_bar)

	# HP 숫자 텍스트
	hp_label = Label.new()
	hp_label.text = "30 / 30"
	hp_label.position = Vector2(190, 23)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	hp_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(hp_label)

func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var cur: int = player.hp
	if cur == _last_hp:
		return

	_last_hp = cur
	_update_display(cur, player.MAX_HP)

func _update_display(cur: int, max_hp: int) -> void:
	hp_label.text = "%d / %d" % [cur, max_hp]
	hp_bar.max_value = max_hp

	# 부드러운 바 애니메이션
	if _hp_tween:
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(hp_bar, "value", float(cur), 0.25)

	# HP 비율에 따라 색상 변경
	var ratio := float(cur) / float(max_hp)
	var fill_style := hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		if ratio > 0.6:
			fill_style.bg_color = COLOR_HIGH
		elif ratio > 0.3:
			fill_style.bg_color = COLOR_MID
		else:
			fill_style.bg_color = COLOR_LOW

func _build_game_over_ui() -> void:
	_game_over_panel = Panel.new()
	_game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_panel.visible = false
	_game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.0, 0.0, 0.0, 0.72)
	_game_over_panel.add_theme_stylebox_override("panel", overlay_style)
	add_child(_game_over_panel)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_panel.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 36)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.18, 0.18))
	title.add_theme_font_size_override("font_size", 72)
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "체력이 모두 소진되었습니다"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	sub.add_theme_font_size_override("font_size", 22)
	vbox.add_child(sub)

	var btn = Button.new()
	btn.text = "메인메뉴로"
	btn.custom_minimum_size = Vector2(220, 54)
	btn.add_theme_font_size_override("font_size", 26)
	btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(btn)

func _on_game_over() -> void:
	_game_over_panel.visible = true
	get_tree().paused = true

func _on_main_menu_pressed() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
