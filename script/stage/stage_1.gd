extends Node2D

# 맵 경계 (타일 크기 × 타일 수로 계산)
@export var map_left: float = 0.0
@export var map_right: float = 3220.0
@export var map_top :float = -1000
@export var map_bottom: float =1050.0

@onready var player = $player
@onready var tilemap = $TileMap

func _ready() -> void:
	# TileMap 기반 자동 계산 (선택)
	_calc_map_bounds()
	
	# 플레이어에게 경계 전달
	player.set_bounds(map_left, map_right, map_top, map_bottom)

func _calc_map_bounds() -> void:
	var rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	map_left   = rect.position.x * tile_size.x
	map_right  = rect.end.x * tile_size.x
	map_top = rect.position.y * tile_size.y
	map_bottom = rect.end.y * tile_size.y + 400 #떨어지는 시간
