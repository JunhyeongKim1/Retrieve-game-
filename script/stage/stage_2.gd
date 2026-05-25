extends Node2D

@export var map_left: float = 0.0
@export var map_right: float = 4800.0
@export var map_top: float = -500.0
@export var map_bottom: float = 850.0

@onready var player = $player
@onready var tilemap = $TileMap
@onready var portal = $Portal
@onready var item = $GiltbronzeCrown

func _ready() -> void:
	_calc_map_bounds()
	player.set_bounds(map_left, map_right, map_top, map_bottom)
	# 스테이지 2 전용: 수직 카메라 스크롤
	var cam = player.get_node("Camera2D")
	cam.limit_top = int(map_top)
	cam.limit_bottom = int(map_bottom)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_fall_death_y(map_bottom)
	portal.visible = false
	portal.monitoring = false

func _process(_delta: float) -> void:
	if not is_instance_valid(item) and not portal.visible:
		portal.visible = true
		portal.monitoring = true

func _calc_map_bounds() -> void:
	var rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	map_left   = rect.position.x * tile_size.x
	map_right  = rect.end.x * tile_size.x
	map_top    = rect.position.y * tile_size.y - 400
	map_bottom = rect.end.y * tile_size.y + 400
