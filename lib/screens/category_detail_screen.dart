import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'category_form_screen.dart';
import 'payment_form_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final int categoryId;

  Future<void> _delete(
      BuildContext context, AppState s, BudgetCategory c) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus kategori?',
      message: 'Kategori "${c.name}" akan dihapus.',
    );
    if (!ok || !context.mounted) return;
    final error = await s.deleteCategory(c.id!);
    if (!context.mounted) return;
    if (error != null) {
      showSnack(context, error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.categoryById(categoryId);
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.category_outlined,
          title: 'Kategori tidak ditemukan',
          message: 'Kategori ini mungkin sudah dihapus.',
        ),
      );
    }
    final spent = s.spentInCategory(categoryId);
    final remaining = c.budget - spent;
    final payments = s.payments.where((p) => p.categoryId == categoryId);
    final vendors = s.vendors.where((v) => v.categoryId == categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                pushPage(context, CategoryFormScreen(category: c)),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, s, c),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            pushPage(context, PaymentFormScreen(presetCategoryId: categoryId)),
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
                    IconBox(iconFor(c.iconKey), size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                InfoRow('Anggaran',
                    c.budget > 0 ? rupiah(c.budget) : 'Belum diisi'),
                InfoRow('Terpakai', rupiah(spent),
                    valueColor: AppColors.danger),
                if (c.budget > 0)
                  InfoRow(
                    remaining >= 0 ? 'Sisa anggaran' : 'Melebihi anggaran',
                    rupiah(remaining.abs()),
                    valueColor:
                        remaining >= 0 ? AppColors.success : AppColors.danger,
                    bold: true,
                  ),
                if (c.budget > 0) ...[
                  const SizedBox(height: 10),
                  RoundedProgress(
                    value: spent / c.budget,
                    color: remaining < 0 ? AppColors.danger : AppColors.rose,
                  ),
                ],
              ],
            ),
          ),
          if (vendors.isNotEmpty) ...[
            const SectionHeader('Vendor'),
            for (final v in vendors) VendorTile(vendor: v),
          ],
          const SectionHeader('Riwayat Pengeluaran'),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Belum ada pengeluaran di kategori ini.',
                  style: TextStyle(color: AppColors.muted)),
            ),
          for (final p in payments) PaymentTile(payment: p),
        ],
      ),
    );
  }
}
