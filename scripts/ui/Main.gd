extends Control

# Node references
@onready var character_node: TextureRect = $Character

# Action button system
var action_buttons: Array[Button] = []
var buttons_visible: bool = false
var show_tween: Tween
var hide_tween: Tween
var is_animating: bool = false

# Window dragging system
var is_dragging: bool = false
var mouse_initial_pos: Vector2 = Vector2.ZERO

# === LIFECYCLE METHODS ===

func _ready() -> void:
  # Enable transparent background
  get_viewport().transparent_bg = true
  get_window().transparent = true
  
  # Enable drawing for border
  set_process(true)
  
  # Create action buttons
  create_action_buttons()
  
  # Connect mouse signals for window hover detection
  mouse_entered.connect(_on_window_mouse_entered)
  mouse_exited.connect(_on_window_mouse_exited)

# === INPUT HANDLING ===

func _gui_input(event: InputEvent) -> void:
  """Handle mouse input for window dragging"""
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
      if event.pressed:
        # Start dragging
        is_dragging = true
        mouse_initial_pos = event.global_position
      else:
        # Stop dragging
        is_dragging = false
  elif event is InputEventMouseMotion and is_dragging:
    # Move window based on mouse movement
    var window: Window = get_window()
    var global_mouse_pos: Vector2 = event.global_position
    var position_delta: Vector2 = global_mouse_pos - mouse_initial_pos
    window.position += Vector2i(position_delta)

# === DRAWING ===

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

# === UI CREATION ===

func create_action_buttons() -> void:
  """Create action buttons around the window border"""
  var window_size = get_window().size
  var button_thickness = 50 # Thickness of the button strip
  
  # Calculate button dimensions for 2 buttons per side
  var top_bottom_button_width = (window_size.x - 2 * button_thickness) / 2.0
  var left_right_button_height = (window_size.y - 2 * button_thickness) / 2.0
  
  # Button positions and sizes around the border (8 buttons total - 2 per side)
  var button_configs = [
    # Top buttons (2 buttons)
    {"pos": Vector2(button_thickness, 0), "size": Vector2(top_bottom_button_width, button_thickness)}, # Top left
    {"pos": Vector2(button_thickness + top_bottom_button_width, 0), "size": Vector2(top_bottom_button_width, button_thickness)}, # Top right
    
    # Right buttons (2 buttons)
    {"pos": Vector2(window_size.x - button_thickness, button_thickness), "size": Vector2(button_thickness, left_right_button_height)}, # Right top
    {"pos": Vector2(window_size.x - button_thickness, button_thickness + left_right_button_height), "size": Vector2(button_thickness, left_right_button_height)}, # Right bottom
    
    # Bottom buttons (2 buttons)
    {"pos": Vector2(button_thickness + top_bottom_button_width, window_size.y - button_thickness), "size": Vector2(top_bottom_button_width, button_thickness)}, # Bottom right
    {"pos": Vector2(button_thickness, window_size.y - button_thickness), "size": Vector2(top_bottom_button_width, button_thickness)}, # Bottom left
    
    # Left buttons (2 buttons)
    {"pos": Vector2(0, button_thickness + left_right_button_height), "size": Vector2(button_thickness, left_right_button_height)}, # Left bottom
    {"pos": Vector2(0, button_thickness), "size": Vector2(button_thickness, left_right_button_height)} # Left top
  ]
  
  # Button labels for different functions (2 per side: Top, Right, Bottom, Left)
  var labels = ["T-1", "T-2", "R-1", "R-2", "B-1", "B-2", "L-1", "L-2"]
  
  for i in range(button_configs.size()):
    var button = Button.new()
    button.text = labels[i]
    button.size = button_configs[i]["size"]
    button.position = button_configs[i]["pos"]
    button.visible = false # Initially hidden
    
    # Style the button
    button.flat = false
    button.modulate = Color(1.0, 1.0, 1.0, 0.9)
    
    # Connect button signal for future functionality
    button.pressed.connect(_on_action_button_pressed.bind(i))
    
    # Add button to scene and array
    add_child(button)
    action_buttons.append(button)

# === EVENT HANDLERS ===

func _on_window_mouse_entered() -> void:
  """Show action buttons when mouse enters window area"""
  show_action_buttons()

func _on_window_mouse_exited() -> void:
  """Hide action buttons when mouse exits window area"""
  hide_action_buttons()

func _on_action_button_pressed(button_index: int) -> void:
  """Handle action button presses - placeholder for future functionality"""
  var button_names = ["Top-1", "Top-2", "Right-1", "Right-2", "Bottom-1", "Bottom-2", "Left-1", "Left-2"]
  print("Action button pressed: ", button_names[button_index])
  # TODO: Implement specific functionality for each action button

# === UTILITY METHODS ===

func show_action_buttons() -> void:
  """Make action buttons visible with fade-in animation"""
  if buttons_visible and not is_animating:
    return
  
  # Stop any existing hide animation
  if hide_tween:
    hide_tween.kill()
    hide_tween = null
  
  # If we're currently hiding, interrupt the animation and show immediately
  if is_animating and not buttons_visible:
    # Cancel current animation state
    is_animating = false
  
  # If already visible and not animating, no need to do anything
  if buttons_visible and not is_animating:
    return
    
  is_animating = true
  buttons_visible = true
  
  for button in action_buttons:
    button.visible = true
  
  # Create and save the show tween
  show_tween = create_tween()
  show_tween.set_parallel(true) # Allow multiple properties to animate simultaneously
  
  for button in action_buttons:
    show_tween.tween_property(button, "modulate:a", 0.9, 0.3)
  
  # Set animation finished callback
  show_tween.tween_callback(func(): is_animating = false).set_delay(0.3)

func hide_action_buttons() -> void:
  """Hide action buttons with fade-out animation"""
  if not buttons_visible or is_animating:
    return
  
  # Stop any existing show animation
  if show_tween:
    show_tween.kill()
    show_tween = null
  
  is_animating = true
  buttons_visible = false
  
  # Create and save the hide tween
  hide_tween = create_tween()
  hide_tween.set_parallel(true) # Allow multiple properties to animate simultaneously
  
  for button in action_buttons:
    hide_tween.tween_property(button, "modulate:a", 0.0, 2.0)
  
  # Set visibility to false after animation completes
  hide_tween.tween_callback(func():
    for button in action_buttons:
      button.visible = false
    is_animating = false
  ).set_delay(2.0)
