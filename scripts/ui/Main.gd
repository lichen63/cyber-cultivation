extends Control

# === CONSTANTS ===

# UI Layout constants
const BORDER_WIDTH = 2
const MARGIN = 20
const BUTTON_THICKNESS = 50

# Component sizes
const KEYBOARD_DISPLAY_WIDTH = 150
const KEYBOARD_DISPLAY_HEIGHT = 60
const KEYBOARD_DISPLAY_FONT_SIZE = 30
const MOUSE_MONITOR_WIDTH = 150
const MOUSE_MONITOR_HEIGHT = 120
const MOUSE_POINT_SIZE = 12

# Colors
const POINT_COLOR = Color(0.9, 0.3, 0.3, 0.9)
const GLOW_COLOR = Color(0.9, 0.3, 0.3, 0.3)
const BORDER_COLOR = Color.WHITE
const BACKGROUND_COLOR = Color(0.1, 0.1, 0.2, 0.8)
const BUTTON_BG_COLOR = Color(0.2, 0.2, 0.3, 0.85)
const BUTTON_HOVER_COLOR = Color(0.3, 0.4, 0.6, 0.9)
const BUTTON_PRESSED_COLOR = Color(0.1, 0.2, 0.4, 0.95)
const ACCENT_COLOR = Color(0.4, 0.6, 0.9, 0.8)
const TEXT_COLOR = Color(0.9, 0.9, 1.0, 1.0)

# Animation constants
const BUTTON_FADE_IN_DURATION = 0.3
const BUTTON_FADE_OUT_DURATION = 2.0
const BUTTON_VISIBLE_ALPHA = 0.9
const BUTTON_HIDDEN_ALPHA = 0.0

# Border and corner constants
const CORNER_RADIUS = 8
const SMALL_CORNER_RADIUS = 6
const SHADOW_SIZE = 4
const SHADOW_OFFSET = Vector2(2, 2)

# Positioning constants
const WINDOW_HEIGHT_THIRD = 3.0
const BUTTON_COUNT = 4
const TOP_BUTTONS_COUNT = 2
const BOTTOM_BUTTONS_COUNT = 2
const MONITOR_PADDING = 16
const MONITOR_HALF_PADDING = 8
const MONITOR_RIGHT_OFFSET = 170
const MONITOR_HEIGHT_OFFSET = 60
const MONITOR_CENTER_X = 75
const MONITOR_CENTER_Y = 60

# Custom MousePoint class for drawing the mouse point
class MousePoint extends Control:
  func _draw() -> void:
    draw_circle(Vector2(4, 4), MOUSE_POINT_SIZE, POINT_COLOR)
    
    # Draw a subtle glow effect
    draw_circle(Vector2(4, 4), MOUSE_POINT_SIZE + 2, GLOW_COLOR)

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
  
  # Initialize mouse point position based on current mouse position
  update_mouse_point_position()
  
  # Connect mouse signals for window hover detection
  mouse_entered.connect(_on_window_mouse_entered)
  mouse_exited.connect(_on_window_mouse_exited)

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
  """Handle all input events - keyboard and global mouse monitoring"""
  if event is InputEventKey and event.pressed:
    update_keyboard_display(event)
  elif event is InputEventMouseMotion:
    # Global mouse movement monitoring
    update_mouse_point_position()

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
  
  # Draw white border
  draw_rect(Rect2(0, 0, window_size.x, BORDER_WIDTH), BORDER_COLOR) # Top
  draw_rect(Rect2(0, window_size.y - BORDER_WIDTH, window_size.x, BORDER_WIDTH), BORDER_COLOR) # Bottom
  draw_rect(Rect2(0, 0, BORDER_WIDTH, window_size.y), BORDER_COLOR) # Left
  draw_rect(Rect2(window_size.x - BORDER_WIDTH, 0, BORDER_WIDTH, window_size.y), BORDER_COLOR) # Right

# === UI CREATION ===

func create_keyboard_display() -> void:
  """Create keyboard display label to the left of character"""
  keyboard_display = Label.new()
  keyboard_display.text = "..."
  keyboard_display.size = Vector2(KEYBOARD_DISPLAY_WIDTH, KEYBOARD_DISPLAY_HEIGHT)
  
  # Position to the left of character at 1/3 height
  var window_size = get_window().size
  keyboard_display.position = Vector2(
    MARGIN, # Margin from left edge
    window_size.y / WINDOW_HEIGHT_THIRD - keyboard_display.size.y / 2.0 # 1/3 height position, centered
  )
  
  # Style the label
  style_keyboard_display()
  
  # Set larger font size
  keyboard_display.add_theme_font_size_override("font_size", KEYBOARD_DISPLAY_FONT_SIZE)
  
  # Add to scene
  add_child(keyboard_display)

