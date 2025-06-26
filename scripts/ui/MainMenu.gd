extends Control

## 主菜单控制器
## 处理主菜单的用户交互和导航

# UI节点引用
@onready var start_button: Button = $MainContainer/ButtonContainer/StartButton
@onready var settings_button: Button = $MainContainer/ButtonContainer/SettingsButton
@onready var companion_button: Button = $MainContainer/ButtonContainer/CompanionButton
@onready var exit_button: Button = $MainContainer/ButtonContainer/ExitButton

func _ready() -> void:
	"""初始化主菜单"""
	# 设置初始焦点
	start_button.grab_focus()
	
	# 设置按钮导航
	setup_button_navigation()
	
	# 播放背景音乐（如果有的话）
	# AudioManager.play_background_music("main_menu")

func setup_button_navigation() -> void:
	"""设置按钮导航和提示"""
	# 为按钮添加提示文本
	start_button.tooltip_text = "开始新游戏"
	settings_button.tooltip_text = "打开游戏设置"
	companion_button.tooltip_text = "打开陪伴设置"
	exit_button.tooltip_text = "退出游戏"
	
	# 设置键盘导航
	start_button.focus_neighbor_bottom = settings_button.get_path()
	settings_button.focus_neighbor_top = start_button.get_path()
	settings_button.focus_neighbor_bottom = companion_button.get_path()
	companion_button.focus_neighbor_top = settings_button.get_path()
	companion_button.focus_neighbor_bottom = exit_button.get_path()
	exit_button.focus_neighbor_top = companion_button.get_path()

func _on_start_button_pressed() -> void:
	"""开始游戏按钮点击事件"""
	print("开始游戏")
	# TODO: 切换到游戏场景
	# get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_settings_button_pressed() -> void:
	"""设置按钮点击事件"""
	print("打开设置")
	# TODO: 打开设置菜单
	# get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")

func _on_companion_button_pressed() -> void:
	"""陪伴设置按钮点击事件"""
	print("打开陪伴设置")
	# TODO: 打开陪伴设置
	# get_tree().change_scene_to_file("res://scenes/ui/CompanionSettings.tscn")

func _on_exit_button_pressed() -> void:
	"""退出游戏按钮点击事件"""
	print("退出游戏")
	get_tree().quit()

func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	if event.is_action_pressed("ui_cancel"):
		# ESC键退出游戏
		get_tree().quit()
