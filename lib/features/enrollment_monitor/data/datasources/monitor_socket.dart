import 'dart:async';

import '../../../../core/network/stomp_socket.dart';
import '../models/traffic_event.dart';
import '../models/traffic_snapshot.dart';

/// WebSocket(STOMP): /ws-school-monitor
///  - /sub/school/monitor/traffic : TrafficSnapshot (1초마다)
///  - /sub/school/monitor/events  : List<TrafficEvent> (1초 묶음)
class MonitorSocket {
  MonitorSocket(this._socket) {
    _socket.subscribe(_trafficTopic, (json) {
      if (json is Map<String, dynamic>) {
        _snapshots.add(TrafficSnapshot.fromJson(json));
      }
    });
    _socket.subscribe(_eventsTopic, (json) {
      final events = TrafficEvent.parseList(json);
      if (events.isNotEmpty) _events.add(events);
    });
  }

  static const _trafficTopic = '/sub/school/monitor/traffic';
  static const _eventsTopic = '/sub/school/monitor/events';

  final StompSocket _socket;
  final _snapshots = StreamController<TrafficSnapshot>.broadcast();
  final _events = StreamController<List<TrafficEvent>>.broadcast();

  Stream<TrafficSnapshot> get snapshots => _snapshots.stream;
  Stream<List<TrafficEvent>> get events => _events.stream;
  Stream<SocketStatus> get status => _socket.statusStream;

  void connect() => _socket.connect();

  void dispose() {
    _socket.dispose();
    _snapshots.close();
    _events.close();
  }
}
