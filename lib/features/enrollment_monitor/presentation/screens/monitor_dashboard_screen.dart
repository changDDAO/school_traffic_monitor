import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/monitor_controller.dart';
import '../widgets/connection_status_chip.dart';
import '../widgets/event_log_list.dart';
import '../widgets/flow_diagram.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/load_control_card.dart';
import '../widgets/realtime_line_chart.dart';
import '../widgets/section_card.dart';

/// 메인 화면: [대시보드] / [이벤트 로그] 두 탭
class MonitorDashboardScreen extends ConsumerWidget {
  const MonitorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitorControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('수강신청 트래픽', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('RabbitMQ · school.enrollment',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          actions: [
            ConnectionStatusChip(
              status: state.connection,
              brokerUp: state.latest?.brokerUp ?? true,
            ),
            const SizedBox(width: 12),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '대시보드'),
              Tab(text: '이벤트 로그'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            _EventLogTab(),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitorControllerProvider);
    final controller = ref.read(monitorControllerProvider.notifier);
    final latest = state.latest;

    return RefreshIndicator(
      onRefresh: controller.loadInitialData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (state.initError != null) ...[
            _Banner(
              color: AppColors.dead,
              icon: Icons.cloud_off_rounded,
              message: state.initError!,
            ),
            const SizedBox(height: 12),
          ] else if (latest != null && !latest.brokerUp) ...[
            const _Banner(
              color: AppColors.reject,
              icon: Icons.warning_amber_rounded,
              message: 'Spring 서버는 연결됐지만 RabbitMQ에 접속할 수 없습니다. 도커 컨테이너를 확인하세요.',
            ),
            const SizedBox(height: 12),
          ],
          SectionCard(
            title: '메시지 흐름',
            subtitle: '점 하나하나가 초당 처리량에 비례해 흐르는 메시지',
            child: FlowDiagram(snapshot: latest, topology: state.topology),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '현재 상태',
            child: KpiGrid(snapshot: latest),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '처리량 (msg/s)',
            subtitle: '최근 ${AppConfig.chartWindowSeconds}초',
            child: RealtimeLineChart(
              history: state.history,
              series: [
                ChartSeries(label: '발행', color: AppColors.publish, value: (s) => s.publishRate),
                ChartSeries(label: '처리 완료', color: AppColors.complete, value: (s) => s.completeRate),
                ChartSeries(label: '거절', color: AppColors.reject, value: (s) => s.rejectRate),
                ChartSeries(label: '오류', color: AppColors.error, value: (s) => s.errorRate),
                ChartSeries(label: 'DLQ', color: AppColors.dead, value: (s) => s.deadLetterRate),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '큐 적재량',
            subtitle: '발행 속도 > 처리 속도면 큐에 쌓였다가 Consumer가 소진',
            child: RealtimeLineChart(
              history: state.history,
              height: 160,
              series: [
                ChartSeries(
                  label: '대기 메시지',
                  color: AppColors.queue,
                  filled: true,
                  value: (s) => (s.mainQueue?.ready ?? 0).toDouble(),
                ),
                ChartSeries(label: '처리 중', color: AppColors.inFlight, value: (s) => s.inFlight.toDouble()),
                ChartSeries(
                  label: 'Consumer 스레드',
                  color: AppColors.complete,
                  value: (s) => s.activeConsumers.toDouble(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const LoadControlCard(),
        ],
      ),
    );
  }
}

class _EventLogTab extends ConsumerWidget {
  const _EventLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitorControllerProvider);
    final controller = ref.read(monitorControllerProvider.notifier);

    return Column(
      children: [
        const SizedBox(height: 10),
        EventFilterBar(
          selected: state.eventFilter,
          onToggle: controller.toggleFilter,
          onClear: controller.clearFilter,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              Text(
                '${state.visibleEvents.length}건${state.paused ? ' · 일시정지됨' : ''}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                tooltip: state.paused ? '다시 받기' : '일시정지',
                onPressed: controller.togglePause,
                icon: Icon(state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              ),
              IconButton(
                tooltip: '비우기',
                onPressed: controller.clearEvents,
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
            ],
          ),
        ),
        Expanded(child: EventLogList(events: state.visibleEvents)),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.message});

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
