import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/traffic_event_type.dart';
import '../../data/models/traffic_snapshot.dart';

/// 핵심 수치 4칸 + 누적 건수 한 줄
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.snapshot});

  final TrafficSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final backlog = s?.mainQueue?.ready ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: '발행',
                value: s == null ? '-' : formatRate(s.publishRate),
                unit: 'msg/s',
                color: AppColors.publish,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                label: '처리',
                value: s == null ? '-' : formatRate(s.consumeRate),
                unit: 'msg/s',
                color: AppColors.complete,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: '큐 대기',
                value: s == null ? '-' : formatCount(backlog),
                unit: '건',
                color: backlog > 100 ? AppColors.reject : AppColors.queue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                label: 'Consumer',
                value: s == null ? '-' : '${s.activeConsumers}/${s.maxConsumers}',
                unit: '처리 중 ${s?.inFlight ?? 0}',
                color: AppColors.inFlight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final type in TrafficEventType.values)
              _TotalChip(type: type, count: s?.total(type) ?? 0),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value, required this.unit, required this.color});

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.type, required this.count});

  final TrafficEventType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${type.label} ${formatCount(count)}',
        style: TextStyle(color: type.color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
