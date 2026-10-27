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
import 'catering_calculator_screen.dart';
import 'payment_form_screen.dart';
import 'payments_screen.dart';
import 'seserahan_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  Future<void> _openQuickBudgetEditor(
      BuildContext context, AppState s) async {
    await pushPage(context, const _QuickBudgetScreen());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final budget = s.totalBudget;
    final spent = s.totalSpent;
    final target = s.profile.targetAmount;
    final unallocated = s.unallocatedTarget;
    final recent = s.payments.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Bagi Otomatis & Edit Cepat',
            icon: const Icon(Icons.auto_fix_high_outlined),
            onPressed: () => _openQuickBudgetEditor(context, s),
          ),
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
                            label: 'Sisa Anggaran',
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
                if (target > 0) ...[
                  const Divider(height: 20),
                  InfoRow('Target total dana', rupiah(target)),
                  InfoRow(
                    unallocated >= 0
                        ? 'Belum dialokasikan ke kategori'
                        : 'Anggaran melebihi target dana',
                    rupiah(unallocated.abs()),
                    valueColor: unallocated < 0
                        ? AppColors.danger
                        : (unallocated == 0
                            ? AppColors.success
                            : AppColors.warning),
                    bold: true,
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openQuickBudgetEditor(context, s),
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(
                      budget == 0
                          ? 'Bantu Bagi Anggaran Otomatis'
                          : 'Atur Cepat / Bagi Ulang Anggaran',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      pushPage(context, const CateringCalculatorScreen()),
                  icon: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('Hitung Katering'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      pushPage(context, const SeserahanScreen()),
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: const Text('Seserahan & Mahar'),
                ),
              ),
            ],
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

/// Layar edit cepat semua anggaran kategori + tombol Bagi Otomatis.
class _QuickBudgetScreen extends StatefulWidget {
  const _QuickBudgetScreen();

  @override
  State<_QuickBudgetScreen> createState() => _QuickBudgetScreenState();
}

class _QuickBudgetScreenState extends State<_QuickBudgetScreen> {
  late final TextEditingController _baseTotal;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final initialTotal = s.profile.targetAmount > 0
        ? s.profile.targetAmount
        : (s.totalBudget > 0 ? s.totalBudget : 50000000);
    _baseTotal = TextEditingController(text: amountToText(initialTotal));
    for (final c in s.categories) {
      _controllers[c.id!] =
          TextEditingController(text: amountToText(c.budget));
    }
  }

  @override
  void dispose() {
    _baseTotal.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _currentSum => _controllers.values
      .fold<int>(0, (sum, ctrl) => sum + parseAmount(ctrl.text));

  void _autoDistribute() {
    final s = context.read<AppState>();
    final total = parseAmount(_baseTotal.text);
    if (total <= 0) {
      showSnack(context, 'Masukkan total dana acuan terlebih dahulu');
      return;
    }
    final recommended = s.calculateRecommendedBudgets(total);
    setState(() {
      for (final entry in recommended.entries) {
        _controllers[entry.key]?.text = amountToText(entry.value);
      }
    });
  }

  Future<void> _saveAll() async {
    final s = context.read<AppState>();
    final budgets = <int, int>{
      for (final entry in _controllers.entries)
        entry.key: parseAmount(entry.value.text),
    };
    await s.saveCategoryBudgets(budgets);
    if (mounted) {
      showSnack(context, 'Anggaran semua kategori berhasil disimpan');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final base = parseAmount(_baseTotal.text);
    final sum = _currentSum;
    final diff = base - sum;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Cepat Anggaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            color: AppColors.roseSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bagi Otomatis Berdasarkan Persentase Ideal',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Katering ~35%, Gedung ~15%, Dekorasi ~10%, MUA & Busana ~10%, '
                  'Foto/Video ~7%, Mahar ~5%, Seserahan ~5%, Undangan/Souvenir ~5%, dll.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  controller: _baseTotal,
                  label: 'Total dana yang ingin dibagi',
                  required: false,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _autoDistribute,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Hitung & Isi Otomatis ke Bawah'),
                  ),
                ),
                const Divider(height: 20),
                InfoRow('Total anggaran terisi', rupiah(sum), bold: true),
                if (base > 0)
                  InfoRow(
                    diff >= 0 ? 'Sisa belum terbagi' : 'Melebihi acuan',
                    rupiah(diff.abs()),
                    valueColor: diff < 0 ? AppColors.danger : AppColors.success,
                  ),
              ],
            ),
          ),
          const SectionHeader('Nominal per Kategori'),
          for (final c in s.categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _controllers[c.id!],
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                onChanged: (_) => setState(() {}),
                decoration: fieldDecoration(
                  c.name,
                  icon: iconFor(c.iconKey),
                  prefixText: 'Rp ',
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            style: bigButtonStyle,
            onPressed: _saveAll,
            child: const Text('Simpan Semua Anggaran'),
          ),
        ],
      ),
    );
  }
}
