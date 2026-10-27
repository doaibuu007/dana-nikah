import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'payment_form_screen.dart';

/// Riwayat semua pengeluaran, dilengkapi pencarian & filter.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _query = '';
  int? _categoryFilter;
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _query.trim().toLowerCase();

    final filtered = s.payments.where((p) {
      if (_categoryFilter != null && p.categoryId != _categoryFilter) {
        return false;
      }
      if (_typeFilter != null && p.type != _typeFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final vendorName =
            s.vendorById(p.vendorId)?.name.toLowerCase() ?? '';
        final catName =
            s.categoryById(p.categoryId)?.name.toLowerCase() ?? '';
        final match = vendorName.contains(q) ||
            catName.contains(q) ||
            p.note.toLowerCase().contains(q) ||
            p.type.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    final filteredTotal =
        filtered.fold<int>(0, (sum, item) => sum + item.amount);

    final children = <Widget>[];
    String? lastMonth;
    for (final p in filtered) {
      final key = '${p.date.year}-${p.date.month}';
      if (key != lastMonth) {
        lastMonth = key;
        final monthTotal = filtered
            .where((x) =>
                x.date.year == p.date.year && x.date.month == p.date.month)
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
            child: Column(
              children: [
                InfoRow('Total semua pengeluaran', rupiah(s.totalSpent),
                    valueColor: AppColors.danger, bold: true),
                if (filtered.length != s.payments.length)
                  InfoRow(
                      'Total sesuai filter (${filtered.length} transaksi)',
                      rupiah(filteredTotal)),
              ],
            ),
          ),
          SearchBarField(
            hint: 'Cari pengeluaran, vendor, atau catatan...',
            value: _query,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua Jenis'),
                selected: _typeFilter == null,
                onSelected: (_) => setState(() => _typeFilter = null),
              ),
              for (final t in paymentTypes)
                ChoiceChip(
                  label: Text(t),
                  selected: _typeFilter == t,
                  onSelected: (sel) =>
                      setState(() => _typeFilter = sel ? t : null),
                ),
            ],
          ),
          if (s.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Semua Kategori'),
                      selected: _categoryFilter == null,
                      onSelected: (_) =>
                          setState(() => _categoryFilter = null),
                    ),
                  ),
                  for (final c in s.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: _categoryFilter == c.id,
                        onSelected: (sel) => setState(
                            () => _categoryFilter = sel ? c.id : null),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (children.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long,
              title: 'Tidak ada pengeluaran',
              message: 'Belum ada pengeluaran yang cocok dengan pencarian.',
            ),
          ...children,
        ],
      ),
    );
  }
}
