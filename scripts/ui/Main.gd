extends Control

# Custom MousePoint class for drawing the mouse point
class MousePoint extends Control:
  func _draw() -> void:
    var point_color = Color(0.9, 0.3, 0.3, 0.9) # Red point
    var point_size = 4.0
    draw_circle(Vector2(4, 4), point_size, point_color)
    
    # Draw a subtle glow effect
    var glow_color = Color(0.9, 0.3, 0.3, 0.3)
    draw_circle(Vector2(4, 4), point_size + 2, glow_color)

# Node references
@onready var character_node: TextureRect = $Character

# Keyboard display system
var keyboard_display: Label
var last_key_text: String = ""

# Key mapping dictionary for better performance and maintainability
var key_name_map: Dictionary = {
  KEY_SPACE: "Space",
  KEY_ENTER: "Enter",
  KEY_TAB: "Tab",
  KEY_BACKSPACE: "Backspace",
  KEY_DELETE: "Delete",
  KEY_ESCAPE: "Escape",
  KEY_LEFT: "Left",
  KEY_RIGHT: "Right",
  KEY_UP: "Up",
  KEY_DOWN: "Down",
  KEY_SHIFT: "Shift",
  KEY_CTRL: "Ctrl",
  KEY_ALT: "Alt",
  KEY_META: "Cmd",
  KEY_CAPSLOCK: "CapsLock",
  KEY_F1: "F1",
  KEY_F2: "F2",
  KEY_F3: "F3",
  KEY_F4: "F4",
  KEY_F5: "F5",
  KEY_F6: "F6",
  KEY_F7: "F7",
  KEY_F8: "F8",
  KEY_F9: "F9",
  KEY_F10: "F10",
  KEY_F11: "F11",
  KEY_F12: "F12"
}

# Action button system
var action_buttons: Array[Button] = []
var buttons_visible: bool = false
var show_tween: Tween
var hide_tween: Tween
var is_animating: bool = false

# Window dragging system
var is_dragging: bool = false
var mouse_initial_pos: Vector2 = Vector2.ZERO

# Mouse monitoring system
var mouse_monitor_area: Panel
var mouse_point: Control
var mouse_point_original_pos: Vector2
var blink_tween: Tween
var move_tween: Tween

# === LIFECYCLE METHODS ===

func _ready() -> void:
  # Enable transparent background
  get_viewport().transparent_bg = true
  get_window().transparent = true
  
  # Enable drawing for border
  set_process(true)
  
  # Create keyboard display
  create_keyboard_display()
  
  # Create action buttons
  create_action_buttons()
  
  # Create mouse monitoring area
  create_mouse_monitor()
  
  # Connect mouse signals for window hover detection
  mouse_entered.connect(_on_window_mouse_entered)
  mouse_exited.connect(_on_window_mouse_exited)

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
  """Handle all input events - keyboard and global mouse monitoring"""
  if event is InputEventKey and event.pressed:
    update_keyboard_display(event)
  elif event is InputEventMouseButton:
    # Global mouse button monitoring
    if event.pressed:
      handle_mouse_click(event.global_position)
    if event.double_click:
      handle_mouse_double_click(event.global_position)
  elif event is InputEventMouseMotion:
    # Global mouse movement monitoring
    handle_mouse_move(event.global_position)

func _gui_input(event: InputEvent) -> void:
  """Handle mouse input for window dragging only"""
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

func create_keyboard_display() -> void:
  """Create keyboard display label above character"""
  keyboard_display = Label.new()
  keyboard_display.text = "..."
  keyboard_display.size = Vector2(200, 60)
  
  # Position above character (assuming character is centered)
  var window_size = get_window().size
  keyboard_display.position = Vector2(
    (window_size.x - keyboard_display.size.x) / 2,
    5 # pixels from top
  )
  
  # Style the label
  style_keyboard_display()
  
  # Set larger font size
  keyboard_display.add_theme_font_size_override("font_size", 30)
  
  # Add to scene
  add_child(keyboard_display)

