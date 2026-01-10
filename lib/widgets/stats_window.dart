import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import '../constants.dart';
import '../models/daily_stats.dart';
import 'dart:math';

class StatsWindow extends StatefulWidget {
  final DailyStats todayStats;
  final Map<String, DailyStats> historyStats;

  const StatsWindow({
    super.key,
    required this.todayStats,
    required this.historyStats,
  });

  @override
  State<StatsWindow> createState() => _StatsWindowState();
}

class _StatsWindowState extends State<StatsWindow> {
  bool isLast7Days = true;
  String metric = 'keyboard'; // keyboard, click, move

  // Colors
  final Color primaryColor = const Color(0xFF66BB6A); // Greenish
  final Color secondaryColor = const Color(0xFF424242);
  final Color textColor = Colors.white;

  String _formatNumber(num value) {
    if (value >= 1000000000000) {
      return '${(value / 1000000000000).toStringAsFixed(1)}T';
    } else if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      if (value is int || value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
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
          color: const Color(0xFF2C2C2E).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTodaySummary(),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.statsHistoryTrends,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
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
      decoration: const BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.only(
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
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
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
              "${_formatNumber(_pixelsToMeters(widget.todayStats.mouseMoveDistance))} m",
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
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 28),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
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
              style: const TextStyle(color: Colors.white54, fontSize: 13),
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
          color: isActive ? primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
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
          child: Text(AppLocalizations.of(context)!.noDataAvailable, style: TextStyle(color: textColor)),
        ),
      );
    }

    double maxY = 0;
    for (var p in dataPoints) {
      if (p.y > maxY) maxY = p.y;
    }
    if (maxY == 0) maxY = 10;

    // Add nice interval
    double interval = maxY / 5;
    if (interval == 0) interval = 1;

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
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.white10, strokeWidth: 1),
              getDrawingVerticalLine: (value) =>
                  FlLine(color: Colors.white10, strokeWidth: 1),
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
                  interval: 1,
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
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
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
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _formatNumber(value),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (dataPoints.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: dataPoints,
                isCurved: true,
                preventCurveOverShooting: true,
                color: primaryColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: primaryColor.withOpacity(0.2),
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
          value = _pixelsToMeters(stats.mouseMoveDistance);
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
