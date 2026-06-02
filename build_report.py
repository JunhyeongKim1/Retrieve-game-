
# -*- coding: utf-8 -*-
"""
Retrieve 최종보고서 — 수정본 생성 스크립트
수정 사항:
  1. HW 스펙 추가 (개발 환경)
  2. 씬 흐름도 → 다이어그램(화살표)으로 시각화
  3. 파일 구성도 → 트리 형태로 시각화
  4. 클래스 상속 구조 → 계층 다이어그램으로 시각화
  5. UI/UX 실제 화면 이미지 슬롯 (이미지 파일 있으면 삽입)
"""

import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak, Image, KeepTogether
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Polygon, Circle
from reportlab.graphics import renderPDF

# ── 폰트 등록 ──────────────────────────────────────────────
pdfmetrics.registerFont(TTFont("Malgun", r"C:\Windows\Fonts\malgun.ttf"))
pdfmetrics.registerFont(TTFont("MalgunBold", r"C:\Windows\Fonts\malgunbd.ttf"))

W, H = A4  # 595 x 842 pt

# ── 스타일 ─────────────────────────────────────────────────
def make_styles():
    s = {}
    base = dict(fontName="Malgun", leading=16)
    bold = dict(fontName="MalgunBold")

    s["title"]    = ParagraphStyle("title",    **bold,  fontSize=22, alignment=TA_CENTER, spaceAfter=4, leading=28)
    s["subtitle"] = ParagraphStyle("subtitle", **base,  fontSize=13, alignment=TA_CENTER, spaceAfter=2)
    s["meta"]     = ParagraphStyle("meta",     **base,  fontSize=10, alignment=TA_CENTER, spaceAfter=2, textColor=colors.HexColor("#555555"))
    s["h1"]       = ParagraphStyle("h1",       **bold,  fontSize=14, spaceBefore=14, spaceAfter=6, textColor=colors.HexColor("#1a1a6e"))
    s["h2"]       = ParagraphStyle("h2",       **bold,  fontSize=12, spaceBefore=10, spaceAfter=4, textColor=colors.HexColor("#2c2c8e"))
    s["body"]     = ParagraphStyle("body",     **base,  fontSize=10, spaceAfter=4)
    s["small"]    = ParagraphStyle("small",    **base,  fontSize=9,  textColor=colors.HexColor("#444444"))
    s["caption"]  = ParagraphStyle("caption",  **base,  fontSize=9,  alignment=TA_CENTER, textColor=colors.HexColor("#666666"), spaceAfter=6)
    s["bullet"]   = ParagraphStyle("bullet",   **base,  fontSize=10, leftIndent=12, spaceAfter=3, bulletIndent=4)
    s["code"]     = ParagraphStyle("code",     fontName="Courier", fontSize=8, leftIndent=12, spaceAfter=2, textColor=colors.HexColor("#333333"))
    return s

ST = make_styles()

