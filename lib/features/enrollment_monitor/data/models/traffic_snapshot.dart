import 'queue_metric.dart';
import 'traffic_event_type.dart';

/// 1초마다 들어오는 트래픽 스냅샷 (/sub/school/monitor/traffic)
class TrafficSnapshot {
  const TrafficSnapshot({
    required this.timestamp,
    required this.brokerUp,
    required this.publishRate,
    required this.completeRate,
    required this.rejectRate,
    required this.errorRate,
    required this.deadLetterRate,
    required this.inFlight,
    required this.activeConsumers,
    required this.maxConsumers,
    required this.queues,
    required this.totals,
  });

  final DateTime timestamp;
  final bool brokerUp;
  final double publishRate;
  final double completeRate;
  final double rejectRate;
  final double errorRate;
  final double deadLetterRate;
  final int inFlight;
  final int activeConsumers;
  final int maxConsumers;
  final List<QueueMetric> queues;
  final Map<TrafficEventType, int> totals;

  QueueMetric? get mainQueue => _queueByRole('MAIN');
  QueueMetric? get deadLetterQueue => _queueByRole('DLQ');

  /// 큐에서 빠져나가는 속도 (완료 + 거절)
  double get consumeRate => completeRate + rejectRate;

  int total(TrafficEventType type) => totals[type] ?? 0;

  QueueMetric? _queueByRole(String role) {
    for (final q in queues) {
      if (q.role == role) return q;
    }
    return null;
  }

  factory TrafficSnapshot.fromJson(Map<String, dynamic> json) {
    final rawTotals = json['totals'] as Map<String, dynamic>? ?? const {};
    final totals = <TrafficEventType, int>{};
    rawTotals.forEach((key, value) {
      final type = TrafficEventType.fromServer(key);
      if (type != null) totals[type] = (value as num).toInt();
    });

    return TrafficSnapshot(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt()),
      brokerUp: json['brokerUp'] as bool? ?? false,
      publishRate: _double(json['publishRate']),
      completeRate: _double(json['completeRate']),
      rejectRate: _double(json['rejectRate']),
      errorRate: _double(json['errorRate']),
      deadLetterRate: _double(json['deadLetterRate']),
      inFlight: (json['inFlight'] as num? ?? 0).toInt(),
      activeConsumers: (json['activeConsumers'] as num? ?? 0).toInt(),
      maxConsumers: (json['maxConsumers'] as num? ?? 0).toInt(),
      queues: (json['queues'] as List<dynamic>? ?? const [])
          .map((e) => QueueMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: totals,
    );
  }

  static List<TrafficSnapshot> parseList(dynamic json) {
    if (json is! List) return const [];
    return json.whereType<Map<String, dynamic>>().map(TrafficSnapshot.fromJson).toList();
  }

  static double _double(dynamic value) => (value as num? ?? 0).toDouble();
}
