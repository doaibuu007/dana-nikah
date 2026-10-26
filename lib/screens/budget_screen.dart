import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'category_detail_screen.dart';
import 'category_form_screen.dart';
import 'payment_form_screen.dart';
import 'payments_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final budget = s.totalBudget;
    final spent = s.totalSpent;
    final target = s.profile.targetAmount;
    final recent = s.payments.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Tambah kategori',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => pushPage(context, const CategoryFormScreen()),
          ),
        ],
      ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: MiniStat(
                            label: 'Anggaran', value: rupiahShort(budget))),
                    Expanded(
                        child: MiniStat(
                            label: 'Terpakai',
                            value: rupiahShort(spent),
                            color: AppColors.danger)),
                    Expanded(
                        child: MiniStat(
                            label: 'Sisa',
                            value: rupiahShort(budget - spent),
                            color: budget - spent < 0
                                ? AppColors.danger
                                : AppColors.success)),
                  ],
                ),
                if (budget > 0) ...[
                  const SizedBox(height: 12),
                  RoundedProgress(
                    value: spent / budget,
                    color: spent > budget ? AppColors.danger : AppColors.rose,
                  ),
                ],
                if (target > 0 && budget > target) ...[
                  const SizedBox(height: 10),
                  Text(
                    '⚠️ Total anggaran melebihi target dana '
                    '(${rupiah(target)}).',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SectionHeader('Kategori'),
          for (final c in s.categories) _CategoryTile(category: c),
          if (s.categories.isEmpty)
            const EmptyState(
              icon: Icons.category_outlined,
              title: 'Belum ada kategori',
              message: 'Tambahkan kategori lewat ikon di kanan atas.',
            ),
          SectionHeader(
            'Pengeluaran Terbaru',
            trailing: s.payments.isEmpty
                ? null
                : TextButton(
                    onPressed: () =>
                        pushPage(context, const PaymentsScreen()),
                    child: const Text('Lihat semua'),
                  ),
          ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Belum ada pengeluaran. Catat DP / pembayaran vendor dengan '
                'tombol "Pengeluaran".',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          for (final p in recent) PaymentTile(payment: p),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final spent = s.spentInCategory(category.id!);
    final budget = category.budget;
    final over = budget > 0 && spent > budget;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => pushPage(
          context, CategoryDetailScreen(categoryId: category.id!)),
      child: Column(
        children: [
          Row(
            children: [
              IconBox(iconFor(category.iconKey), size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      budget > 0
                          ? '${rupiah(spent)} dari ${rupiah(budget)}'
                          : '${rupiah(spent)} • anggaran belum diisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: over ? AppColors.danger : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (over)
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger)
              else
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 10),
            RoundedProgress(
              value: spent / budget,
              color: over ? AppColors.danger : AppColors.rose,
              height: 8,
            ),
          ],
        ],
      ),
    );
  }
}
