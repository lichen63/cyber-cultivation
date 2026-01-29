/// Constants for menu bar popup
class MenuBarPopupConstants {
  MenuBarPopupConstants._();

  static const double popupWidth = 340.0;

  /// For disk/network with extra columns
  static const double popupWidthWide = 400.0;
  static const double popupBorderRadius = 6.0;
  static const double popupPadding = 8.0;

  // Title bar
  static const double titleBarHeight = 28.0;
  static const double titleBarIconSize = 14.0;
  static const double titleFontSize = 12.0;

  // Content area
  static const double contentMinHeight = 80.0;

  // CPU processes
  static const int topProcessesCount = 5;
  static const double processNameFontSize = 11.0;

  /// Includes vertical padding from InkWell
  static const double processRowHeight = 21.0;
  static const double processRowSpacing = 4.0;
  static const double headerFontSize = 10.0;
  static const double headerBottomSpacing = 6.0;

  // Column widths for multi-column layouts
  static const double valueColumnWidth = 70.0;
  static const double pidColumnWidth = 45.0;

  /// Calculate total popup height for default content
  static double get popupHeight {
    return titleBarHeight + contentMinHeight + (popupPadding * 2);
  }

  /// Calculate popup height for medium content (3-4 rows)
  static double get popupHeightMedium {
    return titleBarHeight + 120 + (popupPadding * 2);
  }

  /// Calculate popup height for CPU processes
  static double get cpuPopupHeight {
    // Header row + spacing + process rows + separator + extra padding
    final contentHeight =
        headerFontSize +
        headerBottomSpacing +
        (processRowHeight * topProcessesCount) +
        (processRowSpacing * (topProcessesCount - 1)) +
        (popupPadding * 2) +
        40; // Extra padding for separator, borders, and rounding
    return titleBarHeight + contentHeight;
  }

  // Network info section
  static const double networkInfoRowHeight = 18.0;
  static const int networkInfoRowCount =
      6; // Interface, Name, Local IP, Public IP, MAC, Gateway
  static const double networkInfoSectionSpacing = 10.0;

  /// Calculate popup height for network popup (includes both info and processes)
  static double get networkPopupHeight {
    // Network info section
    final networkInfoHeight =
        (networkInfoRowHeight * networkInfoRowCount) +
        networkInfoSectionSpacing;
    // Process list section (header + process rows)
    final processListHeight =
        headerFontSize +
        headerBottomSpacing +
        (processRowHeight * topProcessesCount) +
        (processRowSpacing * (topProcessesCount - 1));
    // Total with padding
    return titleBarHeight +
        networkInfoHeight +
        processListHeight +
        (popupPadding * 3) +
        30; // Extra for separators and borders
  }
}
