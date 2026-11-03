import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

enum SocketStatus { connecting, connected, disconnected }

/// Spring `@EnableWebSocketMessageBroker`(STOMP)에 붙는 범용 클라이언트.
///
/// - 끊기면 [reconnectDelay] 간격으로 자동 재연결
/// - 재연결될 때마다 등록해 둔 구독을 다시 겁니다.
class StompSocket {
  StompSocket({required this.url, this.reconnectDelay = const Duration(seconds: 3)});

  final String url;
  final Duration reconnectDelay;

  StompClient? _client;
  final Map<String, void Function(dynamic json)> _handlers = {};
  final _statusController = StreamController<SocketStatus>.broadcast();
  SocketStatus _status = SocketStatus.disconnected;

  Stream<SocketStatus> get statusStream => _statusController.stream;
  SocketStatus get status => _status;

  /// [destination]으로 오는 메시지 body(JSON)를 디코딩해서 [onJson]에 넘겨 줍니다.
  void subscribe(String destination, void Function(dynamic json) onJson) {
    _handlers[destination] = onJson;
    if (_client?.connected ?? false) {
      _subscribeOne(destination, onJson);
    }
  }

  void connect() {
    if (_client != null) return;
    _setStatus(SocketStatus.connecting);
    _client = StompClient(
      config: StompConfig(
        url: url,
        reconnectDelay: reconnectDelay,
        // Spring SimpleBroker는 기본 설정에서 heartbeat를 쓰지 않으므로 끔
        heartbeatIncoming: Duration.zero,
        heartbeatOutgoing: Duration.zero,
        onConnect: (_) {
          _setStatus(SocketStatus.connected);
          _handlers.forEach(_subscribeOne);
        },
        onDisconnect: (_) => _setStatus(SocketStatus.disconnected),
        onWebSocketDone: () => _setStatus(SocketStatus.connecting),
        onWebSocketError: (dynamic _) => _setStatus(SocketStatus.connecting),
        onStompError: (_) => _setStatus(SocketStatus.connecting),
      ),
    );
    _client!.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _setStatus(SocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }

  void _subscribeOne(String destination, void Function(dynamic json) onJson) {
    _client?.subscribe(
      destination: destination,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          onJson(jsonDecode(body));
        } catch (_) {
          // 형식이 다른 메시지 하나 때문에 스트림 전체가 죽지 않도록 무시
        }
      },
    );
  }

  void _setStatus(SocketStatus status) {
    if (_status == status || _statusController.isClosed) return;
    _status = status;
    _statusController.add(status);
  }
}
