import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'income_form_screen.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  int? _filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final target = s.profile.targetAmount;
    final filter = _filter;
    final list = filter == null
        ? s.incomes
        : s.incomes.where((i) => i.contributorId == filter).toList();

    final children = <Widget>[];
    String? lastMonth;
    for (final Income i in list) {
      final monthKey = '${i.date.year}-${i.date.month}';
      if (monthKey != lastMonth) {
        lastMonth = monthKey;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            formatMonthYear(i.date),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted),
          ),
        ));
      }
      children.add(IncomeTile(income: i));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabungan',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => pushPage(context, const IncomeFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Setoran'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Terkumpul',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rupiah(s.totalIncome),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (target > 0) ...[
                  const SizedBox(height: 10),
                  RoundedProgress(value: s.savingProgress),
                  const SizedBox(height: 6),
                  Text(
                    '${percent(s.savingProgress)} dari target ${rupiah(target)}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final c in s.contributors)
                ChoiceChip(
                  label: Text('${c.name} · ${rupiahShort(s.incomeOf(c.id!))}'),
                  selected: _filter == c.id,
                  onSelected: (_) => setState(() => _filter = c.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.savings_outlined,
              title: 'Belum ada setoran',
              message: 'Catat setiap dana yang ditabung untuk pernikahan '
                  'dengan menekan tombol "Setoran".',
            )
          else
            ...children,
        ],
      ),
    );
  }
}
