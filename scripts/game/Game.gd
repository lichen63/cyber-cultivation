extends Node2D

## 游戏主控制器
## 处理游戏逻辑和状态管理

# 游戏状态枚举
enum GameState {
	PLAYING,
	PAUSED,
	GAME_OVER
}

# 当前游戏状态
var current_state: GameState = GameState.PLAYING

# 节点引用
@onready var player: CharacterBody2D = $GameWorld/Player
@onready var back_button: Button = $UI/HUD/TopBar/BackButton

func _ready() -> void:
	"""初始化游戏"""
	print("游戏初始化")
	setup_game()

func setup_game() -> void:
	"""设置游戏初始状态"""
	# 设置玩家初始位置
	if player:
		player.position = Vector2(640, 360)  # 屏幕中心
	
	# 设置UI焦点
	back_button.grab_focus()

func _on_back_button_pressed() -> void:
	"""返回主菜单"""
	print("返回主菜单")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	if event.is_action_pressed("ui_cancel"):
		# ESC键返回主菜单
		_on_back_button_pressed()

func pause_game() -> void:
	"""暂停游戏"""
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		print("游戏暂停")

func resume_game() -> void:
	"""恢复游戏"""
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		print("游戏恢复")

func game_over() -> void:
	"""游戏结束"""
	current_state = GameState.GAME_OVER
	print("游戏结束")
