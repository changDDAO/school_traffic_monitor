import 'traffic_event_type.dart';

/// GET /api/school/monitor/events, /sub/school/monitor/events 의 원소
class TrafficEvent {
  const TrafficEvent({
    required this.type,
    required this.requestId,
    required this.studentId,
    required this.detail,
    required this.thread,
    required this.timestamp,
  });

  final TrafficEventType type;
  final String requestId;
  final int? studentId;
  final String? detail;
  final String? thread;
  final DateTime timestamp;

  /// 알 수 없는 type이면 null (서버에 타입이 추가돼도 앱이 죽지 않도록)
  static TrafficEvent? tryParse(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final type = TrafficEventType.fromServer(json['type'] as String?);
    if (type == null) return null;
    return TrafficEvent(
      type: type,
      requestId: json['requestId'] as String? ?? '-',
      studentId: (json['studentId'] as num?)?.toInt(),
      detail: json['detail'] as String?,
      thread: json['thread'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt()),
    );
  }

  static List<TrafficEvent> parseList(dynamic json) {
    if (json is! List) return const [];
    return json.map(tryParse).whereType<TrafficEvent>().toList();
  }
}
