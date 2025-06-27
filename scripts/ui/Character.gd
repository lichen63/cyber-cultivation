extends Area2D

## Human character controller
## Handles dragging and mouse interactions

# Drag-related variables
var is_dragging: bool = false
var drag_start_mouse_pos: Vector2
var drag_start_window_pos: Vector2

# UI node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	"""Initialize human character"""
	# Connect mouse signals
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set up collision shape to match sprite size
	setup_collision_shape()
	
	# Center the character in the window
	center_character()

func setup_collision_shape() -> void:
	"""Set up collision shape to match sprite dimensions"""
	if sprite and sprite.texture and collision_shape:
		var texture_size = sprite.texture.get_size()
		var shape = RectangleShape2D.new()
		shape.size = texture_size * sprite.scale
		collision_shape.shape = shape

func center_character() -> void:
	"""Center the character in the window"""
	var window_size = get_window().size
	position = Vector2(window_size.x / 2, window_size.y / 2)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Handle input events on the character"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("✓ Character clicked - starting drag")
				is_dragging = true
				# Store initial positions for smooth dragging
				drag_start_mouse_pos = event.global_position
				drag_start_window_pos = Vector2(get_window().position)
				print("Drag start mouse pos: ", drag_start_mouse_pos)
				print("Drag start window pos: ", drag_start_window_pos)
			else:
				# Mouse released, stop dragging
				is_dragging = false
				print("✓ Drag ended")

func _input(event: InputEvent) -> void:
	"""Handle global input events (for dragging)"""
	if event.is_action_pressed("ui_cancel"):
		# ESC key to quit game
		get_tree().quit()
	
	if event is InputEventMouseMotion and is_dragging:
		# Calculate how much the mouse has moved since drag started
		var mouse_delta = event.global_position - drag_start_mouse_pos
		# Move window by the same amount
		var new_window_pos = drag_start_window_pos + mouse_delta
		print("=== Mouse Motion During Drag ===")
		print("Current mouse pos: ", event.global_position)
		print("Mouse delta: ", mouse_delta)
		print("New window pos: ", new_window_pos)
		
		get_window().position = Vector2i(new_window_pos)

func _on_mouse_entered() -> void:
	"""Visual feedback when mouse enters character area"""
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 1.2, 1.0) # Slightly brighter

func _on_mouse_exited() -> void:
	"""Reset visual feedback when mouse exits character area"""
	if sprite:
		sprite.modulate = Color.WHITE
