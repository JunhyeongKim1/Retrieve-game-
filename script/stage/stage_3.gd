extends Node2D

@export var map_left: float = 0.0
@export var map_right: float = 10000.0
@export var map_top: float = -2000.0
@export var map_bottom: float = 800.0

@onready var player = $player
@onready var tilemap = $TileMap
@onready var portal = $Portal
@onready var fan_pendant = $"Gilt-bronzeCrown"

func _ready() -> void:
	player.set_bounds(map_left, map_right, map_top, map_bottom)
	SoundManager.play_bgm(SoundManager.bgm_stage3)

	var cam = player.get_node("Camera2D")
	cam.limit_left   = int(map_left)
	cam.limit_right  = int(map_right)
	cam.limit_top    = int(map_top)
	cam.limit_bottom = int(map_bottom)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_fall_death_y(map_bottom)

	# 포탈은 pendant 획득 전까지 닫힘
	portal.visible = false
	portal.monitoring = false

	# fan_pendant 시그널 연결
	if fan_pendant:
		fan_pendant.collected.connect(_on_pendant_collected)


func _on_pendant_collected() -> void:
	portal.visible = true
	portal.monitoring = true


func _process(_delta: float) -> void:
	pass


func _calc_map_bounds() -> void:
	var rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	var tm = tilemap.global_position
	map_left   = tm.x + rect.position.x * tile_size.x
	map_right  = tm.x + rect.end.x * tile_size.x
	map_top    = tm.y + rect.position.y * tile_size.y
	map_bottom = tm.y + rect.end.y * tile_size.y +200
