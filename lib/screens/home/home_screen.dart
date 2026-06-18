import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_flags/country_flags.dart';

import '../../theme/app_theme.dart';
import '../../providers/vpn_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/vpn/vpn_service.dart';
import 'node_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final servers = context.watch<ServerProvider>();
    final auth = context.watch<AuthProvider>();
    final node = servers.selected;

    return Scaffold(
      appBar: AppBar(title: const Text('VPNChina')),
      body: RefreshIndicator(
        onRefresh: () async {
          await servers.load();
          await auth.refreshUser();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SubscriptionBanner(),
            const SizedBox(height: 32),
            _ConnectButton(vpn: vpn, node: node),
            const SizedBox(height: 24),
            _StatusLine(vpn: vpn),
            const SizedBox(height: 32),
            _NodeSelector(node: node),
          ],
        ),
      ),
    );
  }
}

/// Banner trạng thái gói cước trên đầu màn Home.
class _SubscriptionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final active = user?.hasActiveSubscription ?? false;
    final exp = user?.expireDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [AppColors.primary, AppColors.primaryGlow]
              : [AppColors.surface2, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.verified_user : Icons.lock_clock,
              color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'Subscription Valid' : 'No Valid Subscription',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  active && exp != null
                      ? 'Expires: ${exp.toString().split(' ').first}'
                      : 'Subscribe to enjoy global high-speed network',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!active)
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Subscribe',
                  style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

/// Nút tròn lớn bật/tắt VPN — phần trung tâm của app.
class _ConnectButton extends StatelessWidget {
  final VpnProvider vpn;
  final dynamic node;
  const _ConnectButton({required this.vpn, required this.node});

  @override
  Widget build(BuildContext context) {
    final connected = vpn.state == VpnState.connected;
    final connecting = vpn.state == VpnState.connecting;
    final color = connected ? AppColors.success : AppColors.primary;

    return Center(
      child: GestureDetector(
        onTap: () async {
          if (node == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No nodes available')));
            return;
          }
          try {
            await context.read<VpnProvider>().toggle(node);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(0.25), AppColors.bg],
              radius: 0.85,
            ),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(connected ? 0.4 : 0.15),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              connecting
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Icon(Icons.power_settings_new, size: 64, color: color),
              const SizedBox(height: 12),
              Text(
                _label(vpn.state),
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(VpnState s) {
    switch (s) {
      case VpnState.connected:
        return 'Connected';
      case VpnState.connecting:
        return 'Connecting';
      case VpnState.disconnecting:
        return 'Disconnecting';
      default:
        return 'Tap to Connect';
    }
  }
}

/// Dòng hiển thị thời lượng + tốc độ up/down khi đã kết nối.
class _StatusLine extends StatelessWidget {
  final VpnProvider vpn;
  const _StatusLine({required this.vpn});

  @override
  Widget build(BuildContext context) {
    if (vpn.state != VpnState.connected) return const SizedBox(height: 24);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat(Icons.timer_outlined, vpn.duration),
        _stat(Icons.arrow_upward, vpn.uploadSpeed),
        _stat(Icons.arrow_downward, vpn.downloadSpeed),
      ],
    );
  }

  Widget _stat(IconData i, String v) => Column(
        children: [
          Icon(i, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(v,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      );
}

/// Thẻ chọn node hiện tại -> mở danh sách node.
class _NodeSelector extends StatelessWidget {
  final dynamic node;
  const _NodeSelector({required this.node});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: node == null
            ? const Icon(Icons.public, color: AppColors.textSecondary)
            : ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CountryFlag.fromCountryCode(node.countryCode,
                    height: 28, width: 38),
              ),
        title: Text(node?.cleanName ?? 'Select a node',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(node == null ? 'Country/Region' : '${node.type} · x${node.rate}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NodeListScreen())),
      ),
    );
  }
}
