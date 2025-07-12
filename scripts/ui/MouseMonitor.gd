class_name MouseMonitor
extends Panel

# === MOUSE MONITORING COMPONENT ===

const UIConstants = preload("res://scripts/ui/UIConstants.gd")
const UIStyler = preload("res://scripts/ui/UIStyler.gd")

# Reference to cultivation status for experience tracking
var cultivation_status: CultivationStatus

# Mouse tracking variables
var last_mouse_position: Vector2
var accumulated_mouse_distance: float = 0.0
var movement_threshold: float = 100.0

# Custom MousePoint class for drawing the mouse point
class MousePoint extends Control:
  func _draw() -> void:
    draw_circle(Vector2(4, 4), UIConstants.MOUSE_POINT_SIZE, UIConstants.POINT_COLOR)
    
    # Draw a subtle glow effect
    draw_circle(Vector2(4, 4), UIConstants.MOUSE_POINT_SIZE + 2, UIConstants.GLOW_COLOR)

var mouse_point: Control
var mouse_point_original_pos: Vector2

func _init():
  """Initialize mouse monitor"""
  size = Vector2(UIConstants.MOUSE_MONITOR_WIDTH, UIConstants.MOUSE_MONITOR_HEIGHT)
  setup_styling()
  create_mouse_point()
  
  # Initialize mouse tracking
  last_mouse_position = DisplayServer.mouse_get_position()

func setup_styling() -> void:
  """Apply styling to monitoring area"""
  add_theme_stylebox_override("panel", UIStyler.create_mouse_monitor_style())

func set_cultivation_status(status: CultivationStatus) -> void:
  """Set the cultivation status reference for experience tracking"""
  cultivation_status = status

func create_mouse_point() -> void:
  """Create the mouse point indicator"""
  mouse_point = MousePoint.new()
  mouse_point.size = Vector2(UIConstants.MOUSE_POINT_SIZE, UIConstants.MOUSE_POINT_SIZE)
  mouse_point_original_pos = Vector2(UIConstants.MONITOR_CENTER_X, UIConstants.MONITOR_CENTER_Y) # Center of the area
  mouse_point.position = mouse_point_original_pos
  mouse_point.custom_minimum_size = Vector2(UIConstants.MOUSE_POINT_SIZE, UIConstants.MOUSE_POINT_SIZE)
  
  # Add mouse point to the monitoring area
  add_child(mouse_point)

func position_monitor(window_size: Vector2) -> void:
  """Position mouse monitor relative to window"""
  position = Vector2(
    window_size.x - UIConstants.MONITOR_RIGHT_OFFSET,
    window_size.y / UIConstants.WINDOW_HEIGHT_THIRD - UIConstants.MONITOR_HEIGHT_OFFSET
  ) # Right side, at 1/3 height position

func update_mouse_point_position() -> void:
  """Update mouse point position based on current screen mouse coordinates"""
  if not mouse_point:
    return
    
  # Get current mouse position
  var mouse_pos: Vector2i = DisplayServer.mouse_get_position()
  var current_mouse_position = Vector2(mouse_pos)
  
  # Track mouse movement for experience
  track_mouse_movement(current_mouse_position)
  
  # Map the entire screen to the monitor area
  var screen_size: Vector2i = DisplayServer.screen_get_size()
  var relative_pos: Vector2 = Vector2(mouse_pos) / Vector2(screen_size)
  
  # Scale to point area within the monitor
  var point_area_size = size - Vector2(UIConstants.MONITOR_PADDING, UIConstants.MONITOR_PADDING) # Account for borders and label
  var new_point_pos = Vector2(
    clamp(relative_pos.x * point_area_size.x, 0, point_area_size.x - UIConstants.MONITOR_HALF_PADDING) + UIConstants.MONITOR_HALF_PADDING,
    clamp(relative_pos.y * point_area_size.y, 0, point_area_size.y - UIConstants.MONITOR_HALF_PADDING) + UIConstants.MONITOR_HALF_PADDING
  )
  
  # Set the position and ensure visibility
  mouse_point.position = new_point_pos
  mouse_point.modulate.a = 1.0

func track_mouse_movement(current_mouse_position: Vector2) -> void:
  """Track mouse movement and award experience when threshold is reached"""
  var distance = last_mouse_position.distance_to(current_mouse_position)
  
  accumulated_mouse_distance += distance
  last_mouse_position = current_mouse_position
  
  # Check if accumulated distance meets threshold
  if accumulated_mouse_distance >= movement_threshold:
    # Award experience directly
    if cultivation_status:
      cultivation_status.add_experience(1)
    accumulated_mouse_distance = 0.0 # Reset accumulated distance
