import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import '../constants.dart';
import '../models/daily_stats.dart';

class StatsWindow extends StatefulWidget {
  final DailyStats todayStats;
  final Map<String, DailyStats> historyStats;
  final AppThemeColors themeColors;
  final VoidCallback? onClearStats;

  const StatsWindow({
    super.key,
    required this.todayStats,
    required this.historyStats,
    required this.themeColors,
    this.onClearStats,
  });

  @override
  State<StatsWindow> createState() => _StatsWindowState();
}

class _StatsWindowState extends State<StatsWindow> {
  bool isLast7Days = true;
  String metric = 'keyboard'; // keyboard, click, move

  AppThemeColors get _colors => widget.themeColors;

  String _formatNumber(num value) {
    // Round to avoid floating point precision issues (e.g., 495.00000001)
    final roundedValue = (value * 100).round() / 100;

    if (roundedValue >= 1000000000000) {
      return '${(roundedValue / 1000000000000).toStringAsFixed(1)}T';
    } else if (roundedValue >= 1000000000) {
      return '${(roundedValue / 1000000000).toStringAsFixed(1)}B';
    } else if (roundedValue >= 1000000) {
      return '${(roundedValue / 1000000).toStringAsFixed(1)}M';
    } else if (roundedValue >= 1000) {
      return '${(roundedValue / 1000).toStringAsFixed(1)}K';
    } else {
      // Check if value is effectively an integer (no fractional part)
      if (roundedValue % 1 == 0) {
        return roundedValue.toInt().toString();
      }
      return roundedValue.toStringAsFixed(2);
    }
  }

