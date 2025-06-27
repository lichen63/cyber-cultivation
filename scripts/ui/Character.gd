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
