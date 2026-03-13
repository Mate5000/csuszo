import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement_result.dart';

/// Chart showing raw Y-axis acceleration over time with phase highlights.
class AccelChart extends StatelessWidget {
  final MeasurementResult result;

  const AccelChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.rawYData.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    final spots = <FlSpot>[];
    for (int i = 0; i < result.rawYData.length; i++) {
      // x = idő másodpercben (20 Hz → 0.05s/sample)
      spots.add(FlSpot(i * 0.05, result.rawYData[i] * 9.80665));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Y tengely gyorsulás',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(1)}s',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: colorScheme.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Y tengely gyorsulás (m/s²) az idő függvényében',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
