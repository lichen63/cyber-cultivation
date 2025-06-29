extends Control

# Variables for window dragging
var is_dragging: bool = false
var mouse_initial_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
  """Initialize main menu"""
  # Enable transparent background
  get_viewport().transparent_bg = true
  get_window().transparent = true
  
  # Enable drawing for border
  set_process(true)

func _gui_input(event: InputEvent) -> void:
  print("GUI input event: ", event)
  """Handle mouse input for window dragging"""
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
      if event.pressed:
        # Start dragging
        is_dragging = true
        mouse_initial_pos = event.position
      else:
        # Stop dragging
        is_dragging = false
  elif event is InputEventMouseMotion and is_dragging:
    # Move window based on mouse movement
    var window = get_window()
    var global_mouse_pos = event.position
    var position_delta = global_mouse_pos - mouse_initial_pos
    # window.position += position_delta
    window.position += Vector2i(1, 0)
    print("Mouse position: ", global_mouse_pos)
    print("Position delta: ", position_delta)
    print("Current window position: ", window.position)

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