func style_keyboard_display() -> void:
  """Apply styling to keyboard display label"""
  # Create background style
  var style_background = StyleBoxFlat.new()
  style_background.bg_color = BACKGROUND_COLOR
  style_background.border_width_left = BORDER_WIDTH
  style_background.border_width_right = BORDER_WIDTH
  style_background.border_width_top = BORDER_WIDTH
  style_background.border_width_bottom = BORDER_WIDTH
  style_background.border_color = ACCENT_COLOR
  style_background.corner_radius_top_left = SMALL_CORNER_RADIUS
  style_background.corner_radius_top_right = SMALL_CORNER_RADIUS
  style_background.corner_radius_bottom_left = SMALL_CORNER_RADIUS
  style_background.corner_radius_bottom_right = SMALL_CORNER_RADIUS
  
  # Apply background style
  keyboard_display.add_theme_stylebox_override("normal", style_background)
  
  # Set text properties
  keyboard_display.add_theme_color_override("font_color", TEXT_COLOR)
  keyboard_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  keyboard_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func create_action_buttons() -> void:
  """Create action buttons around the window border"""
  var window_size = get_window().size
  
  # Calculate button dimensions for 2 buttons on top and 2 buttons on bottom with margins
  var available_width = window_size.x - (2 * MARGIN)
  var button_width = available_width / TOP_BUTTONS_COUNT
  
  # Button positions and sizes around the border (4 buttons total - 2 on top, 2 on bottom)
  var button_configs = [
    # Top buttons (2 buttons)
    {"pos": Vector2(MARGIN, 0), "size": Vector2(button_width, BUTTON_THICKNESS)}, # Top left
    {"pos": Vector2(MARGIN + button_width, 0), "size": Vector2(button_width, BUTTON_THICKNESS)}, # Top right
    
    # Bottom buttons (2 buttons)
    {"pos": Vector2(MARGIN, window_size.y - BUTTON_THICKNESS), "size": Vector2(button_width, BUTTON_THICKNESS)}, # Bottom left
    {"pos": Vector2(MARGIN + button_width, window_size.y - BUTTON_THICKNESS), "size": Vector2(button_width, BUTTON_THICKNESS)} # Bottom right
  ]
  
  # Button labels for different functions (2 on top, 2 on bottom)
  var labels = ["T-1", "T-2", "B-1", "B-2"]
  
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
  style_normal.bg_color = BUTTON_BG_COLOR
  style_normal.border_width_left = BORDER_WIDTH
  style_normal.border_width_right = BORDER_WIDTH
  style_normal.border_width_top = BORDER_WIDTH
  style_normal.border_width_bottom = BORDER_WIDTH
  style_normal.border_color = ACCENT_COLOR
  style_normal.corner_radius_top_left = CORNER_RADIUS
  style_normal.corner_radius_top_right = CORNER_RADIUS
  style_normal.corner_radius_bottom_left = CORNER_RADIUS
  style_normal.corner_radius_bottom_right = CORNER_RADIUS
  style_normal.shadow_color = Color(0, 0, 0, 0.3)
  style_normal.shadow_size = SHADOW_SIZE
  style_normal.shadow_offset = SHADOW_OFFSET
  
  # Create custom StyleBoxFlat for hover state
  var style_hover = StyleBoxFlat.new()
  style_hover.bg_color = BUTTON_HOVER_COLOR
  style_hover.border_width_left = BORDER_WIDTH
  style_hover.border_width_right = BORDER_WIDTH
  style_hover.border_width_top = BORDER_WIDTH
  style_hover.border_width_bottom = BORDER_WIDTH
  style_hover.border_color = Color(0.5, 0.7, 1.0, 1.0) # Brighter blue border
  style_hover.corner_radius_top_left = CORNER_RADIUS
  style_hover.corner_radius_top_right = CORNER_RADIUS
  style_hover.corner_radius_bottom_left = CORNER_RADIUS
  style_hover.corner_radius_bottom_right = CORNER_RADIUS
  style_hover.shadow_color = Color(0, 0, 0, 0.4)
  style_hover.shadow_size = SHADOW_SIZE + 2
  style_hover.shadow_offset = SHADOW_OFFSET
  
  # Create custom StyleBoxFlat for pressed state
  var style_pressed = StyleBoxFlat.new()
  style_pressed.bg_color = BUTTON_PRESSED_COLOR
  style_pressed.border_width_left = BORDER_WIDTH
  style_pressed.border_width_right = BORDER_WIDTH
  style_pressed.border_width_top = BORDER_WIDTH
  style_pressed.border_width_bottom = BORDER_WIDTH
  style_pressed.border_color = Color(0.3, 0.5, 0.8, 1.0) # Darker blue border
  style_pressed.corner_radius_top_left = CORNER_RADIUS
  style_pressed.corner_radius_top_right = CORNER_RADIUS
  style_pressed.corner_radius_bottom_left = CORNER_RADIUS
  style_pressed.corner_radius_bottom_right = CORNER_RADIUS
  style_pressed.shadow_color = Color(0, 0, 0, 0.2)
  style_pressed.shadow_size = SHADOW_SIZE / 2.0
  style_pressed.shadow_offset = Vector2(1, 1)
  
  # Apply styles to button
  button.add_theme_stylebox_override("normal", style_normal)
  button.add_theme_stylebox_override("hover", style_hover)
  button.add_theme_stylebox_override("pressed", style_pressed)
  
  # Set text color and font properties
  button.add_theme_color_override("font_color", TEXT_COLOR)
  button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0)) # Pure white on hover
  button.add_theme_color_override("font_pressed_color", Color(0.8, 0.9, 1.0, 1.0)) # Slightly dimmer when pressed
  
  # Initial transparency for animation
  button.modulate = Color(1.0, 1.0, 1.0, BUTTON_HIDDEN_ALPHA)

