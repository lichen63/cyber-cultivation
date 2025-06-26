extends Node

## 陪伴管理器
## 处理桌面宠物的陪伴功能和互动

# 宠物设置
var companion_name: String = "小助手"
var interaction_enabled: bool = true

# 宠物状态
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
signal mood_changed(new_mood: MoodState)
signal interaction_triggered()

func _ready() -> void:
	"""初始化陪伴管理器"""
	start_companion_timer()

func start_companion_timer() -> void:
	"""启动陪伴计时器"""
	var timer = Timer.new()
	timer.wait_time = 30.0  # 30秒触发一次
	timer.timeout.connect(_on_companion_timer_timeout)
	timer.autostart = true
	add_child(timer)

func _on_companion_timer_timeout() -> void:
	"""陪伴计时器超时"""
	if interaction_enabled:
		trigger_random_interaction()

func trigger_random_interaction() -> void:
	"""触发随机互动"""
	# 随机改变心情
	var random_mood = randi() % MoodState.size()
	change_mood(random_mood as MoodState)
	
	last_interaction_time = Time.get_time_dict_from_system()["unix"]
	interaction_triggered.emit()

func change_mood(new_mood: MoodState) -> void:
	"""改变宠物心情"""
	if current_mood != new_mood:
		current_mood = new_mood
		mood_changed.emit(new_mood)
		print("宠物心情变化: ", MoodState.keys()[new_mood])

func get_mood_name() -> String:
	"""获取当前心情名称"""
	return MoodState.keys()[current_mood]

func interact_with_companion() -> void:
	"""与宠物互动"""
	change_mood(MoodState.HAPPY)
	last_interaction_time = Time.get_time_dict_from_system()["unix"]
	print("与", companion_name, "互动了！")
