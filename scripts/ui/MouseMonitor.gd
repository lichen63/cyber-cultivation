class_name MouseMonitor
extends Panel

# === MOUSE MONITORING COMPONENT ===

const UIConstants = preload("res://scripts/ui/UIConstants.gd")
const UIStyler = preload("res://scripts/ui/UIStyler.gd")

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

func setup_styling() -> void:
  """Apply styling to monitoring area"""
  add_theme_stylebox_override("panel", UIStyler.create_mouse_monitor_style())

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
