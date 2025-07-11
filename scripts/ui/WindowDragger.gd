class_name WindowDragger
extends RefCounted

# === WINDOW DRAGGING COMPONENT ===

signal window_mouse_entered
signal window_mouse_exited

var is_dragging: bool = false
var mouse_initial_pos: Vector2 = Vector2.ZERO
var parent_node: Control

func _init(parent: Control):
  """Initialize window dragger"""
  parent_node = parent
  # Connect mouse signals for window hover detection
  parent_node.mouse_entered.connect(_on_window_mouse_entered)
  parent_node.mouse_exited.connect(_on_window_mouse_exited)

func handle_gui_input(event: InputEvent) -> void:
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
    var window: Window = parent_node.get_window()
    var global_mouse_pos: Vector2 = event.global_position
    var position_delta: Vector2 = global_mouse_pos - mouse_initial_pos
    window.position += Vector2i(position_delta)

func _on_window_mouse_entered() -> void:
  """Emit signal when mouse enters window area"""
  window_mouse_entered.emit()

func _on_window_mouse_exited() -> void:
  """Emit signal when mouse exits window area"""
  window_mouse_exited.emit()
