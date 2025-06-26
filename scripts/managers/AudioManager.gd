extends Node

## 音频管理器
## 处理游戏中的音频播放和管理

# 音频播放器节点
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# 音量设置
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

func _ready() -> void:
	"""初始化音频管理器"""
	setup_audio_players()

func setup_audio_players() -> void:
	"""设置音频播放器"""
	# 创建背景音乐播放器
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	add_child(music_player)
	
	# 创建音效播放器
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(sfx_player)

func play_background_music(audio_path: String) -> void:
	"""播放背景音乐"""
	var audio_stream = load(audio_path)
	if audio_stream and music_player:
		music_player.stream = audio_stream
		music_player.play()

func stop_background_music() -> void:
	"""停止背景音乐"""
	if music_player:
		music_player.stop()

func play_sfx(audio_path: String) -> void:
	"""播放音效"""
	var audio_stream = load(audio_path)
	if audio_stream and sfx_player:
		sfx_player.stream = audio_stream
		sfx_player.play()

func set_master_volume(volume: float) -> void:
	"""设置主音量"""
	master_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func set_music_volume(volume: float) -> void:
	"""设置音乐音量"""
	music_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func set_sfx_volume(volume: float) -> void:
	"""设置音效音量"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func update_volumes() -> void:
	"""更新所有音频播放器的音量"""
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	if sfx_player:
		sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
