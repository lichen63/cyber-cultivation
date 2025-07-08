extends Control

# Node references
@onready var character_node: TextureRect = $Character

# Action button system
var action_buttons: Array[Button] = []
var buttons_visible: bool = false

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
  
  # Connect mouse signals for character hover detection
  character_node.mouse_entered.connect(_on_character_mouse_entered)
  character_node.mouse_exited.connect(_on_character_mouse_exited)

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
  
  # Calculate button dimensions to fill the border areas
  var top_bottom_button_width = (window_size.x - 2 * button_thickness) / 3.0
  
  # Button positions and sizes around the border (8 buttons total)
  var button_configs = [
    # Top buttons (3 buttons)
    {"pos": Vector2(button_thickness, 0), "size": Vector2(top_bottom_button_width, button_thickness)}, # Top left
    {"pos": Vector2(button_thickness + top_bottom_button_width, 0), "size": Vector2(top_bottom_button_width, button_thickness)}, # Top center
    {"pos": Vector2(button_thickness + 2 * top_bottom_button_width, 0), "size": Vector2(top_bottom_button_width, button_thickness)}, # Top right
    
    # Right button
    {"pos": Vector2(window_size.x - button_thickness, button_thickness), "size": Vector2(button_thickness, window_size.y - 2 * button_thickness)}, # Right center
    
    # Bottom buttons (3 buttons)
    {"pos": Vector2(button_thickness + 2 * top_bottom_button_width, window_size.y - button_thickness), "size": Vector2(top_bottom_button_width, button_thickness)}, # Bottom right
    {"pos": Vector2(button_thickness + top_bottom_button_width, window_size.y - button_thickness), "size": Vector2(top_bottom_button_width, button_thickness)}, # Bottom center
    {"pos": Vector2(button_thickness, window_size.y - button_thickness), "size": Vector2(top_bottom_button_width, button_thickness)}, # Bottom left
    
    # Left button  
    {"pos": Vector2(0, button_thickness), "size": Vector2(button_thickness, window_size.y - 2 * button_thickness)} # Left center
  ]
  
  # Button labels for different functions
  var labels = ["B-1", "B-2", "B-3", "B-4", "B-5", "B-6", "B-7", "B-8"]
  
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

func _on_character_mouse_entered() -> void:
  """Show action buttons when mouse enters character area"""
  show_action_buttons()

func _on_character_mouse_exited() -> void:
  """Hide action buttons when mouse exits character area"""
  hide_action_buttons()

func _on_action_button_pressed(button_index: int) -> void:
  """Handle action button presses - placeholder for future functionality"""
  var button_names = ["Action-1", "Action-2", "Action-3", "Action-4", "Action-5", "Action-6", "Action-7", "Action-8"]
  print("Action button pressed: ", button_names[button_index])
  # TODO: Implement specific functionality for each action button

# === UTILITY METHODS ===

func show_action_buttons() -> void:
  """Make action buttons visible with fade-in animation"""
  if buttons_visible:
    return
  
  buttons_visible = true
  for button in action_buttons:
    button.visible = true
    button.modulate.a = 0.0
    
    # Create fade-in tween
    var tween = create_tween()
    tween.tween_property(button, "modulate:a", 0.9, 0.3)

func hide_action_buttons() -> void:
  """Hide action buttons with fade-out animation"""
  if not buttons_visible:
    return
  
  buttons_visible = false
  for button in action_buttons:
    # Create fade-out tween
    var tween = create_tween()
    tween.tween_property(button, "modulate:a", 0.0, 0.2)
    tween.tween_callback(func(): button.visible = false)
