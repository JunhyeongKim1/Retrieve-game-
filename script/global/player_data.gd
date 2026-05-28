extends Node

# ── 스테이지 간 유지할 플레이어 데이터 ──────────────────
var has_bronze_sword: bool = false
var sword_cooldown: float = 0.0
var has_crown: bool = false
var has_fan_pendant: bool = false
var skill_w_cooldown: float = 0.0

var hp: int = 30
var max_hp: int = 30

# ── 저장 / 불러오기 ─────────────────────────────────────
func save_from_player(player: Node) -> void:
	has_bronze_sword = player.has_bronze_sword
	sword_cooldown   = player.sword_cooldown
	has_crown        = player.has_crown
	has_fan_pendant  = player.has_fan_pendant
	skill_w_cooldown = player.skill_w_cooldown
	hp               = player.hp

func load_to_player(player: Node) -> void:
	player.has_bronze_sword = has_bronze_sword
	player.sword_cooldown   = sword_cooldown
	player.has_crown        = has_crown
	player.has_fan_pendant  = has_fan_pendant
	player.skill_w_cooldown = skill_w_cooldown
	player.hp               = hp

func reset() -> void:
	has_bronze_sword = false
	sword_cooldown   = 0.0
	has_crown        = false
	has_fan_pendant  = false
	skill_w_cooldown = 0.0
	hp               = 30
