import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'payment_form_screen.dart';

/// Riwayat semua pengeluaran, dikelompokkan per bulan.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final children = <Widget>[];
    String? lastMonth;
    for (final p in s.payments) {
      final key = '${p.date.year}-${p.date.month}';
      if (key != lastMonth) {
        lastMonth = key;
        final monthTotal = s.payments
            .where((x) => x.date.year == p.date.year && x.date.month == p.date.month)
            .fold<int>(0, (sum, x) => sum + x.amount);
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatMonthYear(p.date),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
              Text(
                rupiah(monthTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.danger),
              ),
            ],
          ),
        ));
      }
      children.add(PaymentTile(payment: p));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pengeluaran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => pushPage(context, const PaymentFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Pengeluaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          AppCard(
            child: InfoRow('Total pengeluaran', rupiah(s.totalSpent),
                valueColor: AppColors.danger, bold: true),
          ),
          if (children.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long,
              title: 'Belum ada pengeluaran',
              message: 'Pengeluaran yang dicatat akan muncul di sini.',
            ),
          ...children,
        ],
      ),
    );
  }
}
