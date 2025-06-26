extends Control

## 主菜单控制器
## 显示桌面宠物角色

# UI节点引用
@onready var human_character: Sprite2D = $HumanCharacter

func _ready() -> void:
	"""初始化主菜单"""
	# 启用透明背景
	get_viewport().transparent_bg = true
	get_window().transparent = true
	
	# 确保人形角色可见
	if human_character:
		human_character.modulate = Color.WHITE
	
	# 连接CompanionManager信号
	if CompanionManager:
		CompanionManager.mood_changed.connect(_on_mood_changed)
		CompanionManager.interaction_triggered.connect(_on_interaction_triggered)
	
	# 可以添加一些简单的动画效果
	animate_character()

func animate_character() -> void:
	"""为人形角色添加简单的动画效果"""
	if human_character:
		# 创建一个简单的呼吸动画
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(human_character, "scale", Vector2(1.05, 1.05), 2.0)
		tween.tween_property(human_character, "scale", Vector2(1.0, 1.0), 2.0)

func _on_mood_changed(new_mood) -> void:
	"""响应心情变化"""
	# 根据心情调整角色颜色
	if human_character:
		match new_mood:
			CompanionManager.MoodState.HAPPY:
				human_character.modulate = Color.WHITE
			CompanionManager.MoodState.EXCITED:
				human_character.modulate = Color.YELLOW
			CompanionManager.MoodState.CALM:
				human_character.modulate = Color.LIGHT_BLUE
			CompanionManager.MoodState.SLEEPY:
				human_character.modulate = Color.GRAY
			CompanionManager.MoodState.CURIOUS:
				human_character.modulate = Color.LIGHT_GREEN

func _on_interaction_triggered() -> void:
	"""响应互动触发"""
	# 播放互动动画
	if human_character:
		var interaction_tween = create_tween()
		interaction_tween.tween_property(human_character, "rotation", 0.2, 0.2)
		interaction_tween.tween_property(human_character, "rotation", -0.2, 0.2)
		interaction_tween.tween_property(human_character, "rotation", 0.0, 0.2)

func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	if event.is_action_pressed("ui_accept"):
		# 空格键或回车与宠物互动
		if CompanionManager:
			CompanionManager.interact_with_companion()
	elif event.is_action_pressed("ui_cancel"):
		# ESC键退出游戏
		get_tree().quit()
