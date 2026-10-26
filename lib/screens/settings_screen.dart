import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'profile_form_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editContributor(
      BuildContext context, AppState s, Contributor? c) async {
    final controller = TextEditingController(text: c?.name ?? '');
    var color = c?.colorIndex ?? (s.contributors.length % palette.length);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(c == null ? 'Tambah Penyetor' : 'Edit Penyetor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: fieldDecoration('Nama',
                    icon: Icons.person_outline, hint: 'Misal: Orang tua'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < palette.length; i++)
                    GestureDetector(
                      onTap: () => setLocal(() => color = i),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: palette[i],
                        child: color == i
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            if (c != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: const Text('Hapus',
                    style: TextStyle(color: AppColors.danger)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == 'save') {
      final name = controller.text.trim();
      if (name.isEmpty) return;
      await s.saveContributor(
          Contributor(id: c?.id, name: name, colorIndex: color));
    } else if (result == 'delete' && c != null) {
      final error = await s.deleteContributor(c.id!);
      if (error != null && context.mounted) showSnack(context, error);
    }
  }

  Future<void> _pickDay(BuildContext context, AppState s) async {
    final current = s.profile.savingReminderDay;
    final day = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tanggal pengingat setiap bulan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var d = 1; d <= 28; d++)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(ctx, d),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d == current
                              ? AppColors.rose
                              : AppColors.roseSoft,
                        ),
                        child: Text(
                          '$d',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: d == current ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (day != null) {
      await s.saveProfile(s.profile.copyWith(savingReminderDay: day));
    }
  }

  Future<void> _pickTime(BuildContext context, AppState s) async {
    final p = s.profile;
    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: p.savingReminderHour, minute: p.savingReminderMinute),
    );
    if (time != null) {
      await s.saveProfile(p.copyWith(
          savingReminderHour: time.hour, savingReminderMinute: time.minute));
    }
  }

  Future<void> _reset(BuildContext context, AppState s) async {
    final ok = await confirmDialog(
      context,
      title: 'Reset semua data?',
      message: 'Semua profil, tabungan, pengeluaran, vendor, dan checklist '
          'akan dihapus permanen dan tidak bisa dikembalikan.',
      confirmLabel: 'Reset',
    );
    if (!ok || !context.mounted) return;
    final sure = await confirmDialog(
      context,
      title: 'Yakin?',
      message: 'Ini langkah terakhir. Data benar-benar akan dihapus.',
      confirmLabel: 'Ya, hapus semua',
    );
    if (!sure || !context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await s.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile;
    final date = p.weddingDate;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionHeader('Profil Pernikahan'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.favorite, color: AppColors.rose),
              title: Text(p.coupleName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${date == null ? 'Tanggal belum diatur' : formatDateLong(date)}\n'
                'Target: ${p.targetAmount > 0 ? rupiah(p.targetAmount) : '-'}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => pushPage(context, const ProfileFormScreen()),
            ),
          ),
          SectionHeader(
            'Penyetor Dana',
            trailing: TextButton.icon(
              onPressed: () => _editContributor(context, s, null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                if (s.contributors.isEmpty)
                  const ListTile(title: Text('Belum ada penyetor')),
                for (final c in s.contributors)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: paletteColor(c.colorIndex),
                      child: Text(
                        initialOf(c.name),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text('Total setoran ${rupiah(s.incomeOf(c.id!))}'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editContributor(context, s, c),
                  ),
              ],
            ),
          ),
          const SectionHeader('Pengingat'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.savings_outlined),
                  title: const Text('Pengingat nabung bulanan'),
                  subtitle: const Text('Notifikasi rutin untuk menabung'),
                  value: p.savingReminderEnabled,
                  onChanged: (v) async {
                    if (v) await s.requestNotificationPermission();
                    await s.saveProfile(p.copyWith(savingReminderEnabled: v));
                  },
                ),
                if (p.savingReminderEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Tanggal setiap bulan'),
                    trailing: Text('Tgl ${p.savingReminderDay}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => _pickDay(context, s),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Jam'),
                    trailing: Text(
                      formatTime(p.savingReminderHour, p.savingReminderMinute),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _pickTime(context, s),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Pengingat jatuh tempo'),
                  subtitle: const Text(
                      'Pelunasan vendor (H-1 & hari H) dan tenggat checklist'),
                  value: p.dueReminderEnabled,
                  onChanged: (v) async {
                    if (v) await s.requestNotificationPermission();
                    await s.saveProfile(p.copyWith(dueReminderEnabled: v));
                  },
                ),
              ],
            ),
          ),
          const SectionHeader('Data'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Penyimpanan offline'),
                  subtitle: Text(
                      'Semua data tersimpan di HP ini. Menghapus aplikasi '
                      'akan menghapus datanya juga.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.restart_alt, color: AppColors.danger),
                  title: const Text('Reset semua data',
                      style: TextStyle(color: AppColors.danger)),
                  onTap: () => _reset(context, s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Dana Nikah v1.0.0 • Dibuat dengan 💗',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
