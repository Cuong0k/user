import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../core/api/v2board_service.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/invite_info.dart';
import '../../providers/auth_provider.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});
  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  InviteInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      var info = await V2BoardService.instance.fetchInvite();
      if (info.codes.isEmpty) {
        await V2BoardService.instance.generateInviteCode();
        info = await V2BoardService.instance.fetchInvite();
      }
      if (mounted) setState(() {
            _info = info;
            _loading = false;
          });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _inviteLink {
    final code = _info?.firstCode ?? '';
    return '${Api.baseUrl}/#/register?code=$code';
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().loggedIn) {
      return const Scaffold(
          body: Center(child: Text('Please login first to view invitation')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Thống kê
                Row(
                  children: [
                    _statCard('Registered', '${_info?.registerCount ?? 0}'),
                    const SizedBox(width: 12),
                    _statCard('Commission',
                        '${((_info?.totalCommission ?? 0) / 100).toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 24),

                // QR code
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                              data: _inviteLink, size: 180),
                        ),
                        const SizedBox(height: 16),
                        Text('My Invite Code',
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        SelectableText(
                          _info?.firstCode ?? '-',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copy(_info?.firstCode ?? ''),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copy(_inviteLink),
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Copy Link'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _rules(),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );

  Widget _rules() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Invitation Rules',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  '1. Share your exclusive invitation link or code to invite friends.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
              Text(
                  '2. After friends register and place an order, rewards are credited automatically.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      );

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}
