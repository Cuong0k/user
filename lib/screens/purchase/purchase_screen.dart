import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../core/api/v2board_service.dart';
import '../../core/models/plan.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});
  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Plan> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _plans = await V2BoardService.instance.fetchPlans();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  static const _labels = {
    'month_price': '1 Month',
    'quarter_price': '1 Quarter',
    'half_year_price': '6 Months',
    'year_price': '1 Year',
    'onetime_price': 'One-time',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Package')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _plans.isEmpty
                  ? const Center(child: Text('No packages available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _plans.length,
                      itemBuilder: (_, i) => _PlanCard(plan: _plans[i], labels: _labels),
                    ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final Map<String, String> labels;
  const _PlanCard({required this.plan, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip(Icons.swap_vert,
                    plan.transferEnable == null || plan.transferEnable == 0
                        ? 'Unlimited'
                        : '${plan.transferEnable} GB'),
                const SizedBox(width: 8),
                _chip(Icons.devices,
                    plan.deviceLimit == null
                        ? 'Unlimited devices'
                        : '${plan.deviceLimit} devices'),
              ],
            ),
            const SizedBox(height: 14),
            ...plan.periods.map((p) => _periodRow(context, p.key, p.value)),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData i, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _periodRow(BuildContext context, String key, num priceCents) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(labels[key] ?? key)),
          Text('${(priceCents / 100).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => _buy(context, key),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context, String period) async {
    try {
      final tradeNo =
          await V2BoardService.instance.createOrder(plan.id, period);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order created: $tradeNo')));
      // Bước kế: lấy payment methods + checkout(tradeNo, methodId) -> mở URL thanh toán.
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
