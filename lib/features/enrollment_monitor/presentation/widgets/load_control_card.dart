import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/load_controller.dart';
import 'section_card.dart';

/// 수강신청 N건을 초당 M건 속도로 발행하는 테스트 패널
class LoadControlCard extends ConsumerStatefulWidget {
  const LoadControlCard({super.key});

  @override
  ConsumerState<LoadControlCard> createState() => _LoadControlCardState();
}

class _LoadControlCardState extends ConsumerState<LoadControlCard> {
  double _count = 500;
  double _rate = 100;

  @override
  Widget build(BuildContext context) {
    final load = ref.watch(loadControllerProvider);
    final controller = ref.read(loadControllerProvider.notifier);
    final status = load.status;

    return SectionCard(
      title: '테스트 트래픽',
      subtitle: '학생 1~12, 강의 1~7 랜덤 수강신청을 큐에 발행',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SliderRow(
            label: '총 건수',
            valueText: '${_count.round()}건',
            value: _count,
            min: 10,
            max: 3000,
            divisions: 299,
            enabled: !status.running,
            onChanged: (v) => setState(() => _count = v),
          ),
          _SliderRow(
            label: '발행 속도',
            valueText: '${_rate.round()}/s',
            value: _rate,
            min: 5,
            max: 500,
            divisions: 99,
            enabled: !status.running,
            onChanged: (v) => setState(() => _rate = v),
          ),
          const SizedBox(height: 8),
          if (status.running || status.sent > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.progress,
                minHeight: 6,
                color: AppColors.publish,
                backgroundColor: AppColors.surfaceHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${status.sent} / ${status.total}건 발행${status.running ? ' 중' : ' 완료'}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          if (load.error != null) ...[
            Text(load.error!, style: const TextStyle(color: AppColors.dead, fontSize: 12)),
            const SizedBox(height: 8),
          ],
          status.running
              ? FilledButton.tonalIcon(
                  onPressed: load.busy ? null : controller.stop,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('중지'),
                )
              : FilledButton.icon(
                  onPressed: load.busy
                      ? null
                      : () => controller.start(count: _count.round(), ratePerSecond: _rate.round()),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('발행 시작'),
                ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(valueText, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
