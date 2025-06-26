extends Node

## 陪伴管理器
## 处理游戏中的陪伴功能和情感交互

# 陪伴设置
var companion_name: String = "小伙伴"
var companion_mood: String = "开心"
var interaction_frequency: float = 1.0
var voice_enabled: bool = true
var companion_personality: String = "温和"

# 陪伴状态
var companion_level: int = 1
var friendship_points: int = 0
var last_interaction_time: float = 0.0

# 情绪状态枚举
enum MoodState {
	HAPPY,
	CALM,
	EXCITED,
	SLEEPY,
	CURIOUS
}

var current_mood: MoodState = MoodState.HAPPY

# 信号
signal companion_setting_changed(setting_name: String, value)
signal mood_changed(new_mood: MoodState)
signal friendship_level_up(new_level: int)

func _ready() -> void:
	"""初始化陪伴管理器"""
	load_companion_settings()
	# 延迟启动计时器，让游戏先完全加载
	call_deferred("start_companion_timer")

func load_companion_settings() -> void:
	"""加载陪伴设置"""
	# TODO: 从配置文件加载设置
	pass

func save_companion_settings() -> void:
	"""保存陪伴设置"""
	# TODO: 保存设置到配置文件
	pass

func start_companion_timer() -> void:
	"""启动陪伴互动计时器"""
	var timer = Timer.new()
	timer.wait_time = max(10.0, 30.0 / interaction_frequency)  # 最少10秒间隔
	timer.timeout.connect(_on_companion_timer_timeout)
	timer.autostart = true
	add_child(timer)
	print("陪伴计时器已启动，间隔: ", timer.wait_time, " 秒")

func _on_companion_timer_timeout() -> void:
	"""陪伴计时器超时，触发随机互动"""
	trigger_random_interaction()

func set_companion_name(companion_name_input: String) -> void:
	"""设置陪伴者名称"""
	companion_name = companion_name_input
	companion_setting_changed.emit("companion_name", companion_name_input)
	print("陪伴者名称设置为: ", companion_name_input)

func set_interaction_frequency(frequency: float) -> void:
	"""设置互动频率"""
	interaction_frequency = clamp(frequency, 0.1, 3.0)
	companion_setting_changed.emit("interaction_frequency", frequency)
	print("互动频率设置为: ", frequency)

func set_voice_enabled(enabled: bool) -> void:
	"""设置语音功能"""
	voice_enabled = enabled
	companion_setting_changed.emit("voice_enabled", enabled)
	print("语音功能: ", "开启" if enabled else "关闭")

func set_companion_personality(personality: String) -> void:
	"""设置陪伴者性格"""
	companion_personality = personality
	companion_setting_changed.emit("personality", personality)
	print("陪伴者性格设置为: ", personality)

func trigger_random_interaction() -> void:
	"""触发随机互动"""
	var interactions = [
		"想和你聊聊天呢~",
		"今天过得怎么样？",
		"要不要一起玩个小游戏？",
		"记得休息一下哦！",
		"你今天真棒！"
	]
	
	var random_interaction = interactions[randi() % interactions.size()]
	show_companion_message(random_interaction)

func show_companion_message(message: String) -> void:
	"""显示陪伴者消息"""
	print("[", companion_name, "] ", message)
	
	if voice_enabled:
		speak_message(message)

func speak_message(message: String) -> void:
	"""语音播报消息"""
	# TODO: 实现语音播报功能
	print("语音播报: ", message)

func add_friendship_points(points: int) -> void:
	"""增加友好度"""
	friendship_points += points
	check_level_up()

func check_level_up() -> void:
	"""检查是否升级"""
	var required_points = companion_level * 100
	if friendship_points >= required_points:
		companion_level += 1
		friendship_level_up.emit(companion_level)
		show_companion_message("我们的友谊等级提升了！现在是等级 " + str(companion_level))

func change_mood(new_mood: MoodState) -> void:
	"""改变陪伴者心情"""
	if current_mood != new_mood:
		current_mood = new_mood
		mood_changed.emit(new_mood)
		
		var mood_text = get_mood_text(new_mood)
		show_companion_message("我现在感觉" + mood_text + "~")

func get_mood_text(mood: MoodState) -> String:
	"""获取心情文本"""
	match mood:
		MoodState.HAPPY:
			return "很开心"
		MoodState.CALM:
			return "很平静"
		MoodState.EXCITED:
			return "很兴奋"
		MoodState.SLEEPY:
			return "有点困"
		MoodState.CURIOUS:
			return "很好奇"
		_:
			return "不错"

func interact_with_companion() -> void:
	"""与陪伴者互动"""
	last_interaction_time = Time.get_unix_time_from_system()
	add_friendship_points(10)
	
	# 随机改变心情
	if randf() < 0.3:  # 30% 概率改变心情
		var moods = [MoodState.HAPPY, MoodState.CALM, MoodState.EXCITED, MoodState.CURIOUS]
		var random_mood = moods[randi() % moods.size()]
		change_mood(random_mood)
