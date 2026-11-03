/// 부하 생성기 상태 (POST/DELETE/GET /api/school/monitor/load)
class LoadStatus {
  const LoadStatus({
    required this.running,
    required this.total,
    required this.sent,
    required this.ratePerSecond,
  });

  final bool running;
  final int total;
  final int sent;
  final int ratePerSecond;

  static const idle = LoadStatus(running: false, total: 0, sent: 0, ratePerSecond: 0);

  double get progress => total == 0 ? 0 : (sent / total).clamp(0, 1).toDouble();

  factory LoadStatus.fromJson(Map<String, dynamic> json) => LoadStatus(
        running: json['running'] as bool,
        total: (json['total'] as num).toInt(),
        sent: (json['sent'] as num).toInt(),
        ratePerSecond: (json['ratePerSecond'] as num).toInt(),
      );
}