func style_keyboard_display() -> void:
  """Apply styling to keyboard display label"""
  # Create background style
  var style_background = StyleBoxFlat.new()
  style_background.bg_color = Color(0.1, 0.1, 0.2, 0.8) # Dark blue-gray background
  style_background.border_width_left = 2
  style_background.border_width_right = 2
  style_background.border_width_top = 2
  style_background.border_width_bottom = 2
  style_background.border_color = Color(0.4, 0.6, 0.9, 0.9) # Blue border
  style_background.corner_radius_top_left = 6
  style_background.corner_radius_top_right = 6
  style_background.corner_radius_bottom_left = 6
  style_background.corner_radius_bottom_right = 6
  
  # Apply background style
  keyboard_display.add_theme_stylebox_override("normal", style_background)
  
  # Set text properties
  keyboard_display.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0)) # Light blue-white text
  keyboard_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  keyboard_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func create_action_buttons() -> void:
  """Create action buttons around the window border"""
  var window_size = get_window().size
  var button_thickness = 50 # Thickness of the button strip
  
  # Calculate button dimensions for 2 buttons per side
  var top_bottom_button_width = (window_size.x - 2 * button_thickness) / 2.0
  var left_right_button_height = (window_size.y - 2 * button_thickness) / 2.0
  
  # Button positions and sizes around the border (6 buttons total - 2 per side, excluding top)
  var button_configs = [
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
  
  # Button labels for different functions (2 per side: Right, Bottom, Left)
  var labels = ["R-1", "R-2", "B-1", "B-2", "L-1", "L-2"]
  
  for i in range(button_configs.size()):
    var button = Button.new()
    button.text = labels[i]
    button.size = button_configs[i]["size"]
    button.position = button_configs[i]["pos"]
    button.visible = false # Initially hidden
    
    # Create beautiful modern button style
    style_button(button)
    
    # Connect button signal for future functionality
    button.pressed.connect(_on_action_button_pressed.bind(i))
    
    # Add button to scene and array
    add_child(button)
    action_buttons.append(button)

func style_button(button: Button) -> void:
  """Apply beautiful modern styling to a button"""
  # Create custom StyleBoxFlat for normal state
  var style_normal = StyleBoxFlat.new()
  style_normal.bg_color = Color(0.2, 0.2, 0.3, 0.85) # Dark blue-gray with transparency
  style_normal.border_width_left = 2
  style_normal.border_width_right = 2
  style_normal.border_width_top = 2
  style_normal.border_width_bottom = 2
  style_normal.border_color = Color(0.4, 0.6, 0.9, 0.8) # Bright blue border
  style_normal.corner_radius_top_left = 8
  style_normal.corner_radius_top_right = 8
  style_normal.corner_radius_bottom_left = 8
  style_normal.corner_radius_bottom_right = 8
  style_normal.shadow_color = Color(0, 0, 0, 0.3)
  style_normal.shadow_size = 4
  style_normal.shadow_offset = Vector2(2, 2)
  
  # Create custom StyleBoxFlat for hover state
  var style_hover = StyleBoxFlat.new()
  style_hover.bg_color = Color(0.3, 0.4, 0.6, 0.9) # Lighter blue when hovered
  style_hover.border_width_left = 2
  style_hover.border_width_right = 2
  style_hover.border_width_top = 2
  style_hover.border_width_bottom = 2
  style_hover.border_color = Color(0.5, 0.7, 1.0, 1.0) # Brighter blue border
  style_hover.corner_radius_top_left = 8
  style_hover.corner_radius_top_right = 8
  style_hover.corner_radius_bottom_left = 8
  style_hover.corner_radius_bottom_right = 8
  style_hover.shadow_color = Color(0, 0, 0, 0.4)
  style_hover.shadow_size = 6
  style_hover.shadow_offset = Vector2(2, 2)
  
  # Create custom StyleBoxFlat for pressed state
  var style_pressed = StyleBoxFlat.new()
  style_pressed.bg_color = Color(0.1, 0.2, 0.4, 0.95) # Darker when pressed
  style_pressed.border_width_left = 2
  style_pressed.border_width_right = 2
  style_pressed.border_width_top = 2
  style_pressed.border_width_bottom = 2
  style_pressed.border_color = Color(0.3, 0.5, 0.8, 1.0) # Darker blue border
  style_pressed.corner_radius_top_left = 8
  style_pressed.corner_radius_top_right = 8
  style_pressed.corner_radius_bottom_left = 8
  style_pressed.corner_radius_bottom_right = 8
  style_pressed.shadow_color = Color(0, 0, 0, 0.2)
  style_pressed.shadow_size = 2
  style_pressed.shadow_offset = Vector2(1, 1)
  
  # Apply styles to button
  button.add_theme_stylebox_override("normal", style_normal)
  button.add_theme_stylebox_override("hover", style_hover)
  button.add_theme_stylebox_override("pressed", style_pressed)
  
  # Set text color and font properties
  button.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0)) # Light blue-white text
  button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0)) # Pure white on hover
  button.add_theme_color_override("font_pressed_color", Color(0.8, 0.9, 1.0, 1.0)) # Slightly dimmer when pressed
  
  # Initial transparency for animation
  button.modulate = Color(1.0, 1.0, 1.0, 0.0)

# === EVENT HANDLERS ===

func _on_window_mouse_entered() -> void:
  """Show action buttons when mouse enters window area"""
  show_action_buttons()

func _on_window_mouse_exited() -> void:
  """Hide action buttons when mouse exits window area"""
  hide_action_buttons()

func _on_action_button_pressed(button_index: int) -> void:
  """Handle action button presses - placeholder for future functionality"""
  var button_names = ["Right-1", "Right-2", "Bottom-1", "Bottom-2", "Left-1", "Left-2"]
  print("Action button pressed: ", button_names[button_index])
  # TODO: Implement specific functionality for each action button

# === MOUSE MONITORING HANDLERS ===

