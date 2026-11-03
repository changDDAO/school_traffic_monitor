import 'package:flutter/material.dart';

import '../../../../core/network/stomp_socket.dart';
import '../../../../core/theme/app_colors.dart';

/// AppBar 우측의 LIVE / 연결 중 / 끊김 표시
class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key, required this.status, required this.brokerUp});

  final SocketStatus status;

  /// 서버는 붙었는데 RabbitMQ가 꺼진 경우를 구분하기 위함
  final bool brokerUp;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SocketStatus.connected when !brokerUp => ('MQ 끊김', AppColors.reject),
      SocketStatus.connected => ('LIVE', AppColors.complete),
      SocketStatus.connecting => ('연결 중', AppColors.reject),
      SocketStatus.disconnected => ('끊김', AppColors.dead),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: color, pulsing: status == SocketStatus.connected && brokerUp),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulsing) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: dot,
    );
  }
}
