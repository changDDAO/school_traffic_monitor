import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/load_status.dart';
import '../../data/repositories/monitor_repository.dart';

class LoadState {
  const LoadState({this.status = LoadStatus.idle, this.busy = false, this.error});

  final LoadStatus status;
  final bool busy;
  final String? error;

  LoadState copyWith({LoadStatus? status, bool? busy, String? error, bool clearError = false}) {
    return LoadState(
      status: status ?? this.status,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final loadControllerProvider = NotifierProvider<LoadController, LoadState>(LoadController.new);

/// 앱에서 테스트 트래픽(수강신청 N건)을 발생시키고 진행률을 1초마다 갱신
class LoadController extends Notifier<LoadState> {
  Timer? _poller;

  MonitorRepository get _repo => ref.read(monitorRepositoryProvider);

  @override
  LoadState build() {
    ref.onDispose(() => _poller?.cancel());
    Future.microtask(_refresh);
    return const LoadState();
  }

  Future<void> start({required int count, required int ratePerSecond}) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final status = await _repo.startLoad(count: count, ratePerSecond: ratePerSecond);
      state = state.copyWith(status: status, busy: false);
      _startPolling();
    } catch (e) {
      state = state.copyWith(busy: false, error: describeDioError(e));
    }
  }

  Future<void> stop() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final status = await _repo.stopLoad();
      state = state.copyWith(status: status, busy: false);
    } catch (e) {
      state = state.copyWith(busy: false, error: describeDioError(e));
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final status = await _repo.fetchLoadStatus();
      state = state.copyWith(status: status);
      if (status.running && _poller == null) _startPolling();
      if (!status.running) {
        _poller?.cancel();
        _poller = null;
      }
    } catch (_) {
      // 서버가 꺼져 있으면 조용히 무시 (대시보드 상단에 연결 상태가 따로 표시됨)
    }
  }
}
