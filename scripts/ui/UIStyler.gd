class_name UIStyler
extends RefCounted

# === UI STYLING UTILITIES ===

const UIConstants = preload("res://scripts/ui/UIConstants.gd")

static func create_keyboard_display_style() -> StyleBoxFlat:
  """Create background style for keyboard display"""
  var style_background = StyleBoxFlat.new()
  style_background.bg_color = UIConstants.BACKGROUND_COLOR
  style_background.border_width_left = UIConstants.BORDER_WIDTH
  style_background.border_width_right = UIConstants.BORDER_WIDTH
  style_background.border_width_top = UIConstants.BORDER_WIDTH
  style_background.border_width_bottom = UIConstants.BORDER_WIDTH
  style_background.border_color = UIConstants.ACCENT_COLOR
  style_background.corner_radius_top_left = UIConstants.SMALL_CORNER_RADIUS
  style_background.corner_radius_top_right = UIConstants.SMALL_CORNER_RADIUS
  style_background.corner_radius_bottom_left = UIConstants.SMALL_CORNER_RADIUS
  style_background.corner_radius_bottom_right = UIConstants.SMALL_CORNER_RADIUS
  return style_background

static func create_button_normal_style() -> StyleBoxFlat:
  """Create normal state style for buttons"""
  var style_normal = StyleBoxFlat.new()
  style_normal.bg_color = UIConstants.BUTTON_BG_COLOR
  style_normal.border_width_left = UIConstants.BORDER_WIDTH
  style_normal.border_width_right = UIConstants.BORDER_WIDTH
  style_normal.border_width_top = UIConstants.BORDER_WIDTH
  style_normal.border_width_bottom = UIConstants.BORDER_WIDTH
  style_normal.border_color = UIConstants.ACCENT_COLOR
  style_normal.corner_radius_top_left = UIConstants.CORNER_RADIUS
  style_normal.corner_radius_top_right = UIConstants.CORNER_RADIUS
  style_normal.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
  style_normal.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
  style_normal.shadow_color = Color(0, 0, 0, 0.3)
  style_normal.shadow_size = UIConstants.SHADOW_SIZE
  style_normal.shadow_offset = UIConstants.SHADOW_OFFSET
  return style_normal

static func create_button_hover_style() -> StyleBoxFlat:
  """Create hover state style for buttons"""
  var style_hover = StyleBoxFlat.new()
  style_hover.bg_color = UIConstants.BUTTON_HOVER_COLOR
  style_hover.border_width_left = UIConstants.BORDER_WIDTH
  style_hover.border_width_right = UIConstants.BORDER_WIDTH
  style_hover.border_width_top = UIConstants.BORDER_WIDTH
  style_hover.border_width_bottom = UIConstants.BORDER_WIDTH
  style_hover.border_color = Color(0.5, 0.7, 1.0, 1.0) # Brighter blue border
  style_hover.corner_radius_top_left = UIConstants.CORNER_RADIUS
  style_hover.corner_radius_top_right = UIConstants.CORNER_RADIUS
  style_hover.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
  style_hover.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
  style_hover.shadow_color = Color(0, 0, 0, 0.4)
  style_hover.shadow_size = UIConstants.SHADOW_SIZE + 2
  style_hover.shadow_offset = UIConstants.SHADOW_OFFSET
  return style_hover

static func create_button_pressed_style() -> StyleBoxFlat:
  """Create pressed state style for buttons"""
  var style_pressed = StyleBoxFlat.new()
  style_pressed.bg_color = UIConstants.BUTTON_PRESSED_COLOR
  style_pressed.border_width_left = UIConstants.BORDER_WIDTH
  style_pressed.border_width_right = UIConstants.BORDER_WIDTH
  style_pressed.border_width_top = UIConstants.BORDER_WIDTH
  style_pressed.border_width_bottom = UIConstants.BORDER_WIDTH
  style_pressed.border_color = Color(0.3, 0.5, 0.8, 1.0) # Darker blue border
  style_pressed.corner_radius_top_left = UIConstants.CORNER_RADIUS
  style_pressed.corner_radius_top_right = UIConstants.CORNER_RADIUS
  style_pressed.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
  style_pressed.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
  style_pressed.shadow_color = Color(0, 0, 0, 0.2)
  style_pressed.shadow_size = UIConstants.SHADOW_SIZE / 2.0
  style_pressed.shadow_offset = Vector2(1, 1)
  return style_pressed

static func create_mouse_monitor_style() -> StyleBoxFlat:
  """Create style for mouse monitor area"""
  var area_style = StyleBoxFlat.new()
  area_style.bg_color = Color(0.15, 0.15, 0.25, 0.8) # Dark background
  area_style.border_width_left = UIConstants.BORDER_WIDTH
  area_style.border_width_right = UIConstants.BORDER_WIDTH
  area_style.border_width_top = UIConstants.BORDER_WIDTH
  area_style.border_width_bottom = UIConstants.BORDER_WIDTH
  area_style.border_color = UIConstants.ACCENT_COLOR
  area_style.corner_radius_top_left = UIConstants.CORNER_RADIUS
  area_style.corner_radius_top_right = UIConstants.CORNER_RADIUS
  area_style.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
  area_style.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
  return area_style
