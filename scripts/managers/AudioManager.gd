extends Node

## 音频管理器
## 处理桌面宠物的音频播放

# 音频播放器节点
var sfx_player: AudioStreamPlayer

# 音量设置
var master_volume: float = 0.5

func _ready() -> void:
	"""初始化音频管理器"""
	setup_audio_players()

func setup_audio_players() -> void:
	"""设置音频播放器"""
	# 创建音效播放器
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.volume_db = linear_to_db(master_volume)
	add_child(sfx_player)

func play_sfx(audio_path: String) -> void:
	"""播放音效"""
	var audio_stream = load(audio_path)
	if audio_stream and sfx_player:
		sfx_player.stream = audio_stream
		sfx_player.play()

func set_master_volume(volume: float) -> void:
	"""设置主音量"""
	master_volume = clamp(volume, 0.0, 1.0)
	if sfx_player:
		sfx_player.volume_db = linear_to_db(master_volume)
