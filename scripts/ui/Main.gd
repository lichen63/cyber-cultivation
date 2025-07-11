extends Control

# === REFACTORED MAIN UI CONTROLLER ===

# Import all component modules
const UIConstants = preload("res://scripts/ui/UIConstants.gd")
const KeyboardDisplay = preload("res://scripts/ui/KeyboardDisplay.gd")
const MouseMonitor = preload("res://scripts/ui/MouseMonitor.gd")
const ActionButtons = preload("res://scripts/ui/ActionButtons.gd")
const WindowDragger = preload("res://scripts/ui/WindowDragger.gd")

# Node references
@onready var character_node: TextureRect = $Character

# Component instances
var keyboard_display: KeyboardDisplay
var mouse_monitor: MouseMonitor
var action_buttons: ActionButtons
var window_dragger: WindowDragger

# === LIFECYCLE METHODS ===

func _ready() -> void:
  # Enable transparent background
  get_viewport().transparent_bg = true
  get_window().transparent = true
  
  # Enable drawing for border
  set_process(true)
  
  # Initialize all components
  initialize_components()

func initialize_components() -> void:
  """Initialize all UI components"""
  # Create keyboard display
  keyboard_display = KeyboardDisplay.new()
  keyboard_display.position_display(get_window().size)
  add_child(keyboard_display)
  
  # Create mouse monitoring area
  mouse_monitor = MouseMonitor.new()
  mouse_monitor.position_monitor(get_window().size)
  add_child(mouse_monitor)
  
  # Initialize mouse point position based on current mouse position
  mouse_monitor.update_mouse_point_position()
  
  # Create action buttons system
  action_buttons = ActionButtons.new(self)
  action_buttons.create_buttons()
  action_buttons.button_pressed.connect(_on_action_button_pressed)
  
  # Create window dragger
  window_dragger = WindowDragger.new(self)
  window_dragger.window_mouse_entered.connect(_on_window_mouse_entered)
  window_dragger.window_mouse_exited.connect(_on_window_mouse_exited)

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
  """Handle all input events - keyboard and global mouse monitoring"""
  if event is InputEventKey and event.pressed:
    keyboard_display.update_display(event)
  elif event is InputEventMouseMotion:
    # Global mouse movement monitoring
    mouse_monitor.update_mouse_point_position()

func _gui_input(event: InputEvent) -> void:
  """Handle mouse input for window dragging only"""
  window_dragger.handle_gui_input(event)

# === DRAWING ===

func _draw() -> void:
  """Draw the window border"""
  # Get the window size
  var window_size = get_window().size
  
  # Draw white border
  draw_rect(Rect2(0, 0, window_size.x, UIConstants.BORDER_WIDTH), UIConstants.BORDER_COLOR) # Top
  draw_rect(Rect2(0, window_size.y - UIConstants.BORDER_WIDTH, window_size.x, UIConstants.BORDER_WIDTH), UIConstants.BORDER_COLOR) # Bottom
  draw_rect(Rect2(0, 0, UIConstants.BORDER_WIDTH, window_size.y), UIConstants.BORDER_COLOR) # Left
  draw_rect(Rect2(window_size.x - UIConstants.BORDER_WIDTH, 0, UIConstants.BORDER_WIDTH, window_size.y), UIConstants.BORDER_COLOR) # Right

# === EVENT HANDLERS ===

func _on_window_mouse_entered() -> void:
  """Show action buttons when mouse enters window area"""
  action_buttons.show_buttons()

func _on_window_mouse_exited() -> void:
  """Hide action buttons when mouse exits window area"""
  action_buttons.hide_buttons()

func _on_action_button_pressed(button_index: int) -> void:
  """Handle action button presses - placeholder for future functionality"""
  var button_names = ["Top-1", "Top-2", "Bottom-1", "Bottom-2"]
  print("Action button pressed: ", button_names[button_index])
  # TODO: Implement specific functionality for each action button
