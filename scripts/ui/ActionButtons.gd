class_name ActionButtons
extends RefCounted

# === ACTION BUTTONS COMPONENT ===

const UIConstants = preload("res://scripts/ui/UIConstants.gd")
const UIStyler = preload("res://scripts/ui/UIStyler.gd")

signal button_pressed(button_index: int)

var action_buttons: Array[Button] = []
var buttons_visible: bool = false
var show_tween: Tween
var hide_tween: Tween
var is_animating: bool = false
var parent_node: Control

func _init(parent: Control):
  """Initialize action buttons system"""
  parent_node = parent

func create_buttons() -> void:
  """Create action buttons around the window border"""
  var window_size = parent_node.get_window().size
  
  # Calculate button dimensions for 2 buttons on top and 2 buttons on bottom with margins
  var available_width = window_size.x - (2 * UIConstants.MARGIN)
  var button_width = available_width / UIConstants.TOP_BUTTONS_COUNT
  
  # Button positions and sizes around the border (4 buttons total - 2 on top, 2 on bottom)
  var button_configs = [
    # Top buttons (2 buttons)
    {"pos": Vector2(UIConstants.MARGIN, 0), "size": Vector2(button_width, UIConstants.BUTTON_THICKNESS)}, # Top left
    {"pos": Vector2(UIConstants.MARGIN + button_width, 0), "size": Vector2(button_width, UIConstants.BUTTON_THICKNESS)}, # Top right
    
    # Bottom buttons (2 buttons)
    {"pos": Vector2(UIConstants.MARGIN, window_size.y - UIConstants.BUTTON_THICKNESS), "size": Vector2(button_width, UIConstants.BUTTON_THICKNESS)}, # Bottom left
    {"pos": Vector2(UIConstants.MARGIN + button_width, window_size.y - UIConstants.BUTTON_THICKNESS), "size": Vector2(button_width, UIConstants.BUTTON_THICKNESS)} # Bottom right
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
    
    # Connect button signal
    button.pressed.connect(func(): button_pressed.emit(i))
    
    # Add button to scene and array
    parent_node.add_child(button)
    action_buttons.append(button)

func style_button(button: Button) -> void:
  """Apply beautiful modern styling to a button"""
  # Apply styles to button
  button.add_theme_stylebox_override("normal", UIStyler.create_button_normal_style())
  button.add_theme_stylebox_override("hover", UIStyler.create_button_hover_style())
  button.add_theme_stylebox_override("pressed", UIStyler.create_button_pressed_style())
  
  # Set text color and font properties
  button.add_theme_color_override("font_color", UIConstants.TEXT_COLOR)
  button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0)) # Pure white on hover
  button.add_theme_color_override("font_pressed_color", Color(0.8, 0.9, 1.0, 1.0)) # Slightly dimmer when pressed
  
  # Initial transparency for animation
  button.modulate = Color(1.0, 1.0, 1.0, UIConstants.BUTTON_HIDDEN_ALPHA)

func show_buttons() -> void:
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
  show_tween = parent_node.create_tween()
  show_tween.set_parallel(true) # Allow multiple properties to animate simultaneously
  
  for button in action_buttons:
    show_tween.tween_property(button, "modulate:a", UIConstants.BUTTON_VISIBLE_ALPHA, UIConstants.BUTTON_FADE_IN_DURATION)
  
  # Set animation finished callback
  show_tween.tween_callback(func(): is_animating = false).set_delay(UIConstants.BUTTON_FADE_IN_DURATION)

func hide_buttons() -> void:
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
  hide_tween = parent_node.create_tween()
  hide_tween.set_parallel(true) # Allow multiple properties to animate simultaneously
  
  for button in action_buttons:
    hide_tween.tween_property(button, "modulate:a", UIConstants.BUTTON_HIDDEN_ALPHA, UIConstants.BUTTON_FADE_OUT_DURATION)
  
  # Set visibility to false after animation completes
  hide_tween.tween_callback(func():
    for button in action_buttons:
      button.visible = false
    is_animating = false
  ).set_delay(UIConstants.BUTTON_FADE_OUT_DURATION)
