import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/stomp_socket.dart';
import '../../data/models/topology.dart';
import '../../data/models/traffic_event.dart';
import '../../data/models/traffic_event_type.dart';
import '../../data/models/traffic_snapshot.dart';
import '../../data/repositories/monitor_repository.dart';
import 'monitor_state.dart';

final monitorControllerProvider =
    NotifierProvider<MonitorController, MonitorState>(MonitorController.new);

/// 대시보드 화면의 상태를 관리
///  1) REST로 초기 데이터(토폴로지, 최근 60초, 최근 로그) 로드
///  2) WebSocket 연결 후 1초마다 들어오는 스냅샷/이벤트를 상태에 누적
class MonitorController extends Notifier<MonitorState> {
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  MonitorRepository get _repo => ref.read(monitorRepositoryProvider);

  @override
  MonitorState build() {
    ref.onDispose(() {
      for (final s in _subscriptions) {
        s.cancel();
      }
      _subscriptions.clear();
    });
    Future.microtask(_start);
    return const MonitorState();
  }

  Future<void> _start() async {
    final repo = _repo;
    _subscriptions
      ..add(repo.connectionStatus.listen((status) {
        state = state.copyWith(connection: status);
        // 재연결되면 끊겨 있던 동안 비어 있는 그래프를 서버 기록으로 다시 채움
        if (status == SocketStatus.connected) unawaited(loadInitialData());
      }))
      ..add(repo.snapshots.listen(_onSnapshot))
      ..add(repo.events.listen(_onEvents));
    repo.connect();
    await loadInitialData();
  }

  /// 새로고침(당겨서 새로고침/버튼)에서도 사용
  Future<void> loadInitialData() async {
    try {
      // 세 요청을 동시에 보내고 모두 기다림
      final results = await Future.wait<Object>([
        _repo.fetchTopology(),
        _repo.fetchHistory(),
        _repo.fetchRecentEvents(),
      ]);
      final topology = results[0] as Topology;
      final history = results[1] as List<TrafficSnapshot>;
      final events = results[2] as List<TrafficEvent>;
      state = state.copyWith(
        topology: topology,
        history: history,
        events: _mergeEvents(events, state.events),
        clearInitError: true,
      );
    } catch (e) {
      state = state.copyWith(initError: describeDioError(e));
    }
  }

  void toggleFilter(TrafficEventType type) {
    final next = {...state.eventFilter};
    if (!next.remove(type)) next.add(type);
    state = state.copyWith(eventFilter: next);
  }

  void clearFilter() => state = state.copyWith(eventFilter: <TrafficEventType>{});

  void togglePause() => state = state.copyWith(paused: !state.paused);

  void clearEvents() => state = state.copyWith(events: const []);

  void _onSnapshot(TrafficSnapshot snapshot) {
    final last = state.latest;
    if (last != null && !snapshot.timestamp.isAfter(last.timestamp)) return; // REST 기록과 중복
    final history = [...state.history, snapshot];
    final overflow = history.length - AppConfig.chartWindowSeconds;
    state = state.copyWith(
      history: overflow > 0 ? history.sublist(overflow) : history,
    );
  }

  void _onEvents(List<TrafficEvent> batch) {
    if (state.paused) return;
    // 서버는 오래된 → 최신 순으로 보내므로 뒤집어서 앞에 붙임
    final merged = [...batch.reversed, ...state.events];
    state = state.copyWith(
      events: merged.length > AppConfig.maxEventLogSize
          ? merged.sublist(0, AppConfig.maxEventLogSize)
          : merged,
    );
  }

  /// REST로 받은 최근 로그와 이미 화면에 있는 로그를 중복 없이 합침 (최신 순)
  List<TrafficEvent> _mergeEvents(List<TrafficEvent> fetched, List<TrafficEvent> current) {
    final seen = <String>{};
    final merged = <TrafficEvent>[];
    for (final e in [...current, ...fetched]) {
      final key = '${e.type.name}:${e.requestId}:${e.timestamp.millisecondsSinceEpoch}';
      if (seen.add(key)) merged.add(e);
    }
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged.length > AppConfig.maxEventLogSize
        ? merged.sublist(0, AppConfig.maxEventLogSize)
        : merged;
  }
}
