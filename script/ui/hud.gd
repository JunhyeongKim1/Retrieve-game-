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

# ── 스킬 슬롯 ────────────────────────────────────────────
var _skill_slot: Panel
var _skill_arc: _SkillArc
var _skill_cd_label: Label

# 쿨타임 부채꼴 오버레이 (12시에서 시계방향으로 채워지고, 경과한 만큼 다시 시계방향으로 걷힘)
class _SkillArc extends Control:
	var ratio: float = 0.0  # 1.0 = 방금 사용, 0.0 = 준비됨

	func _draw() -> void:
		if ratio < 0.01:
			return
		var center := size / 2.0
		var r : float = min(size.x, size.y) / 2.0
		# 경과 비율만큼 12시 기준 시작점을 시계방향으로 이동
		var elapsed := 1.0 - ratio
		var dark_start := -PI / 2.0 + TAU * elapsed
		var pts := PackedVector2Array()
		pts.append(center)
		for i in 65:
			var a := dark_start + TAU * ratio * (float(i) / 64.0)
			pts.append(center + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.72))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_build_skill_ui()
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

	var title = Label.new()
	title.text = "HP"
	title.position = Vector2(12, 6)
	title.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))
	title.add_theme_font_size_override("font_size", 11)
	panel.add_child(title)

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

	hp_label = Label.new()
	hp_label.text = "30 / 30"
	hp_label.position = Vector2(190, 23)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	hp_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(hp_label)


func _build_skill_ui() -> void:
	const SLOT := 60
	const PAD  := 4

	# 슬롯 패널 — 왼쪽 하단에 앵커
	_skill_slot = Panel.new()
	_skill_slot.anchor_left   = 0.5
	_skill_slot.anchor_top    = 1.0
	_skill_slot.anchor_right  = 0.5
	_skill_slot.anchor_bottom = 1.0
	_skill_slot.offset_left   = -SLOT / 2
	_skill_slot.offset_top    = -(16 + SLOT)
	_skill_slot.offset_right  = SLOT / 2
	_skill_slot.offset_bottom = -16
	_skill_slot.visible = false  # 청동검 획득 전까지 숨김

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color(0.10, 0.07, 0.02, 0.88)
	slot_style.corner_radius_top_left    = 5
	slot_style.corner_radius_top_right   = 5
	slot_style.corner_radius_bottom_left = 5
	slot_style.corner_radius_bottom_right= 5
	slot_style.border_width_left   = 2
	slot_style.border_width_right  = 2
	slot_style.border_width_top    = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = Color(0.75, 0.50, 0.10, 0.85)
	_skill_slot.add_theme_stylebox_override("panel", slot_style)
	add_child(_skill_slot)

	# 청동검 아이콘 이미지
	var icon := TextureRect.new()
	icon.position     = Vector2(PAD, PAD)
	icon.size         = Vector2(SLOT - PAD * 2, SLOT - PAD * 2)
	icon.texture      = load("res://asset/Item/BronseSword.png")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_skill_slot.add_child(icon)

	# 부채꼴 오버레이
	_skill_arc = _SkillArc.new()
	_skill_arc.position = Vector2(PAD, PAD)
	_skill_arc.size     = Vector2(SLOT - PAD * 2, SLOT - PAD * 2)
	_skill_slot.add_child(_skill_arc)

	# 쿨타임 숫자 (오버레이 위)
	_skill_cd_label = Label.new()
	_skill_cd_label.position = Vector2(PAD, PAD)
	_skill_cd_label.size     = Vector2(SLOT - PAD * 2, SLOT - PAD * 2)
	_skill_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill_cd_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_skill_cd_label.add_theme_color_override("font_color", Color.WHITE)
	_skill_cd_label.add_theme_font_size_override("font_size", 14)
	_skill_cd_label.visible = false
	_skill_slot.add_child(_skill_cd_label)

	# 키 힌트
	var key_hint := Label.new()
	key_hint.text = "Q"
	key_hint.position = Vector2(SLOT - 14, SLOT - 15)
	key_hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.65))
	key_hint.add_theme_font_size_override("font_size", 9)
	_skill_slot.add_child(key_hint)


func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var cur: int = player.hp
	if cur != _last_hp:
		_last_hp = cur
		_update_display(cur, player.MAX_HP)

	_update_skill_ui()


func _update_display(cur: int, max_hp: int) -> void:
	hp_label.text = "%d / %d" % [cur, max_hp]
	hp_bar.max_value = max_hp

	if _hp_tween:
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(hp_bar, "value", float(cur), 0.25)

	var ratio := float(cur) / float(max_hp)
	var fill_style := hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		if ratio > 0.6:
			fill_style.bg_color = COLOR_HIGH
		elif ratio > 0.3:
			fill_style.bg_color = COLOR_MID
		else:
			fill_style.bg_color = COLOR_LOW


func _update_skill_ui() -> void:
	var has_sword: bool = player.has_bronze_sword
	if _skill_slot.visible != has_sword:
		_skill_slot.visible = has_sword

	if not has_sword:
		return

	var cd: float = player.sword_cooldown
	var new_ratio: float = cd / float(player.SWORD_COOLDOWN_TIME)

	if not is_equal_approx(_skill_arc.ratio, new_ratio):
		_skill_arc.ratio = new_ratio
		_skill_arc.queue_redraw()

	var show_cd := cd > 0.05
	if _skill_cd_label.visible != show_cd:
		_skill_cd_label.visible = show_cd
	if show_cd:
		_skill_cd_label.text = str(ceili(cd))


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

	# ── 캐릭터 이미지 ──────────────────────────────────────
	# 원하는 이미지 경로로 변경하세요
	const CHAR_IMG_PATH   := "res://asset/Background/gameover.png"
	const TARGET_HEIGHT   := 280.0   # 높이 기준값 (px) — 이 값만 바꾸면 크기 조절 가능

	var char_tex          := load(CHAR_IMG_PATH) as Texture2D
	var tex_size          := char_tex.get_size()
	var target_w          := tex_size.x * (TARGET_HEIGHT / tex_size.y)  # 비율 유지 너비 자동 계산

	var char_img          := TextureRect.new()
	char_img.texture              = char_tex
	char_img.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_img.expand_mode          = TextureRect.EXPAND_IGNORE_SIZE
	char_img.custom_minimum_size  = Vector2(target_w, TARGET_HEIGHT)
	char_img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(char_img)
	# ───────────────────────────────────────────────────────

	var sub = Label.new()
	sub.text = "체력이 모두 소진되었습니다"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	sub.add_theme_font_size_override("font_size", 22)
	vbox.add_child(sub)

	var btn_restart = Button.new()
	btn_restart.text = "처음부터 다시"
	btn_restart.custom_minimum_size = Vector2(220, 54)
	btn_restart.add_theme_font_size_override("font_size", 26)
	btn_restart.pressed.connect(_on_restart_pressed)
	vbox.add_child(btn_restart)

	var btn = Button.new()
	btn.text = "메인메뉴로"
	btn.custom_minimum_size = Vector2(220, 54)
	btn.add_theme_font_size_override("font_size", 26)
	btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(btn)


func _on_game_over() -> void:
	_game_over_panel.visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	if not get_tree().paused:
		return
	PlayerData.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/stage/stage1.tscn")

func _on_main_menu_pressed() -> void:
	if not get_tree().paused:
		return
	PlayerData.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
