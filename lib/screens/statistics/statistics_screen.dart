import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/vpn_provider.dart';
import '../../providers/server_provider.dart';
import '../../core/vpn/vpn_service.dart';

/// Thống kê phiên hiện tại (dữ liệu THẬT từ core, không còn biểu đồ giả).
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final servers = context.watch<ServerProvider>();
    final connected = vpn.state == VpnState.connected;
    final node = vpn.activeNode ?? servers.selected;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(connected ? Icons.shield : Icons.shield_outlined,
                      color: connected
                          ? AppColors.success
                          : AppColors.textSecondary,
                      size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trạng thái VPN',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(connected ? 'Đã kết nối' : 'Chưa kết nối',
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
              _card('Thời gian kết nối', connected ? vpn.duration : '--'),
              const SizedBox(width: 12),
              _card('Giao thức', node?.type.toUpperCase() ?? '--'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _card('Tải lên', connected ? vpn.uploadTotal : '--',
                  icon: Icons.arrow_upward),
              const SizedBox(width: 12),
              _card('Tải xuống', connected ? vpn.downloadTotal : '--',
                  icon: Icons.arrow_downward),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _card('Tốc độ lên', connected ? vpn.uploadSpeed : '--'),
              const SizedBox(width: 12),
              _card('Tốc độ xuống', connected ? vpn.downloadSpeed : '--'),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.dns, color: AppColors.primary),
              title: const Text('Server hiện tại'),
              subtitle: Text(node?.cleanName ?? 'Chưa chọn'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String label, String value, {IconData? icon}) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
}
