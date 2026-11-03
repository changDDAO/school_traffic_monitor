class QueueMetric {
  const QueueMetric({
    required this.name,
    required this.role,
    required this.ready,
    required this.consumers,
  });

  final String name;

  /// MAIN / DLQ
  final String role;

  /// 큐에서 대기 중인 메시지 수
  final int ready;
  final int consumers;

  bool get isDeadLetter => role == 'DLQ';

  factory QueueMetric.fromJson(Map<String, dynamic> json) => QueueMetric(
        name: json['name'] as String,
        role: json['role'] as String,
        ready: (json['ready'] as num).toInt(),
        consumers: (json['consumers'] as num).toInt(),
      );
}
