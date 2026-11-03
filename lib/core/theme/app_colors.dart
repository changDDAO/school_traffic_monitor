import 'package:flutter/material.dart';

/// 대시보드 전체에서 의미가 고정된 색 (차트, 흐름도, 로그가 같은 색을 씀)
class AppColors {
  AppColors._();

  static const background = Color(0xFF0F1115);
  static const surface = Color(0xFF181B22);
  static const surfaceHigh = Color(0xFF222632);
  static const border = Color(0xFF2C3140);
  static const textPrimary = Color(0xFFE8EAF0);
  static const textSecondary = Color(0xFF9AA1B2);

  static const publish = Color(0xFF4C8DFF);   // 발행
  static const complete = Color(0xFF2FBF71);  // 처리 완료
  static const reject = Color(0xFFF5A524);    // 비즈니스 거절
  static const error = Color(0xFFFF7A45);     // 처리 오류(재시도)
  static const dead = Color(0xFFF25C54);      // DLQ
  static const queue = Color(0xFFA78BFA);     // 큐 적재량
  static const inFlight = Color(0xFF38BDF8);  // 처리 중
}
