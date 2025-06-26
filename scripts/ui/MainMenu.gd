extends Control

## 主菜单控制器
## 显示人形角色，透明背景

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

func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	if event.is_action_pressed("ui_cancel"):
		# ESC键退出游戏
		get_tree().quit()
