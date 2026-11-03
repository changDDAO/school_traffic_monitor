import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/topology.dart';
import '../../data/models/traffic_snapshot.dart';

/// Producer → Exchange → Queue → Consumer, Queue → DLQ 흐름을 그리고
/// 초당 처리량에 비례해 점(메시지)이 흘러가는 애니메이션을 보여줌.
class FlowDiagram extends StatefulWidget {
  const FlowDiagram({super.key, required this.snapshot, required this.topology});

  final TrafficSnapshot? snapshot;
  final Topology topology;

  @override
  State<FlowDiagram> createState() => _FlowDiagramState();
}

class _FlowDiagramState extends State<FlowDiagram> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _FlowPainter(
          animation: _controller,
          snapshot: widget.snapshot,
          topology: widget.topology,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Node {
  const _Node(this.center, this.title, this.value, this.color, {this.highlight = false});

  final Offset center;
  final String title;
  final String value;
  final Color color;
  final bool highlight;
}

class _FlowPainter extends CustomPainter {
  _FlowPainter({required this.animation, required this.snapshot, required this.topology})
      : super(repaint: animation);

  final Animation<double> animation;
  final TrafficSnapshot? snapshot;
  final Topology topology;

  static const _nodeHeight = 54.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = snapshot;
    final nodeWidth = math.min(84.0, size.width * 0.21);
    const topY = 46.0;
    final bottomY = size.height - 36;
    double x(double ratio) => size.width * ratio;

    final backlog = s?.mainQueue?.ready ?? 0;
    final dlqCount = s?.deadLetterQueue?.ready ?? 0;

    final producer = _Node(Offset(x(0.11), topY), 'Producer', '${formatRate(s?.publishRate ?? 0)}/s', AppColors.publish);
    final exchange = _Node(Offset(x(0.37), topY), 'Exchange', 'direct', AppColors.publish);
    final queue = _Node(Offset(x(0.63), topY), 'Queue', '${formatCount(backlog)}건', AppColors.queue,
        highlight: backlog > 0);
    final consumer = _Node(
      Offset(x(0.89), topY),
      'Consumer',
      '${s?.activeConsumers ?? 0}/${s?.maxConsumers ?? topology.maxConcurrency}',
      AppColors.complete,
      highlight: (s?.inFlight ?? 0) > 0,
    );
    final dlq = _Node(Offset(x(0.63), bottomY), 'DLQ', '${formatCount(dlqCount)}건', AppColors.dead,
        highlight: dlqCount > 0);

    final half = nodeWidth / 2;
    // 가로 연결선: 노드 오른쪽 끝 → 다음 노드 왼쪽 끝
    _edge(canvas, producer.center + Offset(half, 0), exchange.center - Offset(half, 0),
        s?.publishRate ?? 0, AppColors.publish, label: topology.routingKey);
    _edge(canvas, exchange.center + Offset(half, 0), queue.center - Offset(half, 0),
        s?.publishRate ?? 0, AppColors.publish);
    _edge(canvas, queue.center + Offset(half, 0), consumer.center - Offset(half, 0),
        s?.consumeRate ?? 0, AppColors.complete, label: 'prefetch ${topology.prefetch}');
    // 세로 연결선: 큐 아래 → DLQ 위 (재시도 다 실패한 메시지)
    _edge(canvas, queue.center + const Offset(0, _nodeHeight / 2), dlq.center - const Offset(0, _nodeHeight / 2),
        s?.deadLetterRate ?? 0, AppColors.dead, label: '재시도 ${topology.maxAttempts}회 실패');

    for (final node in [producer, exchange, queue, consumer, dlq]) {
      _drawNode(canvas, node, nodeWidth);
    }
  }

  /// 연결선 + 흐르는 점. 점 개수는 초당 처리량에 비례 (최대 7개)
  void _edge(Canvas canvas, Offset from, Offset to, double rate, Color color,
      {String? label}) {
    final active = rate > 0;
    final line = Paint()
      ..color = (active ? color : AppColors.border).withValues(alpha: active ? 0.55 : 1)
      ..strokeWidth = 2;
    canvas.drawLine(from, to, line);

    // 화살촉
    final dir = (to - from) / (to - from).distance;
    final normal = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo((to - dir * 7 + normal * 4).dx, (to - dir * 7 + normal * 4).dy)
      ..lineTo((to - dir * 7 - normal * 4).dx, (to - dir * 7 - normal * 4).dy)
      ..close();
    canvas.drawPath(head, Paint()..color = line.color);

    if (label != null) {
      final vertical = (to.dx - from.dx).abs() < 1;
      final mid = Offset.lerp(from, to, 0.5)!;
      // 가로선 라벨은 노드 아래쪽 빈 공간에, 세로선 라벨은 선 오른쪽에
      final anchor = vertical ? mid + const Offset(8, -6) : mid + const Offset(0, _nodeHeight / 2 + 6);
      _text(canvas, label, anchor,
          const TextStyle(color: AppColors.textSecondary, fontSize: 9), center: !vertical);
    }

    if (!active) return;
    final dots = math.min(7, math.max(1, (rate / 10).ceil()));
    final dotPaint = Paint()..color = color;
    for (var i = 0; i < dots; i++) {
      final t = (animation.value + i / dots) % 1.0;
      canvas.drawCircle(Offset.lerp(from, to, t)!, 3, dotPaint);
    }
  }

  void _drawNode(Canvas canvas, _Node node, double width) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: node.center, width: width, height: _nodeHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.surfaceHigh);
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = node.highlight ? 2 : 1
        ..color = node.highlight ? node.color : AppColors.border,
    );
    _text(canvas, node.title, node.center - const Offset(0, 16),
        const TextStyle(color: AppColors.textSecondary, fontSize: 10), center: true, maxWidth: width - 6);
    _text(canvas, node.value, node.center + const Offset(0, 1),
        TextStyle(color: node.color, fontSize: 14, fontWeight: FontWeight.w700),
        center: true, maxWidth: width - 6);
  }

  void _text(Canvas canvas, String text, Offset anchor, TextStyle style,
      {bool center = false, double maxWidth = 140}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = center ? anchor.dx - painter.width / 2 : anchor.dx;
    painter.paint(canvas, Offset(dx, anchor.dy));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _FlowPainter old) =>
      old.snapshot != snapshot || old.topology != topology;
}
