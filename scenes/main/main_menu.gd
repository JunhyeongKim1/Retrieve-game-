extends Node2D

# ══════════════════════════════════════════════════════════
# 출처 내용 — 아래 항목을 채워주세요
# ══════════════════════════════════════════════════════════
const CREDITS: Array = [
	["배경음악", [
		"House In a Forest Loop  |  제작: [작성자]  |  출처: [링크]",
	]],
	["효과음", [
		"[효과음 이름]  |  출처: [링크]",
	]],
	["아트 에셋", [
		"[에셋 이름]  |  출처: [링크]",
		"[에셋 이름]  |  출처: [링크]",
	]],
	["제작", [
		"[이름]  |  [역할]",
		"[이름]  |  [역할]",
	]],
]
# ══════════════════════════════════════════════════════════

# 디자인 상수
const PANEL_W    := 380
const PANEL_H    := 720
const MARGIN_L   := 44
const BTN_W      := 292
const BTN_H      := 54
const BTN_GAP    := 12

# 색상 팔레트
const C_GOLD       := Color(1.00, 0.85, 0.28)
const C_GOLD_DIM   := Color(0.55, 0.42, 0.12, 0.70)
const C_GOLD_HOV   := Color(0.85, 0.68, 0.20, 0.90)
const C_GOLD_ACT   := Color(1.00, 0.85, 0.30, 1.00)
const C_PANEL_BG   := Color(0.04, 0.03, 0.07, 0.90)
const C_BTN_NOR    := Color(0.10, 0.08, 0.05, 0.80)
const C_BTN_HOV    := Color(0.20, 0.15, 0.07, 0.92)
const C_BTN_PRE    := Color(0.28, 0.20, 0.08, 0.97)
const C_SUBTITLE   := Color(0.72, 0.65, 0.52)
const C_VERSION    := Color(0.45, 0.42, 0.38, 0.70)
const C_TXT_NOR    := Color(0.92, 0.88, 0.80)
const C_TXT_HOV    := Color(1.00, 0.95, 0.75)
const C_OVERLAY    := Color(0.04, 0.04, 0.08, 0.94)

var _credits_layer: CanvasLayer
var _btn_start: Button


func _ready() -> void:
	_build_main_ui()
	_build_credits_panel()


# ══════════════════════════════════════════════════════════
# 메인 UI
# ══════════════════════════════════════════════════════════
func _build_main_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)

	# ── 왼쪽 반투명 패널 ──────────────────────────────────
	var panel := Panel.new()
	panel.position = Vector2.ZERO
	panel.size     = Vector2(PANEL_W, PANEL_H)

	var ps := StyleBoxFlat.new()
	ps.bg_color          = C_PANEL_BG
	ps.border_width_right = 1
	ps.border_color      = Color(C_GOLD_DIM.r, C_GOLD_DIM.g, C_GOLD_DIM.b, 0.40)
	panel.add_theme_stylebox_override("panel", ps)
	ui.add_child(panel)

	# ── 타이틀 ────────────────────────────────────────────
	var title := Label.new()
	title.text     = "Retrieve"
	title.position = Vector2(MARGIN_L, 168)
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_font_size_override("font_size", 72)
	panel.add_child(title)

	# ── 서브타이틀 ────────────────────────────────────────
	var subtitle := Label.new()
	subtitle.text     = "유물을 되찾아라"
	subtitle.position = Vector2(MARGIN_L + 4, 258)
	subtitle.add_theme_color_override("font_color", C_SUBTITLE)
	subtitle.add_theme_font_size_override("font_size", 15)
	panel.add_child(subtitle)

	# ── 장식 구분선 ───────────────────────────────────────
	var line := ColorRect.new()
	line.position = Vector2(MARGIN_L, 293)
	line.size     = Vector2(BTN_W, 1)
	line.color    = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	panel.add_child(line)

	# ── 버튼 3개 ──────────────────────────────────────────
	const Y0 := 326

	_btn_start = _make_button("게임 시작")
	_btn_start.position = Vector2(MARGIN_L, Y0)
	_btn_start.pressed.connect(_on_start_pressed)
	panel.add_child(_btn_start)

	var btn_credits := _make_button("출처")
	btn_credits.position = Vector2(MARGIN_L, Y0 + (BTN_H + BTN_GAP))
	btn_credits.pressed.connect(_on_credits_pressed)
	panel.add_child(btn_credits)

	var btn_quit := _make_button("게임 종료")
	btn_quit.position = Vector2(MARGIN_L, Y0 + 2 * (BTN_H + BTN_GAP))
	btn_quit.pressed.connect(_on_quit_pressed)
	panel.add_child(btn_quit)

	# ── 하단 버전 표기 ────────────────────────────────────
	var ver := Label.new()
	ver.text     = "© 2026  계명대학교"
	ver.position = Vector2(MARGIN_L, 696)
	ver.add_theme_color_override("font_color", C_VERSION)
	ver.add_theme_font_size_override("font_size", 11)
	panel.add_child(ver)


