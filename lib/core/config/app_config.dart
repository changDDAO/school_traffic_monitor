/// 서버 주소 설정
///
/// - Android 에뮬레이터에서 PC의 localhost는 `10.0.2.2`로 접근합니다.
/// - 실제 폰으로 테스트할 때는 PC의 IP를 넘겨 주세요.
///   flutter run --dart-define=API_HOST=192.168.0.10
class AppConfig {
  AppConfig._();

  static const String host = String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');
  static const int port = int.fromEnvironment('API_PORT', defaultValue: 8080);

  static String get baseUrl => 'http://$host:$port';
  static String get wsUrl => 'ws://$host:$port/ws-school-monitor';

  /// 차트에 보여줄 시간 범위(초)
  static const int chartWindowSeconds = 60;

  /// 이벤트 로그에 들고 있을 최대 줄 수
  static const int maxEventLogSize = 150;
}