  double _pixelsToMeters(double pixels) {
    // Approx 96 DPI: 1 inch = 96 px = 0.0254 m
    // 1 px = 0.0254 / 96 m ≈ 0.0002645833 m
    return pixels * 0.0002645833;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: size.width > 700 ? 700 : size.width * 0.95,
        height: size.height > 600 ? 600 : size.height * 0.9,
        decoration: BoxDecoration(
          color: _colors.dialogBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _colors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _colors.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.statsTodaysActivity,
                      style: TextStyle(
                        color: _colors.primaryText,
                        fontSize: AppConstants.fontSizeDialogTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTodaySummary(),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.statsHistoryTrends,
                      style: TextStyle(
                        color: _colors.primaryText,
                        fontSize: AppConstants.fontSizeDialogTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHistoryControls(),
                    const SizedBox(height: 16),
                    _buildChart(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _colors.overlayLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.statsTitle,
            style: TextStyle(
              color: _colors.primaryText,
              fontSize: AppConstants.fontSizeDialogTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onClearStats != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: _colors.secondaryText,
                  ),
                  tooltip: AppLocalizations.of(context)!.statsClearData,
                  onPressed: _showClearConfirmation,
                ),
              IconButton(
                icon: Icon(Icons.close, color: _colors.secondaryText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: BorderSide(color: _colors.border, width: 2),
        ),
        title: Text(
          l10n.statsClearConfirmTitle,
          style: TextStyle(color: _colors.error),
        ),
        content: Text(
          l10n.statsClearConfirmContent,
          style: TextStyle(color: _colors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancelButtonText,
              style: TextStyle(color: _colors.inactive),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onClearStats?.call();
            },
            child: Text(
              l10n.deleteButtonText,
              style: TextStyle(color: _colors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildStatCard(
              AppLocalizations.of(context)!.statsKeyboard,
              _formatNumber(widget.todayStats.keyboardCount),
              Icons.keyboard,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              AppLocalizations.of(context)!.statsClicks,
              _formatNumber(widget.todayStats.mouseClickCount),
              Icons.mouse,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              AppLocalizations.of(context)!.statsDistance,
              "${_formatNumber(_pixelsToMeters(widget.todayStats.mouseMoveDistance.toDouble()))} m",
              Icons.show_chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _colors.overlayLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _colors.chartAccent, size: 28),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: _colors.primaryText,
                    fontSize: AppConstants.fontSizeDialogStatValue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: _colors.secondaryText,
                fontSize: AppConstants.fontSizeDialogStatLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryControls() {
    return Column(
      children: [
        // Time Range
        Row(
          children: [
            Expanded(
              child: _buildToggleBtn(
                AppLocalizations.of(context)!.statsLast7Days,
                isLast7Days,
                () => setState(() => isLast7Days = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToggleBtn(
                AppLocalizations.of(context)!.statsLast30Days,
                !isLast7Days,
                () => setState(() => isLast7Days = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Metrics
        Row(
          children: [
            Expanded(
              child: _buildToggleBtn(
                AppLocalizations.of(context)!.statsKeyboard,
                metric == 'keyboard',
                () => setState(() => metric = 'keyboard'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToggleBtn(
                AppLocalizations.of(context)!.statsClicks,
                metric == 'click',
                () => setState(() => metric = 'click'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToggleBtn(
                AppLocalizations.of(context)!.statsDistance,
                metric == 'move',
                () => setState(() => metric = 'move'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _colors.chartAccent : _colors.overlayLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : _colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final dataPoints = _getDataPoints();
    if (dataPoints.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noDataAvailable,
            style: TextStyle(color: _colors.primaryText),
          ),
        ),
      );
    }

    double maxY = 0;
    for (var p in dataPoints) {
      if (p.y > maxY) maxY = p.y;
    }
    if (maxY == 0) maxY = 10;

    // Add nice interval - use integer intervals for keyboard/click metrics
    double interval = maxY / 5;
    if (interval == 0) interval = 1;
    // For keyboard and click metrics, round up to whole numbers
    if (metric != 'move') {
      interval = interval.ceilToDouble();
      if (interval < 1) interval = 1;
    }

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, right: 20),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: _colors.border.withValues(alpha: 0.1),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: _colors.border.withValues(alpha: 0.1),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: isLast7Days ? 1 : 5,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < dataPoints.length) {
                      // Show partial date
                      // We used day index as X.
                      // But wait, the chart x axis must map to dates.
                      // I will iterate dates and use index.
                      final dateStr = _getDateForIndex(index);
                      if (dateStr == null) return const SizedBox.shrink();
                      final date = DateTime.parse(dateStr);
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          DateFormat('MM/dd').format(date),
                          style: TextStyle(
                            color: _colors.secondaryText,
                            fontSize: AppConstants.fontSizeDialogHint,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    // For keyboard/click, show integers; for distance, show with suffix
                    String label;
                    if (metric == 'move') {
                      label = '${_formatNumber(value)} m';
                    } else {
                      label = _formatNumber(value.round());
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: _colors.secondaryText,
                          fontSize: AppConstants.fontSizeDialogHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    );
                  },
                  reservedSize: 60,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (dataPoints.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.1,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final suffix = metric == 'move' ? ' m' : '';
                    return LineTooltipItem(
                      '${spot.y.round()}$suffix',
                      TextStyle(
                        color: _colors.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: dataPoints,
                isCurved: true,
                preventCurveOverShooting: true,
                color: _colors.chartAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: _colors.chartAccent.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getDataPoints() {
    final days = isLast7Days ? 7 : 30;
    final now = DateTime.now();
    List<FlSpot> spots = [];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final stats = widget.historyStats[key]; // Can be null

      double value = 0;
      if (stats != null) {
        if (metric == 'keyboard') {
          value = stats.keyboardCount.toDouble();
        } else if (metric == 'click') {
          value = stats.mouseClickCount.toDouble();
        } else if (metric == 'move') {
          value = _pixelsToMeters(stats.mouseMoveDistance.toDouble());
        }
      }

      // X = index (0 to days-1)
      spots.add(FlSpot((days - 1 - i).toDouble(), value));
    }
    return spots;
  }

  String? _getDateForIndex(int index) {
    final days = isLast7Days ? 7 : 30;
    final now = DateTime.now();
    // Logic: index 0 is (days-1) days ago. index (days-1) is today (0 days ago).
    // In _getDataPoints: x = (days - 1 - i). i goes from days-1 to 0.
    // When i = days-1 (oldest), x = 0.
    // When i = 0 (today), x = days - 1.

    // So to get date from x=index:
    // index = days - 1 - i  => i = days - 1 - index.
    // date = now.subtract(Duration(days: i));

    if (index < 0 || index >= days) return null;

    final i = days - 1 - index;
    final date = now.subtract(Duration(days: i));
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
