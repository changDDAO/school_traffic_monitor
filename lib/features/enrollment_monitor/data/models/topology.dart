/// GET /api/school/monitor/topology — 흐름도에 표시할 이름과 리스너 설정
class Topology {
  const Topology({
    required this.exchange,
    required this.routingKey,
    required this.queue,
    required this.deadLetterExchange,
    required this.deadLetterRoutingKey,
    required this.deadLetterQueue,
    required this.concurrency,
    required this.maxConcurrency,
    required this.prefetch,
    required this.maxAttempts,
  });

  final String exchange;
  final String routingKey;
  final String queue;
  final String deadLetterExchange;
  final String deadLetterRoutingKey;
  final String deadLetterQueue;
  final int concurrency;
  final int maxConcurrency;
  final int prefetch;
  final int maxAttempts;

  /// 서버에 연결되기 전에 보여줄 기본값 (RabbitMQConfig와 동일)
  static const fallback = Topology(
    exchange: 'school.enrollment.exchange',
    routingKey: 'enrollment.request',
    queue: 'school.enrollment.queue',
    deadLetterExchange: 'school.enrollment.dlx',
    deadLetterRoutingKey: 'enrollment.dead',
    deadLetterQueue: 'school.enrollment.dlq',
    concurrency: 3,
    maxConcurrency: 10,
    prefetch: 10,
    maxAttempts: 3,
  );

  factory Topology.fromJson(Map<String, dynamic> json) => Topology(
        exchange: json['exchange'] as String,
        routingKey: json['routingKey'] as String,
        queue: json['queue'] as String,
        deadLetterExchange: json['deadLetterExchange'] as String,
        deadLetterRoutingKey: json['deadLetterRoutingKey'] as String,
        deadLetterQueue: json['deadLetterQueue'] as String,
        concurrency: (json['concurrency'] as num).toInt(),
        maxConcurrency: (json['maxConcurrency'] as num).toInt(),
        prefetch: (json['prefetch'] as num).toInt(),
        maxAttempts: (json['maxAttempts'] as num).toInt(),
      );
}