# ── 공통 버튼 팩토리 ──────────────────────────────────────
func _make_button(label: String) -> Button:
	var btn := Button.new()
	btn.text                = label
	btn.custom_minimum_size = Vector2(BTN_W, BTN_H)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color",         C_TXT_NOR)
	btn.add_theme_color_override("font_hover_color",   C_TXT_HOV)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	btn.add_theme_stylebox_override("normal",  _btn_style(C_BTN_NOR, C_GOLD_DIM))
	btn.add_theme_stylebox_override("hover",   _btn_style(C_BTN_HOV, C_GOLD_HOV))
	btn.add_theme_stylebox_override("pressed", _btn_style(C_BTN_PRE, C_GOLD_ACT))
	btn.add_theme_stylebox_override("focus",   _btn_style(C_BTN_NOR, C_GOLD_DIM))
	return btn


func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                    = bg
	s.border_width_left           = 1
	s.border_width_right          = 1
	s.border_width_top            = 1
	s.border_width_bottom         = 1
	s.border_color                = border
	s.corner_radius_top_left      = 3
	s.corner_radius_top_right     = 3
	s.corner_radius_bottom_left   = 3
	s.corner_radius_bottom_right  = 3
	return s


# ══════════════════════════════════════════════════════════
# 버튼 콜백
# ══════════════════════════════════════════════════════════
func _on_start_pressed() -> void:
	_btn_start.disabled = true
	get_tree().change_scene_to_file("res://scenes/story/intro.tscn")

func _on_credits_pressed() -> void:
	_credits_layer.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()


# ══════════════════════════════════════════════════════════
# 출처 패널
# ══════════════════════════════════════════════════════════
func _build_credits_panel() -> void:
	_credits_layer = CanvasLayer.new()
	_credits_layer.layer   = 10
	_credits_layer.visible = false
	add_child(_credits_layer)

	# 전체화면 오버레이
	var overlay := Panel.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ovs := StyleBoxFlat.new()
	ovs.bg_color = C_OVERLAY
	overlay.add_theme_stylebox_override("panel", ovs)
	_credits_layer.add_child(overlay)

	# 중앙 컨텐츠 박스
	var box := Panel.new()
	box.position = Vector2(240, 60)
	box.size     = Vector2(800, 600)
	var bs := StyleBoxFlat.new()
	bs.bg_color                   = Color(0.07, 0.06, 0.10, 0.98)
	bs.border_width_left          = 1
	bs.border_width_right         = 1
	bs.border_width_top           = 1
	bs.border_width_bottom        = 1
	bs.border_color               = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)
	bs.corner_radius_top_left     = 6
	bs.corner_radius_top_right    = 6
	bs.corner_radius_bottom_left  = 6
	bs.corner_radius_bottom_right = 6
	box.add_theme_stylebox_override("panel", bs)
	overlay.add_child(box)

	var margin := MarginContainer.new()
	margin.position = Vector2.ZERO
	margin.size     = Vector2(800, 600)
	margin.add_theme_constant_override("margin_left",   52)
	margin.add_theme_constant_override("margin_right",  52)
	margin.add_theme_constant_override("margin_top",    36)
	margin.add_theme_constant_override("margin_bottom", 36)
	box.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# 제목
	var cr_title := Label.new()
	cr_title.text                 = "출처"
	cr_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr_title.add_theme_color_override("font_color", C_GOLD)
	cr_title.add_theme_font_size_override("font_size", 38)
	vbox.add_child(cr_title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35))
	vbox.add_child(sep)

	# 섹션별 항목
	for entry in CREDITS:
		var section: String = entry[0]
		var items: Array    = entry[1]

		var sec_lbl := Label.new()
		sec_lbl.text = "■  " + section
		sec_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
		sec_lbl.add_theme_font_size_override("font_size", 17)
		vbox.add_child(sec_lbl)

		for item_text: String in items:
			var item_lbl := Label.new()
			item_lbl.text = "      • " + item_text
			item_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			item_lbl.add_theme_font_size_override("font_size", 14)
			vbox.add_child(item_lbl)

	# 닫기 버튼
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	var close_btn := _make_button("닫기")
	close_btn.custom_minimum_size    = Vector2(160, BTN_H)
	close_btn.size_flags_horizontal  = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void: _credits_layer.visible = false)
	vbox.add_child(close_btn)
