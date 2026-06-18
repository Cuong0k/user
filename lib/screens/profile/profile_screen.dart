import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/vpn_provider.dart';
import '../../core/vpn/vpn_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _updating = false;

  Future<void> _updateSubscription() async {
    // Nếu đang bật VPN thì yêu cầu tắt trước
    final vpn = context.read<VpnProvider>();
    if (vpn.state == VpnState.connected || vpn.state == VpnState.connecting) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vui lòng tắt app (ngắt VPN) rồi thực hiện lại')));
      return;
    }
    setState(() => _updating = true);
    try {
      await context.read<AuthProvider>().refreshUser();
      await context.read<ServerProvider>().load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật gói dịch vụ thành công')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('My')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.email ?? 'Not logged in',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Balance: ${((user?.balance ?? 0) / 100).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _TrafficCard(),
          const SizedBox(height: 20),

          // Nút cập nhật gói VPN (làm mới gói + node từ server)
          ElevatedButton.icon(
            onPressed: _updating ? null : _updateSubscription,
            icon: _updating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            label: Text(_updating ? 'Đang cập nhật...' : 'Cập nhật gói VPN'),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            child: const Text('Logout',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _TrafficCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final unlimited = user.unlimited;
    final ratio = unlimited || user.totalGB == 0
        ? 0.0
        : (user.usedGB / user.totalGB).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Traffic Usage',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: unlimited ? null : ratio,
                minHeight: 10,
                backgroundColor: AppColors.surface2,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              unlimited
                  ? 'Unlimited · Used ${user.usedGB.toStringAsFixed(2)} GB'
                  : 'Used ${user.usedGB.toStringAsFixed(2)} / ${user.totalGB.toStringAsFixed(2)} GB',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
