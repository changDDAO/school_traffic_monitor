import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/enrollment_monitor/presentation/screens/monitor_dashboard_screen.dart';

class SchoolTrafficMonitorApp extends StatelessWidget {
  const SchoolTrafficMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '수강신청 트래픽 모니터',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const MonitorDashboardScreen(),
    );
  }
}
