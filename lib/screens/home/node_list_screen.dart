import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_flags/country_flags.dart';

import '../../theme/app_theme.dart';
import '../../providers/server_provider.dart';
import '../../providers/vpn_provider.dart';
import '../../core/models/server_node.dart';

class NodeListScreen extends StatefulWidget {
  const NodeListScreen({super.key});
  @override
  State<NodeListScreen> createState() => _NodeListScreenState();
}

class _NodeListScreenState extends State<NodeListScreen> {
  String _query = '';
  bool _testing = false;

  Future<void> _testAll() async {
    setState(() => _testing = true);
    final servers = context.read<ServerProvider>();
    final vpn = context.read<VpnProvider>();
    for (final n in servers.nodes) {
      try {
        final ms = await vpn.ping(n);
        servers.setPing(n.id, ms);
      } catch (_) {
        servers.setPing(n.id, -1);
      }
    }
    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<ServerProvider>();
    final nodes = servers.nodes
        .where((n) => n.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Server'),
        actions: [
          IconButton(
            icon: _testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.speed),
            tooltip: 'Kiểm tra độ trễ',
            onPressed: _testing ? null : _testAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm server theo tên, quốc gia...',
              ),
            ),
          ),
          Expanded(
            child: servers.loading
                ? const Center(child: CircularProgressIndicator())
                : nodes.isEmpty
                    ? const Center(
                        child: Text('Không có server',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: nodes.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.surface2),
                        itemBuilder: (_, i) => _NodeTile(
                            node: nodes[i], ping: servers.pings[nodes[i].id]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  final ServerNode node;
  final int? ping;
  const _NodeTile({required this.node, this.ping});

  Color get _pingColor {
    if (ping == null) return AppColors.textSecondary;
    if (ping! < 0) return AppColors.danger;
    if (ping! < 150) return AppColors.success;
    if (ping! < 300) return Colors.orange;
    return AppColors.danger;
  }

  String get _pingText {
    if (ping == null) return '';
    if (ping! < 0) return 'timeout';
    return '${ping}ms';
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ServerProvider>().selected?.id == node.id;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child:
            CountryFlag.fromCountryCode(node.countryCode, height: 28, width: 38),
      ),
      title: Text(node.cleanName,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: node.isOnline
                  ? AppColors.textPrimary
                  : AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_pingText, style: TextStyle(color: _pingColor, fontSize: 13)),
          const SizedBox(width: 8),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ],
      ),
      onTap: () {
        context.read<ServerProvider>().select(node);
        Navigator.pop(context);
      },
    );
  }
}
