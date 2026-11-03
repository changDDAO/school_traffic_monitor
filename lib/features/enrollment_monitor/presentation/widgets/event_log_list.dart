import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/traffic_event.dart';
import '../../data/models/traffic_event_type.dart';

/// 상단 필터 칩 (선택 없으면 전체)
class EventFilterBar extends StatelessWidget {
  const EventFilterBar({super.key, required this.selected, required this.onToggle, required this.onClear});

  final Set<TrafficEventType> selected;
  final ValueChanged<TrafficEventType> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('전체'),
            selected: selected.isEmpty,
            onSelected: (_) => onClear(),
          ),
          for (final type in TrafficEventType.values) ...[
            const SizedBox(width: 6),
            FilterChip(
              avatar: Icon(type.icon, size: 16, color: type.color),
              label: Text(type.label),
              selected: selected.contains(type),
              selectedColor: type.color.withValues(alpha: 0.2),
              onSelected: (_) => onToggle(type),
            ),
          ],
        ],
      ),
    );
  }
}

/// 이벤트 한 줄씩 (최신이 위)
class EventLogList extends StatelessWidget {
  const EventLogList({super.key, required this.events});

  final List<TrafficEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '아직 이벤트가 없습니다.\n대시보드 탭에서 테스트 트래픽을 보내 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) => _EventTile(event: events[index]),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final TrafficEvent event;

  @override
  Widget build(BuildContext context) {
    final type = event.type;
    final shortId = event.requestId.length > 8 ? event.requestId.substring(0, 8) : event.requestId;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: type.color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(type.icon, color: type.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(type.label,
                        style: TextStyle(color: type.color, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('학생 ${event.studentId ?? '-'}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    const Spacer(),
                    Text(formatTime(event.timestamp),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
                if (event.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(event.detail!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                ],
                const SizedBox(height: 2),
                Text('#$shortId · ${event.thread ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
