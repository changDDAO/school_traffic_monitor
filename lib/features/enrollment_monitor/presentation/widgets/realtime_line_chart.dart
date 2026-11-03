import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/traffic_snapshot.dart';

/// 차트 한 줄의 정의 (이름, 색, 스냅샷에서 값 꺼내는 함수)
class ChartSeries {
  const ChartSeries({required this.label, required this.color, required this.value, this.filled = false});

  final String label;
  final Color color;
  final double Function(TrafficSnapshot s) value;
  final bool filled;
}

/// 최근 60초를 x축(-59 ~ 0초)으로 그리는 공통 라인 차트
class RealtimeLineChart extends StatelessWidget {
  const RealtimeLineChart({
    super.key,
    required this.history,
    required this.series,
    this.height = 180,
    this.minMaxY = 10,
  });

  final List<TrafficSnapshot> history;
  final List<ChartSeries> series;
  final double height;

  /// 트래픽이 없어도 y축이 0~minMaxY는 유지되도록
  final double minMaxY;

  @override
  Widget build(BuildContext context) {
    const window = AppConfig.chartWindowSeconds;
    final points = history.length > window ? history.sublist(history.length - window) : history;
    final offset = points.length - 1;

    double peak = 0;
    for (final s in points) {
      for (final line in series) {
        peak = math.max(peak, line.value(s));
      }
    }
    final maxY = _niceCeil(math.max(peak * 1.15, minMaxY));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [for (final line in series) _Legend(label: line.label, color: line.color)],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minX: -window.toDouble(),
              maxX: 0,
              minY: 0,
              maxY: maxY,
              clipData: FlClipData.all(),
              lineTouchData: LineTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 15,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        value == 0 ? '지금' : '${value.toInt()}s',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                for (final line in series)
                  LineChartBarData(
                    // 가장 최근 값이 x=0, 1초 전이 x=-1 ...
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot((i - offset).toDouble(), line.value(points[i])),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: line.color,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: line.filled,
                      color: line.color.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
            // 매초 새 데이터가 들어오므로 애니메이션 없이 즉시 갱신
            duration: Duration.zero,
          ),
        ),
      ],
    );
  }

  /// 7 → 10, 23 → 25, 140 → 150 처럼 축 눈금이 깔끔하게 떨어지도록 올림
  static double _niceCeil(double value) {
    final exponent = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    for (final step in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (value <= step * exponent) return step * exponent;
    }
    return 10 * exponent;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 3, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
