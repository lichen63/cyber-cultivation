class_name KeyboardDisplay
extends Label

# === KEYBOARD DISPLAY COMPONENT ===

const UIConstants = preload("res://scripts/ui/UIConstants.gd")
const UIStyler = preload("res://scripts/ui/UIStyler.gd")

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

var last_key_text: String = ""

func _init():
  """Initialize keyboard display"""
  text = "..."
  size = Vector2(UIConstants.KEYBOARD_DISPLAY_WIDTH, UIConstants.KEYBOARD_DISPLAY_HEIGHT)
  
  # Style the label
  setup_styling()
  
  # Set larger font size
  add_theme_font_size_override("font_size", UIConstants.KEYBOARD_DISPLAY_FONT_SIZE)

func setup_styling() -> void:
  """Apply styling to keyboard display label"""
  # Apply background style
  add_theme_stylebox_override("normal", UIStyler.create_keyboard_display_style())
  
  # Set text properties
  add_theme_color_override("font_color", UIConstants.TEXT_COLOR)
  horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func position_display(window_size: Vector2) -> void:
  """Position keyboard display relative to window"""
  position = Vector2(
    UIConstants.MARGIN, # Margin from left edge
    window_size.y / UIConstants.WINDOW_HEIGHT_THIRD - size.y / 2.0 # 1/3 height position, centered
  )

func update_display(event: InputEventKey) -> void:
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
  text = key_string
