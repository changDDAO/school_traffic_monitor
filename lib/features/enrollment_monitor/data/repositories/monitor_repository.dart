import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/stomp_socket.dart';
import '../datasources/monitor_api.dart';
import '../datasources/monitor_socket.dart';
import '../models/load_status.dart';
import '../models/topology.dart';
import '../models/traffic_event.dart';
import '../models/traffic_snapshot.dart';

/// 화면(presentation)은 REST인지 WebSocket인지 몰라도 되도록 한 곳으로 모음
class MonitorRepository {
  MonitorRepository(this._api, this._socket);

  final MonitorApi _api;
  final MonitorSocket _socket;

  // --- 실시간 ---
  Stream<TrafficSnapshot> get snapshots => _socket.snapshots;
  Stream<List<TrafficEvent>> get events => _socket.events;
  Stream<SocketStatus> get connectionStatus => _socket.status;
  void connect() => _socket.connect();

  // --- 초기 데이터 ---
  Future<Topology> fetchTopology() => _api.fetchTopology();
  Future<List<TrafficSnapshot>> fetchHistory() =>
      _api.fetchHistory(seconds: AppConfig.chartWindowSeconds);
  Future<List<TrafficEvent>> fetchRecentEvents() => _api.fetchEvents(limit: 50);

  // --- 부하 생성 ---
  Future<LoadStatus> startLoad({required int count, required int ratePerSecond}) =>
      _api.startLoad(count: count, ratePerSecond: ratePerSecond);
  Future<LoadStatus> stopLoad() => _api.stopLoad();
  Future<LoadStatus> fetchLoadStatus() => _api.fetchLoadStatus();
}

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  final socket = MonitorSocket(StompSocket(url: AppConfig.wsUrl));
  ref.onDispose(socket.dispose);
  return MonitorRepository(MonitorApi(ref.watch(dioProvider)), socket);
});
