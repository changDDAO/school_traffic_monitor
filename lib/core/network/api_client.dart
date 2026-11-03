import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// 앱 전체에서 공유하는 Dio 인스턴스
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Dio 에러를 화면에 보여줄 한 줄 메시지로 변환
String describeDioError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return '서버(${AppConfig.baseUrl})에 연결할 수 없습니다. Spring Boot가 실행 중인지 확인하세요.';
      case DioExceptionType.receiveTimeout:
        return '서버 응답이 너무 늦습니다.';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final message = data is Map ? (data['message'] ?? data['error']) : null;
        return 'HTTP ${error.response?.statusCode}${message != null ? ': $message' : ''}';
      default:
        return error.message ?? error.toString();
    }
  }
  return error.toString();
}
