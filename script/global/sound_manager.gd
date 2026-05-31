extends Node

# ── BGM (인스펙터에서 오디오 파일을 드래그&드롭으로 지정) ──
@export_group("BGM")
@export var bgm_main_menu: AudioStream
@export var bgm_stage1: AudioStream
@export var bgm_stage2: AudioStream
@export var bgm_stage3: AudioStream

# ── SFX ──────────────────────────────────────────────────
@export_group("SFX")
@export var sfx_jump:     AudioStream
@export var sfx_hit:      AudioStream
@export var sfx_item:     AudioStream
@export var sfx_portal:   AudioStream
@export var sfx_gameover: AudioStream

# ── SFX 풀 크기 ──────────────────────────────────────────	
const SFX_POOL_SIZE := 8

# ── 내부 노드 ────────────────────────────────────────────
var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0

# ── 볼륨 (0.0 ~ 1.0) ─────────────────────────────────────
var bgm_volume: float = 0.4 :
	set(v):
		bgm_volume = clamp(v, 0.0, 1.0)
		if _bgm_player:
			_bgm_player.volume_db = linear_to_db(bgm_volume)

var sfx_volume: float = 0.6 :
	set(v):
		sfx_volume = clamp(v, 0.0, 1.0)
		for p in _sfx_pool:
			p.volume_db = linear_to_db(sfx_volume)


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)


# BGM 끝나면 자동 루프
func _on_bgm_finished() -> void:
	if _bgm_player.stream != null:
		_bgm_player.play()


# ── BGM ──────────────────────────────────────────────────
func play_bgm(stream: AudioStream, restart: bool = false) -> void:
	if stream == null:
		push_warning("SoundManager: BGM 스트림이 null입니다. 인스펙터에서 파일을 지정해 주세요.")
		return

	if not restart and _bgm_player.playing and _bgm_player.stream == stream:
		return

	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume)
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stream = null
	_bgm_player.stop()


# ── SFX ──────────────────────────────────────────────────
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		push_warning("SoundManager: SFX 스트림이 null입니다. 인스펙터에서 파일을 지정해 주세요.")
		return

	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.play()