# ── 테이블 공통 스타일 ─────────────────────────────────────
def tbl_style(header_color="#1a1a6e", row_colors=("#f0f0fa", "#ffffff")):
    return TableStyle([
        ("BACKGROUND",  (0,0), (-1,0),  colors.HexColor(header_color)),
        ("TEXTCOLOR",   (0,0), (-1,0),  colors.white),
        ("FONTNAME",    (0,0), (-1,0),  "MalgunBold"),
        ("FONTSIZE",    (0,0), (-1,0),  10),
        ("ALIGN",       (0,0), (-1,-1), "LEFT"),
        ("VALIGN",      (0,0), (-1,-1), "MIDDLE"),
        ("FONTNAME",    (0,1), (-1,-1), "Malgun"),
        ("FONTSIZE",    (0,1), (-1,-1), 9),
        ("ROWBACKGROUNDS",(0,1),(-1,-1), [colors.HexColor(c) for c in row_colors]),
        ("GRID",        (0,0), (-1,-1), 0.4, colors.HexColor("#cccccc")),
        ("LEFTPADDING",  (0,0),(-1,-1), 6),
        ("RIGHTPADDING", (0,0),(-1,-1), 6),
        ("TOPPADDING",   (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
    ])

# ── 씬 흐름도 다이어그램 ────────────────────────────────────
def make_scene_flow_diagram():
    """가로 흐름: 메인메뉴 → 인트로 → Stage1 → Stage2 → Stage3 → 엔딩"""
    dw, dh = 480, 90
    d = Drawing(dw, dh)

    nodes = [
        ("메인\n메뉴",  30),
        ("인트로",     110),
        ("Stage 1",   190),
        ("Stage 2",   270),
        ("Stage 3",   350),
        ("엔  딩",    430),
    ]
    box_w, box_h = 60, 36
    cy = dh / 2

    BOX_COLOR   = colors.HexColor("#1a1a6e")
    ARROW_COLOR = colors.HexColor("#555555")
    TEXT_COLOR  = colors.white

    for label, cx in nodes:
        # 박스
        d.add(Rect(cx - box_w/2, cy - box_h/2, box_w, box_h,
                   fillColor=BOX_COLOR, strokeColor=colors.HexColor("#0a0a4e"), strokeWidth=1))
        # 텍스트 (줄바꿈 처리)
        lines = label.split("\n")
        for li, ln in enumerate(lines):
            yo = cy + 6 - li * 14 if len(lines) > 1 else cy + 4
            d.add(String(cx, yo, ln, fontName="Malgun", fontSize=9,
                         fillColor=TEXT_COLOR, textAnchor="middle"))

    # 화살표
    for i in range(len(nodes) - 1):
        cx1 = nodes[i][1]   + box_w/2
        cx2 = nodes[i+1][1] - box_w/2
        mx  = (cx1 + cx2) / 2
        # 선
        d.add(Line(cx1, cy, cx2 - 6, cy,
                   strokeColor=ARROW_COLOR, strokeWidth=1.5))
        # 화살표 머리
        d.add(Polygon([cx2-6, cy+4, cx2, cy, cx2-6, cy-4],
                      fillColor=ARROW_COLOR, strokeColor=ARROW_COLOR, strokeWidth=0))

    return d

# ── 파일 구성 트리 다이어그램 ──────────────────────────────
def make_file_tree_diagram():
    """Godot 프로젝트 파일 트리를 시각적으로 표현"""
    dw, dh = 500, 340
    d = Drawing(dw, dh)

    FOLDER_CLR = colors.HexColor("#1a1a6e")
    FILE_CLR   = colors.HexColor("#3a5a9e")
    LINE_CLR   = colors.HexColor("#888888")
    TXT_CLR    = colors.HexColor("#111111")

    entries = [
        # (depth, label, is_folder)
        (0, "Retrieve-game-/  [프로젝트 루트]", True),
        (1, "scenes/", True),
        (2, "main/  → main_menu.tscn", False),
        (2, "stage/ → stage1~3.tscn, portal.tscn, MovingPlatform.tscn", False),
        (2, "story/ → intro.tscn, ending.tscn", False),
        (2, "player/ → player.tscn", False),
        (2, "enemy/ → Enemy.tscn, BlueSlime.tscn, RedSlime.tscn, RangedEnemy.tscn, Bullet.tscn", False),
        (2, "items/ → BaseItem.tscn, Bronze_sword.tscn, Gilt_bronze_crown.tscn, fan_pendant.tscn", False),
        (2, "ui/    → hud.tscn, ItemPopup.tscn, GameOverPanel.tscn", False),
        (2, "global/→ SoundManager.tscn", False),
        (1, "script/", True),
        (2, "player.gd, player_data.gd (Autoload)", False),
        (2, "stage_1~3.gd, portal.gd, scene_transition.gd, moving_platform.gd", False),
        (2, "enemy.gd, blue_slime.gd, red_slime.gd, ranged_enemy.gd, bullet.gd", False),
        (2, "BaseItem.gd, bronze_sword.gd, gilt_bronze_crown.gd, fan_pendant.gd", False),
        (2, "hud.gd, item_popup.gd, sound_manager.gd (Autoload)", False),
        (1, "asset/  [스프라이트, 타일셋, 사운드 파일]", True),
        (1, "project.godot  [엔진 설정 파일]", False),
    ]

    row_h = 17
    start_y = dh - 20
    indent_w = 18

    for i, (depth, label, is_folder) in enumerate(entries):
        y = start_y - i * row_h
        x = 10 + depth * indent_w

        # 세로 연결선 (depth > 0)
        if depth > 0:
            d.add(Line(x - indent_w + 8, y + row_h/2, x - indent_w + 8, y,
                       strokeColor=LINE_CLR, strokeWidth=0.8))
            d.add(Line(x - indent_w + 8, y, x - 2, y,
                       strokeColor=LINE_CLR, strokeWidth=0.8))

        # 아이콘
        icon_clr = FOLDER_CLR if is_folder else FILE_CLR
        d.add(Rect(x, y - 5, 8, 8, fillColor=icon_clr, strokeColor=None))

        # 텍스트
        fs = 8.5 if depth == 0 else 8
        fw = "MalgunBold" if is_folder else "Malgun"
        d.add(String(x + 12, y - 4, label, fontName=fw, fontSize=fs,
                     fillColor=TXT_CLR))

    return d

# ── 클래스 상속 다이어그램 ─────────────────────────────────
def make_class_diagram():
    """상속 계층 트리 다이어그램"""
    dw, dh = 500, 210
    d = Drawing(dw, dh)

    BASE_CLR  = colors.HexColor("#1a1a6e")
    CHILD_CLR = colors.HexColor("#2c5f9e")
    LEAF_CLR  = colors.HexColor("#4a7fbe")
    LINE_CLR  = colors.HexColor("#555555")
    TXT_W     = colors.white

    bw, bh = 110, 26
    gap_y   = 50

    def box(cx, cy, label, clr, bold=False):
        d.add(Rect(cx - bw/2, cy - bh/2, bw, bh,
                   fillColor=clr, strokeColor=colors.HexColor("#0a0a3e"), strokeWidth=0.8))
        fn = "MalgunBold" if bold else "Malgun"
        d.add(String(cx, cy - 4, label, fontName=fn, fontSize=8.5,
                     fillColor=TXT_W, textAnchor="middle"))

    def arrow(x1, y1, x2, y2):
        d.add(Line(x1, y1, x2, y2, strokeColor=LINE_CLR, strokeWidth=1.2))
        # 화살표 머리 (위쪽 향함)
        dx, dy = x2 - x1, y2 - y1
        length = (dx**2 + dy**2) ** 0.5
        ux, uy = dx/length, dy/length
        px, py = -uy, ux
        d.add(Polygon([x2, y2,
                       x2 - ux*7 + px*4, y2 - uy*7 + py*4,
                       x2 - ux*7 - px*4, y2 - uy*7 - py*4],
                      fillColor=LINE_CLR, strokeColor=LINE_CLR))

    top_y = dh - 30

    # ── CharacterBody2D 계열 ──
    # BaseEnemy
    box(130, top_y, "BaseEnemy", BASE_CLR, bold=True)
    # SlimeEnemy
    box(75, top_y - gap_y, "SlimeEnemy", CHILD_CLR)
    arrow(100, top_y - bh/2, 85, top_y - gap_y + bh/2)
    # BlueSlime, RedSlime
    box(35,  top_y - gap_y*2, "BlueSlime",  LEAF_CLR)
    box(115, top_y - gap_y*2, "RedSlime",   LEAF_CLR)
    arrow(55, top_y - gap_y - bh/2, 45,  top_y - gap_y*2 + bh/2)
    arrow(90, top_y - gap_y - bh/2, 105, top_y - gap_y*2 + bh/2)
    # RangedEnemy
    box(185, top_y - gap_y, "RangedEnemy", CHILD_CLR)
    arrow(155, top_y - bh/2, 175, top_y - gap_y + bh/2)

    # BaseItem
    box(370, top_y, "BaseItem", BASE_CLR, bold=True)
    box(290, top_y - gap_y, "BronzeSword",      CHILD_CLR)
    box(370, top_y - gap_y, "GiltbronzeCrown",  CHILD_CLR)
    box(450, top_y - gap_y, "FanPendant",       CHILD_CLR)
    arrow(350, top_y - bh/2, 305, top_y - gap_y + bh/2)
    arrow(370, top_y - bh/2, 370, top_y - gap_y + bh/2)
    arrow(390, top_y - bh/2, 435, top_y - gap_y + bh/2)

    # Player (CharacterBody2D)
    box(130, top_y - gap_y*3 + 10, "Player\n(CharacterBody2D)", BASE_CLR, bold=True)

    # Node 계열
    box(370, top_y - gap_y*2, "SoundManager\n(Autoload)", CHILD_CLR)
    box(450, top_y - gap_y*3 + 10, "PlayerData\n(Autoload)", CHILD_CLR)

    # 레이블
    d.add(String(10, dh - 10, "Godot 클래스 상속 구조", fontName="MalgunBold",
                 fontSize=9, fillColor=colors.HexColor("#1a1a6e")))

    return d

# ── 구분선 ────────────────────────────────────────────────
def hr():
    return HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#cccccc"), spaceAfter=6)

# ── 본문 조합 ──────────────────────────────────────────────
def build_story(img_dir):
    story = []
    SP = lambda n=6: Spacer(1, n)

    # ════════════════════════════════════════════
    # 표지
    # ════════════════════════════════════════════
    story += [
        SP(60),
        Paragraph("개인 프로젝트 최종 보고서", ST["title"]),
        SP(10),
        Paragraph("Retrieve", ParagraphStyle("big", fontName="MalgunBold", fontSize=32,
                  alignment=TA_CENTER, textColor=colors.HexColor("#1a1a6e"), leading=38)),
        SP(8),
        Paragraph("잃어버린 유물을 되찾는 2D 플랫포머 게임", ST["subtitle"]),
        SP(30),
    ]

    meta = [
        ["개발 도구",  "Godot 4 / GDScript"],
        ["개발 기간",  "2026.04.01 ~ 2026.05.31"],
        ["소스코드",   "https://github.com/JunhyeongKim1/Retrieve-game-"],
        ["시연 영상",  "https://youtu.be/961TFhMLXEA"],
    ]
    mt = Table(meta, colWidths=[80, 330])
    mt.setStyle(TableStyle([
        ("FONTNAME",  (0,0),(-1,-1), "Malgun"),
        ("FONTNAME",  (0,0),(0,-1),  "MalgunBold"),
        ("FONTSIZE",  (0,0),(-1,-1), 10),
        ("ALIGN",     (0,0),(0,-1),  "RIGHT"),
        ("ALIGN",     (1,0),(-1,-1), "LEFT"),
        ("TOPPADDING",(0,0),(-1,-1), 5),
        ("BOTTOMPADDING",(0,0),(-1,-1), 5),
        ("LINEBELOW", (0,-1),(-1,-1), 0.5, colors.HexColor("#aaaaaa")),
    ]))
    story += [mt, PageBreak()]

    # ════════════════════════════════════════════
    # 1. 프로젝트 개요
    # ════════════════════════════════════════════
    story += [Paragraph("1. 프로젝트 개요", ST["h1"]), hr()]

    story += [Paragraph("▶ 1-1. 작품 주제 선정 배경", ST["h2"])]
    story += [Paragraph(
        "본 프로젝트는 계명대학교 행소박물관에 소장된 실제 유물(청동검, 금동관, 노리개)을 소재로 한 2D "
        "플랫포머 게임입니다. 유물의 역사적·문화적 가치를 게임 콘텐츠와 결합하여, 플레이어가 자연스럽게 "
        "유물에 대한 정보를 습득할 수 있도록 기획했습니다.", ST["body"]),
        Paragraph(
        "게임의 줄거리는 몬스터들에게 빼앗긴 유물을 되찾는 여정으로 구성되며, 각 유물을 획득하면 고유 "
        "능력이 해금되어 게임플레이에 직접 영향을 줍니다.", ST["body"]),
        SP(),
    ]

    story += [Paragraph("▶ 1-2. 벤치마킹 자료", ST["h2"])]
    bench = [
        ["벤치마킹 대상", "참고 요소"],
        ["슈퍼 마리오 시리즈", "플랫포머 기본 구조, 맵 설계, 아이템 능력 시스템"],
        ["Celeste", "Coyote Time, Jump Buffer 등 정밀한 점프 조작감"],
        ["Hollow Knight", "에너미 패턴 설계, 스테이지 분위기 및 보스 구성 참고"],
        ["Godot 공식 문서", "CharacterBody2D, TileMap, ParallaxBackground 구현"],
    ]
    bt = Table(bench, colWidths=[130, 330])
    bt.setStyle(tbl_style())
    story += [bt, SP()]

    # ── 1-3. 개발 환경 (HW 스펙 포함) ──
    story += [Paragraph("▶ 1-3. 개발 환경", ST["h2"])]

    # SW 환경
    story += [Paragraph("■ 소프트웨어 환경", ParagraphStyle("sh", fontName="MalgunBold", fontSize=10, spaceAfter=3))]
    sw_data = [
        ["항목", "내용"],
        ["게임 엔진",  "Godot 4.x"],
        ["언어",      "GDScript"],
        ["IDE",       "Godot 내장 편집기 + VS Code (Claude Code)"],
        ["버전 관리",  "Git / GitHub"],
        ["그래픽 에셋","직접 제작 및 공개 라이선스 에셋 활용"],
        ["사운드 에셋","공개 라이선스 WAV / MP3 파일"],
        ["운영체제",   "Windows 11 Pro"],
        ["기타",      "Python 3 (reportlab — 보고서 생성)"],
    ]
    swt = Table(sw_data, colWidths=[100, 360])
    swt.setStyle(tbl_style())
    story += [swt, SP(8)]

    # HW 환경 (신규 추가)
    story += [Paragraph("■ 하드웨어(개발 PC) 환경", ParagraphStyle("sh", fontName="MalgunBold", fontSize=10, spaceAfter=3))]
    hw_data = [
        ["항목", "사양"],
        ["CPU",  "Intel Core i7-11800H @ 2.30GHz (11세대, 8코어 16스레드)"],
        ["RAM",  "16 GB DDR4"],
        ["GPU",  "Intel UHD Graphics (내장 그래픽)"],
        ["OS",   "Microsoft Windows 11 Pro (64-bit)"],
        ["저장장치", "NVMe SSD (권장 여유 공간: 2 GB 이상)"],
    ]
    hwt = Table(hw_data, colWidths=[100, 360])
    hwt.setStyle(tbl_style(header_color="#2c5f2e"))
    story += [hwt, PageBreak()]

    # ════════════════════════════════════════════
    # 2. 개발 프로그램 설명
    # ════════════════════════════════════════════
    story += [Paragraph("2. 개발 프로그램 설명", ST["h1"]), hr()]

    # ── 2-1. 씬 흐름도 ──
    story += [Paragraph("▶ 2-1. 씬 흐름도", ST["h2"])]
    story += [Paragraph("아래 다이어그램은 게임의 씬 전환 흐름을 나타냅니다.", ST["body"])]
    story += [renderPDF.GraphicsFlowable(make_scene_flow_diagram()), SP(4)]
    story += [Paragraph("[ 그림 1 ] 씬 전환 흐름도", ST["caption"])]

    flow_detail = [
        ["씬 파일 경로", "전환 조건"],
        ["scenes/main/main_menu.tscn",  "시작 버튼 클릭"],
        ["scenes/story/intro.tscn",     "스토리 페이지 완료"],
        ["scenes/stage/stage1.tscn",    "청동검 수집 후 포탈 입장"],
        ["scenes/stage/stage2.tscn",    "금동관 수집 후 포탈 입장"],
        ["scenes/stage/stage_3.tscn",   "노리개 수집 후 포탈 입장"],
        ["scenes/story/ending.tscn",    "엔딩 페이지 완료"],
    ]
    fdt = Table(flow_detail, colWidths=[260, 200])
    fdt.setStyle(tbl_style())
    story += [fdt, SP()]

    # ── 2-2. 파일 구성도 ──
    story += [Paragraph("▶ 2-2. 파일 구성도", ST["h2"])]
    story += [Paragraph("아래 트리 다이어그램은 프로젝트의 디렉터리 및 주요 파일 구조를 나타냅니다.", ST["body"])]
    story += [renderPDF.GraphicsFlowable(make_file_tree_diagram()), SP(4)]
    story += [Paragraph("[ 그림 2 ] 프로젝트 파일 구성 트리", ST["caption"])]

    # ── 2-3. 클래스 상속 구조 ──
    story += [Paragraph("▶ 2-3. 클래스 상속 구조", ST["h2"])]
    story += [Paragraph("Godot Node를 베이스로 하는 주요 클래스 상속 계층 다이어그램입니다.", ST["body"])]
    story += [renderPDF.GraphicsFlowable(make_class_diagram()), SP(4)]
    story += [Paragraph("[ 그림 3 ] 클래스 상속 구조 다이어그램", ST["caption"])]

    def P(text, bold=False):
        """표 셀용 Paragraph — \n을 <br/>로 변환"""
        fn = "MalgunBold" if bold else "Malgun"
        st = ParagraphStyle("cell", fontName=fn, fontSize=9, leading=13,
                            leftPadding=0, rightPadding=0)
        return Paragraph(text.replace("\n", "<br/>"), st)

    cls_tbl = [
        [P("베이스 클래스", bold=True), P("자식 클래스", bold=True), P("주요 오버라이드 / 추가 기능", bold=True)],
        [P("BaseEnemy\n(CharacterBody2D)"),
         P("SlimeEnemy (blue_slime.gd)\nRangedEnemy (ranged_enemy.gd)"),
         P("_update_animation()\n_physics_process() — 사격")],
        [P("SlimeEnemy"),
         P("RedSlimeEnemy (red_slime.gd)"),
         P("_process_chase() — 점프 추격")],
        [P("BaseItem\n(Area2D)"),
         P("BronzeSword\nGiltbronzeCrown\nFanPendant"),
         P("_apply_effect(player)\ncollected signal (FanPendant 전용)")],
        [P("CharacterBody2D"),
         P("Player"),
         P("Coyote Time / Jump Buffer\ntake_damage(), set_bounds()")],
        [P("Node"),
         P("SoundManager (Autoload)\nPlayerData (Autoload)"),
         P("BGM 루프 재생, SFX 풀 관리\n스테이지 간 데이터 유지")],
    ]
    ct = Table(cls_tbl, colWidths=[130, 160, 180])
    ct.setStyle(tbl_style())
    story += [ct, SP()]

    # ── 2-4. UI/UX 설계 ──
    story += [Paragraph("▶ 2-4. UI/UX 설계", ST["h2"])]
    story += [Paragraph(
        "플레이어 인터페이스는 HUD(hud.gd)를 통해 화면 상단에 HP 바와 스킬 슬롯을 표시합니다. "
        "아이템 획득 시 팝업(ItemPopup)이 표시되며 게임이 일시정지되고, 1초 경과 후 Space 키로 닫을 수 있습니다. "
        "게임오버 시 반투명 오버레이와 함께 재시작/메인메뉴 버튼이 표시됩니다.", ST["body"])]

    ui_tbl = [
        ["UI 요소", "위치", "설명"],
        ["HP 바",          "좌측 상단",    "현재 HP / 최대 HP 표시, 피격 시 색상 변화"],
        ["스킬 슬롯 Q",    "하단 중앙",    "청동검 스킬 아이콘 + 쿨타임 부채꼴 오버레이"],
        ["스킬 슬롯 W",    "하단 중앙 우측","노리개 스킬 아이콘 + 쿨타임 오버레이"],
        ["아이템 팝업",    "화면 중앙",    "유물 이름/설명/아이콘 표시, 1초 후 Space로 닫기"],
        ["게임오버 패널",  "전체 화면",    "GAME OVER 텍스트, 재시작 / 메인메뉴 버튼"],
    ]
    uit = Table(ui_tbl, colWidths=[100, 100, 270])
    uit.setStyle(tbl_style())
    story += [uit, SP(8)]

    # 실제 화면 이미지 슬롯 (2열 레이아웃)
    story += [Paragraph("■ 실제 화면 구조", ParagraphStyle("sh", fontName="MalgunBold", fontSize=10, spaceAfter=6))]

    img_names = [
        ("screenshot_mainmenu.png",  "메인 메뉴 화면"),
        ("screenshot_stage.png",     "인게임 화면 (Stage)"),
        ("screenshot_item_popup.png","아이템 획득 팝업 화면"),
        ("screenshot_gameover.png",  "게임오버 화면"),
    ]

    IMG_W, IMG_H = 440, 260  # 이미지 크기
    CAP_STYLE = ParagraphStyle("cap2", fontName="Malgun", fontSize=9,
                               alignment=TA_CENTER, textColor=colors.HexColor("#555555"), leading=13)

    def make_cell(fname, caption):
        fpath = os.path.join(img_dir, fname)
        if os.path.exists(fpath):
            img = Image(fpath, width=IMG_W, height=IMG_H)
        else:
            img = Table(
                [[Paragraph(f"[ {caption} ]\n파일 없음: {fname}",
                            ParagraphStyle("ph2", fontName="Malgun", fontSize=8,
                                           alignment=TA_CENTER, textColor=colors.HexColor("#aaaaaa")))]],
                colWidths=[IMG_W], rowHeights=[IMG_H]
            )
            img.setStyle(TableStyle([
                ("BOX",        (0,0),(-1,-1), 1, colors.HexColor("#dddddd")),
                ("BACKGROUND", (0,0),(-1,-1), colors.HexColor("#f5f5f5")),
                ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
            ]))
        cap = Paragraph(caption, CAP_STYLE)
        return [img, cap]

    # 2개씩 한 페이지, 세로로 배치
    for i in range(0, len(img_names), 2):
        for j in range(2):
            if i + j >= len(img_names):
                break
            cell = make_cell(*img_names[i + j])
            story += [cell[0], cell[1], SP(20)]
        if i + 2 < len(img_names):
            story.append(PageBreak())

    story += [PageBreak()]

    # ════════════════════════════════════════════
    # 3. 테스트 및 검증
    # ════════════════════════════════════════════
    story += [Paragraph("3. 테스트 및 검증 · 장애요인과 문제 해결", ST["h1"]), hr()]

    story += [Paragraph("▶ 3-1. 주요 버그 및 해결 과정", ST["h2"])]
    bug_tbl = [
        [P("버그 / 장애요인", bold=True), P("원인", bold=True), P("해결 방법", bold=True)],
        [P("Stage 3 시작 즉사"),
         P("_calc_map_bounds()가 TileMap 로컬 좌표로 map_bottom을 계산하여 플레이어 시작 Y(580)보다 작은 값이 산출됨"),
         P("_calc_map_bounds() 호출 제거 후 @export 기본값(map_bottom=1000) 사용")],
        [P("Stage 3 카메라 범위 초과"),
         P("cam.limit_left / limit_right 미설정으로 수평 스크롤 제한 없음"),
         P("_ready()에서 4방향 limit 모두 설정")],
        [P("fanpendant UI 미표시"),
         P("hud.gd에서 fanpendant.png(잘못된 파일) 로드 및 expand_mode 충돌"),
         P("fanpendant_museum.png로 교체, custom_minimum_size 명시")],
        [P("RangedEnemy 탄환 충돌 미작동"),
         P("Bullet의 collision_layer/mask가 플레이어 레이어와 불일치"),
         P("Bullet collision_mask=4 (플레이어 레이어) 설정")],
        [P("BGM 루프 미작동"),
         P("AudioStreamPlayer의 finished 시그널 미연결"),
         P("SoundManager._ready()에서 finished.connect(_on_bgm_finished) 연결")],
        [P("아이템 팝업 즉시 닫힘"),
         P("_input에서 is_action_just_pressed 미지원 이벤트 타입 오류"),
         P("is_action_pressed + not is_echo() 조합으로 변경, 1초 딜레이 추가")],
    ]
    bgt = Table(bug_tbl, colWidths=[130, 180, 160])
    bgt.setStyle(tbl_style())
    story += [bgt, SP()]

    story += [Paragraph("▶ 3-2. 테스트 항목", ST["h2"])]
    test_tbl = [
        ["테스트 항목", "결과"],
        ["메인메뉴 → 인트로 → Stage1 → Stage2 → Stage3 → 엔딩 전체 흐름", "✅ 정상"],
        ["플레이어 점프 (일반 / Coyote / Double / Jump Buffer)", "✅ 정상"],
        ["에너미 3종 AI (순찰 / 추격 / 공포 / 사망)", "✅ 정상"],
        ["아이템 3종 획득 및 능력 적용 (청동검 Q, 금동관 더블점프, 노리개 W)", "✅ 정상"],
        ["Stage3 포탈 — pendant 획득 후 개방", "✅ 정상"],
        ["게임오버 → 재시작(Stage1) / 메인메뉴 이동", "✅ 정상"],
        ["BGM 스테이지별 재생 및 루프, 게임오버 시 정지", "✅ 정상"],
        ["SFX (점프, 피격, 아이템, 포탈, 게임오버)", "✅ 정상"],
    ]
    tt = Table(test_tbl, colWidths=[380, 80])
    tt.setStyle(tbl_style())
    story += [tt, PageBreak()]

    # ════════════════════════════════════════════
    # 4. 성과 및 결론
    # ════════════════════════════════════════════
    story += [Paragraph("4. 성과 및 결론", ST["h1"]), hr()]

    story += [Paragraph("▶ 4-1. 기대효과 및 활용방안", ST["h2"])]
    story += [Paragraph(
        "본 게임은 계명대학교 행소박물관의 실제 소장 유물을 소재로 하여, 플레이어가 게임을 진행하면서 "
        "자연스럽게 유물의 역사적 배경과 특징을 접할 수 있습니다.", ST["body"])]
    for item in [
        "박물관 교육 콘텐츠로 활용 가능 (초·중학생 대상 게임형 전시 연계)",
        "지역 문화재 홍보 수단으로 활용 가능",
        "향후 유물 종류 확장 및 멀티플레이 기능 추가를 통한 서비스 확장 가능",
    ]:
        story.append(Paragraph(f"• {item}", ST["bullet"]))
    story += [SP()]

    story += [Paragraph("▶ 4-2. 프로젝트 성과", ST["h2"])]
    for item in [
        "Godot 4 엔진을 활용한 완성도 있는 2D 플랫포머 게임 개발",
        "상속 기반 에너미 시스템 구축 (BaseEnemy → SlimeEnemy → RedSlimeEnemy, BaseEnemy → RangedEnemy)",
        "오토로드 싱글톤 패턴으로 전역 데이터(PlayerData, SoundManager) 관리",
        "씬 전환, 카메라 제한, 패럴랙스 배경 등 게임 엔진 핵심 기능 구현",
        "원거리 공격 에너미, 이동 플랫폼 등 다양한 게임플레이 요소 구현",
    ]:
        story.append(Paragraph(f"• {item}", ST["bullet"]))
    story += [SP()]

    story += [Paragraph("▶ 4-3. 후기", ST["h2"])]
    story += [Paragraph(
        "이번 프로젝트에서 가장 중요하게 생각한 것은 내가 가진 능력을 적극적으로 활용하는 것이었습니다. "
        "이전 수업에서 싱글톤 패턴 기반의 게임 엔진을 직접 설계하고 구현한 경험, 그리고 게임을 기획했던 "
        "경험을 살려 시스템 구조 설계부터 기능 구현까지 일관된 방향으로 프로젝트를 이끌어 나갈 수 있었습니다. "
        "이 과정을 통해 그동안 쌓아온 경험이 실제 프로젝트에서 어떻게 가치를 발휘하는지 직접 체감할 수 있었습니다. "
        "앞으로도 배운 것들을 필요한 순간에 꺼내어 쓸 수 있는 역량으로 발전시켜 나가고 싶습니다.", ST["body"]),
        PageBreak()]

    # ════════════════════════════════════════════
    # 5. 참고문헌
    # ════════════════════════════════════════════
    story += [Paragraph("5. 참고문헌", ST["h1"]), hr()]

    refs = {
        "▶ 개발 문서": [
            "Godot Engine 공식 문서 — https://docs.godotengine.org",
            "GDScript 레퍼런스 — https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/",
        ],
        "▶ 그래픽 에셋": ["Kenney Assets — https://kenney.nl/assets"],
        "▶ 사운드 에셋": ["Freesound — https://freesound.org"],
        "▶ 벤치마킹": [
            "Super Mario Bros. — Nintendo",
            "Celeste — Maddy Makes Games",
            "Hollow Knight — Team Cherry",
        ],
    }
    for heading, items in refs.items():
        story.append(Paragraph(heading, ST["h2"]))
        for item in items:
            story.append(Paragraph(f"• {item}", ST["bullet"]))
        story.append(SP(4))

    return story


# ── 메인 ──────────────────────────────────────────────────
if __name__ == "__main__":
    BASE = r"C:\2026_2Dgame\Retrieve-game-"
    IMG_DIR = os.path.join(BASE, "screenshots")
    OUT = os.path.join(BASE, "Retrieve_최종보고서_수정본.pdf")

    os.makedirs(IMG_DIR, exist_ok=True)

    doc = SimpleDocTemplate(
        OUT, pagesize=A4,
        leftMargin=20*mm, rightMargin=20*mm,
        topMargin=20*mm, bottomMargin=20*mm,
    )
    doc.build(build_story(IMG_DIR))
    print("완료: " + OUT)
