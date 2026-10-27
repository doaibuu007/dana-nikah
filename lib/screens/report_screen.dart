import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../utils/exporter.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class _ChartEntry {
  const _ChartEntry(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// 0 = pengeluaran, 1 = anggaran
  int _mode = 0;

  void _showExportSheet(BuildContext context, AppState s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Bagikan & Export Laporan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: AppColors.success),
              title: const Text('Kirim Ringkasan ke WhatsApp'),
              subtitle: const Text(
                  'Kirim laporan progres tabungan & tagihan ke pasangan/keluarga'),
              onTap: () {
                Navigator.pop(ctx);
                shareViaWhatsapp(context, buildWhatsappSummary(s));
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.rose),
              title: const Text('Salin Teks Ringkasan'),
              subtitle: const Text('Salin laporan rapi ke clipboard'),
              onTap: () {
                Navigator.pop(ctx);
                copyToClipboard(
                  context,
                  buildWhatsappSummary(s),
                  'Ringkasan laporan berhasil disalin',
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.table_chart_outlined, color: AppColors.gold),
              title: const Text('Salin Data CSV (Excel / Google Sheets)'),
              subtitle: const Text(
                  'Salin seluruh tabel transaksi dalam format CSV'),
              onTap: () {
                Navigator.pop(ctx);
                copyToClipboard(
                  context,
                  buildCsvExport(s),
                  'Data CSV disalin! Tempel ke file .csv atau Google Sheets.',
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    final categoryEntries = <_ChartEntry>[];
    for (var i = 0; i < s.categories.length; i++) {
      final c = s.categories[i];
      final value = _mode == 0 ? s.spentInCategory(c.id!) : c.budget;
      if (value > 0) {
        categoryEntries.add(_ChartEntry(c.name, value, paletteColor(i)));
      }
    }
    categoryEntries.sort((a, b) => b.value.compareTo(a.value));

    final contributorEntries = <_ChartEntry>[
      for (final c in s.contributors)
        if (s.incomeOf(c.id!) > 0)
          _ChartEntry(c.name, s.incomeOf(c.id!), paletteColor(c.colorIndex)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            tooltip: 'Bagikan / Export',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showExportSheet(context, s),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      shareViaWhatsapp(context, buildWhatsappSummary(s)),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Bagikan ke WA'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showExportSheet(context, s),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text('Export / Salin'),
                ),
              ),
            ],
          ),
          const SectionHeader('Per Kategori'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Pengeluaran'),
                icon: Icon(Icons.receipt_long),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Anggaran'),
                icon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (set) => setState(() => _mode = set.first),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: _DonutWithLegend(
              entries: categoryEntries,
              emptyText: _mode == 0
                  ? 'Belum ada pengeluaran yang dicatat.'
                  : 'Anggaran per kategori belum diisi.',
            ),
          ),
          const SectionHeader('Anggaran vs Realisasi'),
          AppCard(
            child: Column(
              children: [
                for (final c in s.categories)
                  _BudgetRow(
                    name: c.name,
                    budget: c.budget,
                    spent: s.spentInCategory(c.id!),
                  ),
              ],
            ),
          ),
          const SectionHeader('Kontribusi Tabungan'),
          AppCard(
            child: _DonutWithLegend(
              entries: contributorEntries,
              emptyText: 'Belum ada setoran tabungan.',
            ),
          ),
          const SectionHeader('Ringkasan'),
          AppCard(
            child: Column(
              children: [
                InfoRow('Target dana', rupiah(s.profile.targetAmount)),
                InfoRow('Dana terkumpul', rupiah(s.totalIncome),
                    valueColor: AppColors.success),
                InfoRow('Total pengeluaran', rupiah(s.totalSpent),
                    valueColor: AppColors.danger),
                InfoRow('Saldo saat ini', rupiah(s.balance),
                    valueColor:
                        s.balance < 0 ? AppColors.danger : AppColors.success,
                    bold: true),
                const Divider(height: 20),
                InfoRow('Total anggaran', rupiah(s.totalBudget)),
                InfoRow('Total kontrak vendor', rupiah(s.totalContract)),
                InfoRow('Sisa tagihan vendor', rupiah(s.totalOutstanding),
                    valueColor: AppColors.danger),
                InfoRow(
                  'Dana bebas setelah lunas',
                  rupiah(s.balance - s.totalOutstanding),
                  valueColor: s.balance - s.totalOutstanding < 0
                      ? AppColors.danger
                      : AppColors.success,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutWithLegend extends StatelessWidget {
  const _DonutWithLegend({required this.entries, required this.emptyText});

  final List<_ChartEntry> entries;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(emptyText,
              style: const TextStyle(color: AppColors.muted)),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 58,
                  sections: [
                    for (final e in entries)
                      PieChartSectionData(
                        value: e.value.toDouble(),
                        color: e.color,
                        radius: 44,
                        title: e.value / total >= 0.07
                            ? percent(e.value / total)
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text(
                    rupiahShort(total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: e.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(rupiah(e.value),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(
                  width: 44,
                  child: Text(
                    percent(e.value / total),
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.name,
    required this.budget,
    required this.spent,
  });

  final String name;
  final int budget;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final diff = budget - spent;
    final over = budget > 0 && diff < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(
                budget == 0
                    ? '-'
                    : (over
                        ? 'Lebih ${rupiahShort(-diff)}'
                        : 'Sisa ${rupiahShort(diff)}'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: over ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${rupiah(spent)} / ${budget == 0 ? 'belum dianggarkan' : rupiah(budget)}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          if (budget > 0) ...[
            const SizedBox(height: 6),
            RoundedProgress(
              value: spent / budget,
              color: over ? AppColors.danger : AppColors.rose,
              height: 6,
            ),
          ],
        ],
      ),
    );
  }
}