func handle_mouse_click(_mouse_pos: Vector2) -> void:
  """Handle mouse click events - blink the point"""
  if mouse_point:
    # Stop any existing blink animation
    if blink_tween:
      blink_tween.kill()
    
    # Ensure point is visible before blinking
    mouse_point.modulate.a = 1.0
    
    # Start blink animation
    blink_mouse_point()

func handle_mouse_move(mouse_pos: Vector2) -> void:
  """Handle mouse move events - move the point in the same direction (global coordinates)"""
  # Map the entire screen to the monitor area
  var screen_size = DisplayServer.screen_get_size()
  var relative_pos = mouse_pos / Vector2(screen_size)
  
  # Scale to point area within the monitor
  var point_area_size = mouse_monitor_area.size - Vector2(16, 16) # Account for borders and label
  var new_point_pos = Vector2(
    clamp(relative_pos.x * point_area_size.x, 0, point_area_size.x - 8) + 8,
    clamp(relative_pos.y * point_area_size.y, 0, point_area_size.y - 8) + 8
  )
  
  # Use direct position assignment to avoid conflicts and ensure visibility
  mouse_point.position = new_point_pos
  # Ensure the point is visible after movement
  mouse_point.modulate.a = 1.0

func handle_mouse_double_click(_mouse_pos: Vector2) -> void:
  """Handle double-click events - rapid blink"""
  rapid_blink_mouse_point()

func blink_mouse_point() -> void:
  """Make the mouse point blink once"""
  if not mouse_point:
    return
    
  if blink_tween:
    blink_tween.kill()
  
  # Ensure point is visible before starting animation
  mouse_point.modulate.a = 1.0
  
  blink_tween = create_tween()
  blink_tween.tween_property(mouse_point, "modulate:a", 0.2, 0.1)
  blink_tween.tween_property(mouse_point, "modulate:a", 1.0, 0.1)

func rapid_blink_mouse_point() -> void:
  """Make the mouse point blink rapidly for double-click"""
  if not mouse_point:
    return
    
  if blink_tween:
    blink_tween.kill()
  
  # Ensure point is visible before starting animation
  mouse_point.modulate.a = 1.0
  
  blink_tween = create_tween()
  # Blink 3 times rapidly
  for i in range(3):
    blink_tween.tween_property(mouse_point, "modulate:a", 0.1, 0.05)
    blink_tween.tween_property(mouse_point, "modulate:a", 1.0, 0.05)

func create_mouse_monitor() -> void:
  """Create mouse monitoring area and point to the right of the character"""
  var window_size = get_window().size
  
  # Create the monitoring area panel
  mouse_monitor_area = Panel.new()
  mouse_monitor_area.size = Vector2(150, 120)
  mouse_monitor_area.position = Vector2(window_size.x - 170, 80) # Right side, below keyboard display
  
  # Style the monitoring area
  var area_style = StyleBoxFlat.new()
  area_style.bg_color = Color(0.15, 0.15, 0.25, 0.8) # Dark background
  area_style.border_width_left = 2
  area_style.border_width_right = 2
  area_style.border_width_top = 2
  area_style.border_width_bottom = 2
  area_style.border_color = Color(0.4, 0.6, 0.9, 0.8) # Blue border
  area_style.corner_radius_top_left = 8
  area_style.corner_radius_top_right = 8
  area_style.corner_radius_bottom_left = 8
  area_style.corner_radius_bottom_right = 8
  mouse_monitor_area.add_theme_stylebox_override("panel", area_style)
  
  # Create the mouse point
  mouse_point = MousePoint.new()
  mouse_point.size = Vector2(32, 32)
  mouse_point_original_pos = Vector2(75, 60) # Center of the area
  mouse_point.position = mouse_point_original_pos
  mouse_point.custom_minimum_size = Vector2(32, 32)
  
  # Add components to the monitoring area
  mouse_monitor_area.add_child(mouse_point)
  
  # Add the monitoring area to the main scene
  add_child(mouse_monitor_area)

# === UTILITY METHODS ===

func update_keyboard_display(event: InputEventKey) -> void:
  """Update keyboard display with the pressed key"""
  var key_string = ""
  
  # Try to get key name from dictionary first
  if event.keycode in key_name_map:
    key_string = key_name_map[event.keycode]
  else:
    # For regular characters, use the unicode representation
    if event.unicode != 0:
      key_string = char(event.unicode)
    else:
      key_string = "Key: " + str(event.keycode)
  
  # Add modifier information
  var modifiers = []
  if event.shift_pressed:
    modifiers.append("Shift")
  if event.ctrl_pressed:
    modifiers.append("Ctrl")
  if event.alt_pressed:
    modifiers.append("Alt")
  if event.meta_pressed:
    modifiers.append("Cmd")
  
  if modifiers.size() > 0:
    key_string = " + ".join(modifiers) + " + " + key_string
  
  # Update the display
  last_key_text = key_string
  keyboard_display.text = key_string

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
