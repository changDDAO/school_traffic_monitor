import 'package:flutter_test/flutter_test.dart';
import 'package:school_traffic_monitor/features/enrollment_monitor/data/models/traffic_event.dart';
import 'package:school_traffic_monitor/features/enrollment_monitor/data/models/traffic_event_type.dart';
import 'package:school_traffic_monitor/features/enrollment_monitor/data/models/traffic_snapshot.dart';

void main() {
  test('서버 스냅샷 JSON을 파싱한다', () {
    final snapshot = TrafficSnapshot.fromJson({
      'timestamp': 1762070400000,
      'brokerUp': true,
      'publishRate': 120.0,
      'completeRate': 80,
      'rejectRate': 5.5,
      'errorRate': 0,
      'deadLetterRate': 0,
      'inFlight': 7,
      'activeConsumers': 10,
      'maxConsumers': 10,
      'queues': [
        {'name': 'school.enrollment.queue', 'role': 'MAIN', 'ready': 340, 'consumers': 10},
        {'name': 'school.enrollment.dlq', 'role': 'DLQ', 'ready': 2, 'consumers': 1},
      ],
      'totals': {'PUBLISHED': 1000, 'COMPLETED': 650, 'DEAD_LETTERED': 2},
    });

    expect(snapshot.mainQueue?.ready, 340);
    expect(snapshot.deadLetterQueue?.ready, 2);
    expect(snapshot.consumeRate, 85.5);
    expect(snapshot.total(TrafficEventType.deadLettered), 2);
    expect(snapshot.total(TrafficEventType.rejected), 0);
  });

  test('모르는 이벤트 타입은 건너뛴다', () {
    final events = TrafficEvent.parseList([
      {'type': 'PUBLISHED', 'requestId': 'abc', 'studentId': 3, 'timestamp': 1762070400000},
      {'type': 'SOMETHING_NEW', 'requestId': 'def', 'timestamp': 1762070400000},
    ]);
    expect(events, hasLength(1));
    expect(events.first.type, TrafficEventType.published);
  });
}
