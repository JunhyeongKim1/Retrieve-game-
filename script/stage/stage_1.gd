extends Node2D

# 맵 경계 (타일 크기 × 타일 수로 계산)
@export var map_left: float = 0.0
@export var map_right: float = 3220.0
@export var map_top :float = -1000
@export var map_bottom: float =1050.0


@onready var player = $player
@onready var tilemap = $TileMap
@onready var skill1_label = $HUD/skill1
@onready var bronsesword = $BronseSword
@onready var portal = $Portal

func _ready() -> void:
	_calc_map_bounds()
	player.set_bounds(map_left, map_right, map_top, map_bottom)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_fall_death_y(map_bottom)
	portal.visible = false
	portal.monitoring = false

func _calc_map_bounds() -> void:
	var rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	map_left   = rect.position.x * tile_size.x
	map_right  = rect.end.x * tile_size.x
	map_top = rect.position.y * tile_size.y
	map_bottom = rect.end.y * tile_size.y + 400

func _process(_delta: float) -> void:
	var sword1_done = not is_instance_valid(bronsesword)
	if sword1_done:
		skill1_label.visible = true
		portal.visible = true
		portal.monitoring = true