# === EVENT HANDLERS ===

func _on_window_mouse_entered() -> void:
  """Show action buttons when mouse enters window area"""
  show_action_buttons()

func _on_window_mouse_exited() -> void:
  """Hide action buttons when mouse exits window area"""
  hide_action_buttons()

func _on_action_button_pressed(button_index: int) -> void:
  """Handle action button presses - placeholder for future functionality"""
  var button_names = ["Top-1", "Top-2", "Bottom-1", "Bottom-2"]
  print("Action button pressed: ", button_names[button_index])
  # TODO: Implement specific functionality for each action button

# === MOUSE MONITORING HANDLERS ===

func update_mouse_point_position() -> void:
  """Update mouse point position based on current screen mouse coordinates"""
  if not mouse_point or not mouse_monitor_area:
    return
    
  # Get current mouse position
  var mouse_pos: Vector2i = DisplayServer.mouse_get_position()
  
  # Map the entire screen to the monitor area
  var screen_size: Vector2i = DisplayServer.screen_get_size()
  var relative_pos: Vector2 = Vector2(mouse_pos) / Vector2(screen_size)
  
  # Scale to point area within the monitor
  var point_area_size = mouse_monitor_area.size - Vector2(MONITOR_PADDING, MONITOR_PADDING) # Account for borders and label
  var new_point_pos = Vector2(
    clamp(relative_pos.x * point_area_size.x, 0, point_area_size.x - MONITOR_HALF_PADDING) + MONITOR_HALF_PADDING,
    clamp(relative_pos.y * point_area_size.y, 0, point_area_size.y - MONITOR_HALF_PADDING) + MONITOR_HALF_PADDING
  )
  
  # Set the position and ensure visibility
  mouse_point.position = new_point_pos
  mouse_point.modulate.a = 1.0

func create_mouse_monitor() -> void:
  """Create mouse monitoring area and point to the right of the character"""
  var window_size = get_window().size
  
  # Create the monitoring area panel
  mouse_monitor_area = Panel.new()
  mouse_monitor_area.size = Vector2(MOUSE_MONITOR_WIDTH, MOUSE_MONITOR_HEIGHT)
  mouse_monitor_area.position = Vector2(window_size.x - MONITOR_RIGHT_OFFSET, window_size.y / WINDOW_HEIGHT_THIRD - MONITOR_HEIGHT_OFFSET) # Right side, at 1/3 height position
  
  # Style the monitoring area
  var area_style = StyleBoxFlat.new()
  area_style.bg_color = Color(0.15, 0.15, 0.25, 0.8) # Dark background
  area_style.border_width_left = BORDER_WIDTH
  area_style.border_width_right = BORDER_WIDTH
  area_style.border_width_top = BORDER_WIDTH
  area_style.border_width_bottom = BORDER_WIDTH
  area_style.border_color = ACCENT_COLOR
  area_style.corner_radius_top_left = CORNER_RADIUS
  area_style.corner_radius_top_right = CORNER_RADIUS
  area_style.corner_radius_bottom_left = CORNER_RADIUS
  area_style.corner_radius_bottom_right = CORNER_RADIUS
  mouse_monitor_area.add_theme_stylebox_override("panel", area_style)
  
  # Create the mouse point
  mouse_point = MousePoint.new()
  mouse_point.size = Vector2(MOUSE_POINT_SIZE, MOUSE_POINT_SIZE)
  mouse_point_original_pos = Vector2(MONITOR_CENTER_X, MONITOR_CENTER_Y) # Center of the area
  mouse_point.position = mouse_point_original_pos
  mouse_point.custom_minimum_size = Vector2(MOUSE_POINT_SIZE, MOUSE_POINT_SIZE)
  
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
    show_tween.tween_property(button, "modulate:a", BUTTON_VISIBLE_ALPHA, BUTTON_FADE_IN_DURATION)
  
  # Set animation finished callback
  show_tween.tween_callback(func(): is_animating = false).set_delay(BUTTON_FADE_IN_DURATION)

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
    hide_tween.tween_property(button, "modulate:a", BUTTON_HIDDEN_ALPHA, BUTTON_FADE_OUT_DURATION)
  
  # Set visibility to false after animation completes
  hide_tween.tween_callback(func():
    for button in action_buttons:
      button.visible = false
    is_animating = false
  ).set_delay(BUTTON_FADE_OUT_DURATION)
