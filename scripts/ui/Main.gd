extends Control

func _ready() -> void:
  """Initialize main menu"""
  # Enable transparent background
  get_viewport().transparent_bg = true
  get_window().transparent = true
  
  # Enable drawing for border
  set_process(true)

func _draw() -> void:
  """Draw the window border"""
  # Get the window size
  var window_size = get_window().size
  
  # Draw white border (2 pixel thick)
  var border_color = Color.WHITE
  var border_width = 2
  
  # Draw border lines
  draw_rect(Rect2(0, 0, window_size.x, border_width), border_color) # Top
  draw_rect(Rect2(0, window_size.y - border_width, window_size.x, border_width), border_color) # Bottom
  draw_rect(Rect2(0, 0, border_width, window_size.y), border_color) # Left
  draw_rect(Rect2(window_size.x - border_width, 0, border_width, window_size.y), border_color) # Right
