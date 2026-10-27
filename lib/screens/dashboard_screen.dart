import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/exporter.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'catering_calculator_screen.dart';
import 'profile_form_screen.dart';
import 'report_screen.dart';
import 'seserahan_screen.dart';
import 'settings_screen.dart';
import 'task_form_screen.dart';
import 'vendor_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dana Nikah',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Bagikan ke WhatsApp',
            icon: const Icon(Icons.share_outlined),
            onPressed: () =>
                shareViaWhatsapp(context, buildWhatsappSummary(s)),
          ),
          IconButton(
            tooltip: 'Laporan',
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => pushPage(context, const ReportScreen()),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => pushPage(context, const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _HeroCard(state: s),
          _FundCard(state: s),
          _StatsRow(state: s),
          _QuickToolsCard(state: s),
          _BudgetCard(state: s),
          _ContributionCard(state: s),
          _UpcomingCard(state: s),
          _ChecklistCard(state: s),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final days = state.daysToWedding;
    final date = state.profile.weddingDate;
    final months = state.monthsToWedding;
    String headline;
    String caption;
    if (days == null || date == null) {
      headline = 'Tentukan Hari H';
      caption = 'Ketuk untuk mengatur tanggal pernikahan';
    } else if (days > 0) {
      headline = 'H-$days';
      caption = formatDateLong(date);
    } else if (days == 0) {
      headline = 'Hari Ini! 💍';
      caption = 'Selamat menempuh hidup baru';
    } else {
      headline = 'Sah! 🎉';
      caption = 'Sudah menikah ${-days} hari';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => pushPage(context, const ProfileFormScreen()),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: heroGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.profile.coupleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(caption, style: const TextStyle(color: Colors.white)),
                if (months != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Sekitar $months bulan lagi',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  const _FundCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final target = state.profile.targetAmount;
    final suggestion = state.monthlySavingSuggestion;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Dana Terkumpul',
                    style: TextStyle(color: AppColors.muted)),
              ),
              if (target > 0)
                Text(
                  percent(state.savingProgress),
                  style: const TextStyle(
                      color: AppColors.rose, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(state.totalIncome),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (target > 0) ...[
            Text('dari target ${rupiah(target)}',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            RoundedProgress(value: state.savingProgress, height: 12),
            const SizedBox(height: 8),
            Text(
              state.remainingTarget > 0
                  ? 'Kurang ${rupiah(state.remainingTarget)} lagi'
                  : 'Target tercapai! 🎉',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: state.remainingTarget > 0
                    ? AppColors.ink
                    : AppColors.success,
              ),
            ),
          ] else
            TextButton.icon(
              onPressed: () => pushPage(context, const ProfileFormScreen()),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Atur target dana'),
            ),
          if (suggestion != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.roseSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.rose),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saran nabung ${rupiah(suggestion)}/bulan agar target '
                      'tercapai sebelum hari H.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.receipt_long,
              label: 'Terpakai',
              value: rupiahShort(state.totalSpent),
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Saldo',
              value: rupiahShort(state.balance),
              color: state.balance < 0 ? AppColors.danger : AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.storefront_outlined,
              label: 'Sisa Tagihan',
              value: rupiahShort(state.totalOutstanding),
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon, color: color, size: 32),
          const SizedBox(height: 10),
          MiniStat(label: label, value: value, color: AppColors.ink),
        ],
      ),
    );
  }
}

class _QuickToolsCard extends StatelessWidget {
  const _QuickToolsCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final bought = state.seserahanBoughtCount;
    final totalSeserahan = state.seserahanItems.length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alat Bantu & Rincian',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () =>
                      pushPage(context, const CateringCalculatorScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.roseSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.restaurant_menu,
                            color: AppColors.rose),
                        const SizedBox(height: 6),
                        const Text('Kalkulator Katering',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(
                          '${state.profile.invitationCount} undangan',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => pushPage(context, const SeserahanScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.roseSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.card_giftcard, color: AppColors.rose),
                        const SizedBox(height: 6),
                        const Text('Seserahan & Mahar',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(
                          '$bought/$totalSeserahan terbeli',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final budget = state.totalBudget;
    final spent = state.totalSpent;
    final target = state.profile.targetAmount;
    final over = budget > 0 && spent > budget;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Anggaran vs Pengeluaran',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          InfoRow('Total anggaran', rupiah(budget)),
          InfoRow('Sudah dikeluarkan', rupiah(spent),
              valueColor: over ? AppColors.danger : null),
          if (budget > 0) ...[
            const SizedBox(height: 8),
            RoundedProgress(
              value: spent / budget,
              color: over ? AppColors.danger : AppColors.rose,
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Isi anggaran tiap kategori di tab Anggaran.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          if (target > 0 && budget > target)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Total anggaran melebihi target dana sebesar '
                      '${rupiah(budget - target)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (state.contributors.isEmpty) return const SizedBox.shrink();
    final total = state.totalIncome;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kontribusi Tabungan',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final c in state.contributors) ...[
            Builder(builder: (context) {
              final amount = state.incomeOf(c.id!);
              final color = paletteColor(c.colorIndex);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 5, backgroundColor: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c.name)),
                        Text(
                          rupiah(amount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            total == 0 ? '0%' : percent(amount / total),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RoundedProgress(
                      value: total == 0 ? 0 : amount / total,
                      color: color,
                      height: 6,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _Upcoming {
  const _Upcoming({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = <_Upcoming>[];
    for (final v in state.vendors) {
      final due = v.dueDate;
      if (due == null || state.vendorStatus(v) == VendorStatus.paid) continue;
      items.add(_Upcoming(
        date: due,
        title: 'Pelunasan ${v.name}',
        subtitle: 'Sisa ${rupiah(state.vendorRemaining(v))}',
        icon: Icons.storefront,
        page: VendorDetailScreen(vendorId: v.id!),
      ));
    }
    for (final t in state.tasks) {
      final due = t.dueDate;
      if (t.done || due == null) continue;
      items.add(_Upcoming(
        date: due,
        title: t.title,
        subtitle: 'Checklist',
        icon: Icons.fact_check_outlined,
        page: TaskFormScreen(task: t),
      ));
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    final shown = items.take(5).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jadwal & Jatuh Tempo',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada jadwal. Isi tanggal jatuh tempo vendor atau '
                'tanggal checklist agar muncul di sini.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          for (final item in shown)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconBox(item.icon, size: 38),
              title: Text(item.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(item.subtitle),
              trailing: Text(
                dueLabel(item.date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: daysBetween(DateTime.now(), item.date) < 0
                      ? AppColors.danger
                      : AppColors.rose,
                ),
              ),
              onTap: () => pushPage(context, item.page),
            ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final total = state.tasks.length;
    if (total == 0) return const SizedBox.shrink();
    final done = state.tasksDone;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Persiapan Pernikahan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text('$done/$total selesai',
                  style: const TextStyle(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          RoundedProgress(
              value: done / total, color: AppColors.success, height: 8),
        ],
      ),
    );
  }
}
