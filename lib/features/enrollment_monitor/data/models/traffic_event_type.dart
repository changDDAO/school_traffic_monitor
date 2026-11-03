import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 백엔드 TrafficEventType과 이름이 1:1로 같아야 합니다.
enum TrafficEventType {
  published('발행', AppColors.publish, Icons.upload_rounded),
  completed('처리 완료', AppColors.complete, Icons.check_circle_rounded),
  rejected('거절', AppColors.reject, Icons.block_rounded),
  error('오류·재시도', AppColors.error, Icons.replay_rounded),
  deadLettered('DLQ', AppColors.dead, Icons.report_rounded);

  const TrafficEventType(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  /// "DEAD_LETTERED" → deadLettered
  static TrafficEventType? fromServer(String? value) {
    switch (value) {
      case 'PUBLISHED':
        return TrafficEventType.published;
      case 'COMPLETED':
        return TrafficEventType.completed;
      case 'REJECTED':
        return TrafficEventType.rejected;
      case 'ERROR':
        return TrafficEventType.error;
      case 'DEAD_LETTERED':
        return TrafficEventType.deadLettered;
    }
    return null;
  }
}
