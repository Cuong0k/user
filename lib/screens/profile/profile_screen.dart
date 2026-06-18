import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../purchase/purchase_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header tài khoản
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

          // Traffic usage
          _TrafficCard(),
          const SizedBox(height: 16),

          // Mua / gia hạn gói
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PurchaseScreen())),
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Purchase Package'),
          ),
          const SizedBox(height: 24),

          _menu(Icons.devices, 'Device Management', () {}),
          _menu(Icons.receipt_long, 'My Orders', () {}),
          _menu(Icons.confirmation_number, 'Redeem Code', () {}),
          _menu(Icons.support_agent, 'Customer Service', () {}),
          _menu(Icons.lock_outline, 'Change Password', () {}),
          _menu(Icons.settings, 'Settings', () {}),
          const SizedBox(height: 12),
          _menu(Icons.logout, 'Logout', () => _confirmLogout(context),
              color: AppColors.danger),
        ],
      ),
    );
  }

  Widget _menu(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.textPrimary),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
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
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              unlimited
                  ? 'Unlimited Traffic · Used ${user.usedGB.toStringAsFixed(2)} GB'
                  : 'Used ${user.usedGB.toStringAsFixed(2)} / ${user.totalGB.toStringAsFixed(2)} GB',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
