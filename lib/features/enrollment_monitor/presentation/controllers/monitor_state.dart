import '../../../../core/network/stomp_socket.dart';
import '../../data/models/topology.dart';
import '../../data/models/traffic_event.dart';
import '../../data/models/traffic_event_type.dart';
import '../../data/models/traffic_snapshot.dart';

class MonitorState {
  const MonitorState({
    this.connection = SocketStatus.connecting,
    this.topology = Topology.fallback,
    this.history = const [],
    this.events = const [],
    this.eventFilter = const {},
    this.paused = false,
    this.initError,
  });

  final SocketStatus connection;
  final Topology topology;

  /// 오래된 것 → 최신 (차트용, 최대 AppConfig.chartWindowSeconds개)
  final List<TrafficSnapshot> history;

  /// 최신 → 오래된 것 (로그용)
  final List<TrafficEvent> events;

  /// 비어 있으면 전체 표시
  final Set<TrafficEventType> eventFilter;

  /// 로그 일시정지 (스크롤하며 읽을 때)
  final bool paused;

  final String? initError;

  TrafficSnapshot? get latest => history.isEmpty ? null : history.last;

  List<TrafficEvent> get visibleEvents => eventFilter.isEmpty
      ? events
      : events.where((e) => eventFilter.contains(e.type)).toList();

  MonitorState copyWith({
    SocketStatus? connection,
    Topology? topology,
    List<TrafficSnapshot>? history,
    List<TrafficEvent>? events,
    Set<TrafficEventType>? eventFilter,
    bool? paused,
    String? initError,
    bool clearInitError = false,
  }) {
    return MonitorState(
      connection: connection ?? this.connection,
      topology: topology ?? this.topology,
      history: history ?? this.history,
      events: events ?? this.events,
      eventFilter: eventFilter ?? this.eventFilter,
      paused: paused ?? this.paused,
      initError: clearInitError ? null : (initError ?? this.initError),
    );
  }
}
