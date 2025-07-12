class_name CultivationStatus
extends RefCounted

# === CULTIVATION STATUS COMPONENT ===

const UIConstants = preload("res://scripts/ui/UIConstants.gd")
const UIStyler = preload("res://scripts/ui/UIStyler.gd")

# Constants
const LEVEL_PREFIX = "Lv. "

# Configuration
var max_exp_per_level: Array[int] = [] # Different max exp for each level
var max_level: int = 100
var current_exp: int = 0
var current_level: int = 1

# UI Components
var container: Control
var level_label: Label
var exp_bar: ProgressBar
var exp_label: Label

func _init():
  """Initialize cultivation status system"""
  
  # Set default values
  max_level = 100
  current_exp = 0
  current_level = 1
  
  # Initialize default max exp per level (unified exponential growth formula)
  max_exp_per_level = []
  for level in range(1, max_level + 1):
    var base_exp = 10 # Starting from 10 exp for level 1
    # Single formula for all levels - exponential growth gets dramatically harder at higher levels
    var exp_for_level = int(base_exp * pow(1.2, level - 1))
    max_exp_per_level.append(exp_for_level)

func create_ui(window_size: Vector2) -> Control:
  """Create the cultivation status UI in the top area and return the container"""
  
  # Create main container
  container = Control.new()
  container.name = "CultivationStatusContainer"
  container.size = Vector2(window_size.x - (2 * UIConstants.MARGIN), 60)
  container.position = Vector2(UIConstants.MARGIN, UIConstants.MARGIN)
  
  # Create experience bar (horizontally centered)
  var bar_width = 400 # Fixed width for the progress bar
  exp_bar = ProgressBar.new()
  exp_bar.min_value = 0
  exp_bar.max_value = get_current_level_max_exp()
  exp_bar.value = current_exp
  exp_bar.size = Vector2(bar_width, 30)
  exp_bar.position = Vector2((container.size.x - bar_width) / 2, 5) # Centered horizontally
  exp_bar.show_percentage = false # Hide default percentage
  style_progress_bar(exp_bar)
  
  # Create level label (positioned to the left of the status bar)
  level_label = Label.new()
  level_label.text = LEVEL_PREFIX + str(current_level)
  level_label.size = Vector2(100, 30)
  level_label.position = Vector2(exp_bar.position.x - 70, 4) # Aligned with exp_bar center
  style_label(level_label)
  
  # Create experience text overlay on the progress bar
  exp_label = Label.new()
  exp_label.text = str(current_exp) + "/" + str(get_current_level_max_exp())
  exp_label.size = exp_bar.size
  exp_label.position = Vector2(0, 0) # Relative to exp_bar
  exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  exp_label.add_theme_color_override("font_color", Color.WHITE)
  exp_label.add_theme_font_size_override("font_size", 24)
  exp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE # Allow clicks to pass through
  
  # Add exp_label as child of exp_bar to overlay the text
  exp_bar.add_child(exp_label)
  
  # Add components to container
  container.add_child(level_label)
  container.add_child(exp_bar)
  
  # Return container to be added by caller
  return container

func style_label(label: Label) -> void:
  """Apply styling to labels"""
  label.add_theme_color_override("font_color", UIConstants.TEXT_COLOR)
  label.add_theme_font_size_override("font_size", 24) # Increased from 18 to 24
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func style_progress_bar(progress_bar: ProgressBar) -> void:
  """Apply beautiful styling to the progress bar"""
  # Create background style
  var bg_style = StyleBoxFlat.new()
  bg_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
  bg_style.border_width_left = 1
  bg_style.border_width_right = 1
  bg_style.border_width_top = 1
  bg_style.border_width_bottom = 1
  bg_style.border_color = Color(0.5, 0.5, 0.7, 1.0)
  bg_style.corner_radius_top_left = 8
  bg_style.corner_radius_top_right = 8
  bg_style.corner_radius_bottom_left = 8
  bg_style.corner_radius_bottom_right = 8
  
  # Create fill style (experience bar)
  var fill_style = StyleBoxFlat.new()
  fill_style.bg_color = Color(0.3, 0.7, 1.0, 0.9) # Cyan-blue cultivation energy color
  fill_style.corner_radius_top_left = 6
  fill_style.corner_radius_top_right = 6
  fill_style.corner_radius_bottom_left = 6
  fill_style.corner_radius_bottom_right = 6
  
  # Apply styles
  progress_bar.add_theme_stylebox_override("background", bg_style)
  progress_bar.add_theme_stylebox_override("fill", fill_style)

func get_current_level_max_exp() -> int:
  """Get the max experience required for the current level"""
  if current_level <= 0 or current_level > max_exp_per_level.size():
    return 100 # Default fallback
  return max_exp_per_level[current_level - 1] # Array is 0-indexed, levels are 1-indexed

func update_experience(new_exp: int) -> void:
  """Update current experience and check for level up"""
  current_exp = new_exp
  
  # Check for level up
  while current_exp >= get_current_level_max_exp() and current_level < max_level:
    current_exp -= get_current_level_max_exp()
    current_level += 1
    # You could emit a signal here for level up effects
  
  # Clamp values
  current_exp = max(0, min(current_exp, get_current_level_max_exp()))
  current_level = max(1, min(current_level, max_level))
  
  # Update UI
  refresh_ui()

func add_experience(exp_amount: int) -> void:
  """Add experience points"""
  update_experience(current_exp + exp_amount)

func set_level(new_level: int) -> void:
  """Set current level directly"""
  current_level = max(1, min(new_level, max_level))
  refresh_ui()

func refresh_ui() -> void:
  """Refresh the UI display with current values"""
  if level_label:
    level_label.text = LEVEL_PREFIX + str(current_level)
  if exp_bar:
    exp_bar.max_value = get_current_level_max_exp()
    exp_bar.value = current_exp
    # Update the text overlay on the progress bar
    if exp_bar.get_child_count() > 0:
      var exp_text_label = exp_bar.get_child(0) as Label
      if exp_text_label:
        exp_text_label.text = str(current_exp) + "/" + str(get_current_level_max_exp())
  
  # Update progress bar max value if it exists
  if exp_bar:
    exp_bar.max_value = get_current_level_max_exp()
  
  refresh_ui()

func get_current_exp() -> int:
  """Get current experience points"""
  return current_exp

func get_current_level() -> int:
  """Get current level"""
  return current_level

func get_max_exp() -> int:
  """Get maximum experience points for current level"""
  return get_current_level_max_exp()

func get_max_level() -> int:
  """Get maximum level"""
  return max_level
