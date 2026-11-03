import 'package:dio/dio.dart';

import '../models/load_status.dart';
import '../models/topology.dart';
import '../models/traffic_event.dart';
import '../models/traffic_snapshot.dart';

/// REST: /api/school/monitor/**
class MonitorApi {
  MonitorApi(this._dio);

  final Dio _dio;

  static const _base = '/api/school/monitor';

  Future<Topology> fetchTopology() async {
    final res = await _dio.get<Map<String, dynamic>>('$_base/topology');
    return Topology.fromJson(res.data!);
  }

  Future<List<TrafficSnapshot>> fetchHistory({int seconds = 60}) async {
    final res = await _dio.get<List<dynamic>>('$_base/history', queryParameters: {'seconds': seconds});
    return TrafficSnapshot.parseList(res.data);
  }

  /// 최신 → 오래된 순
  Future<List<TrafficEvent>> fetchEvents({int limit = 50}) async {
    final res = await _dio.get<List<dynamic>>('$_base/events', queryParameters: {'limit': limit});
    return TrafficEvent.parseList(res.data);
  }

  Future<LoadStatus> startLoad({required int count, required int ratePerSecond}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/load',
      data: {'count': count, 'ratePerSecond': ratePerSecond},
    );
    return LoadStatus.fromJson(res.data!);
  }

  Future<LoadStatus> stopLoad() async {
    final res = await _dio.delete<Map<String, dynamic>>('$_base/load');
    return LoadStatus.fromJson(res.data!);
  }

  Future<LoadStatus> fetchLoadStatus() async {
    final res = await _dio.get<Map<String, dynamic>>('$_base/load');
    return LoadStatus.fromJson(res.data!);
  }
}
