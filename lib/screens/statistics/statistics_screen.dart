import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import '../../providers/vpn_provider.dart';
import '../../core/vpn/vpn_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final connected = vpn.state == VpnState.connected;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Trạng thái VPN
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(connected ? Icons.shield : Icons.shield_outlined,
                      color: connected ? AppColors.success : AppColors.textSecondary,
                      size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VPN Status',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(connected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: connected
                                  ? AppColors.success
                                  : AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _infoCard('Connection Time', connected ? vpn.duration : '--'),
              const SizedBox(width: 12),
              _infoCard('Protocol', vpn.activeNode?.type.toUpperCase() ?? '--'),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Last 7 Days Protection Time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _WeeklyChart()),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
}

/// Biểu đồ cột thời gian bảo vệ 7 ngày (dữ liệu mẫu — nối API thật của bạn vào).
class _WeeklyChart extends StatelessWidget {
  final _days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _hours = const [2.5, 4.0, 1.5, 6.0, 3.5, 5.0, 4.5];

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 8,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_days[v.toInt()],
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ),
            ),
          ),
        ),
        barGroups: List.generate(
          7,
          (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: _hours[i],
              width: 18,
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primary, AppColors.primaryGlow],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
