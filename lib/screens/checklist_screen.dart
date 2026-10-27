import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'seserahan_screen.dart';
import 'task_form_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  String _query = '';
  int? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _query.trim().toLowerCase();

    final filtered = s.tasks.where((t) {
      if (_categoryFilter != null && t.categoryId != _categoryFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final catName =
            s.categoryById(t.categoryId)?.name.toLowerCase() ?? '';
        final match = t.title.toLowerCase().contains(q) ||
            t.note.toLowerCase().contains(q) ||
            catName.contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    final pending = filtered.where((t) => !t.done).toList()
      ..sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return (a.id ?? 0).compareTo(b.id ?? 0);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    final done = filtered.where((t) => t.done).toList();
    final totalAll = s.tasks.length;
    final doneAll = s.tasksDone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Rincian Seserahan & Mahar',
            icon: const Icon(Icons.card_giftcard_outlined),
            onPressed: () => pushPage(context, const SeserahanScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => pushPage(context, const TaskFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Tugas'),
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
                    const Expanded(
                      child: Text('Progres persiapan',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      '$doneAll/$totalAll selesai',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RoundedProgress(
                  value: totalAll == 0 ? 0 : doneAll / totalAll,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          SearchBarField(
            hint: 'Cari tugas persiapan...',
            value: _query,
            onChanged: (v) => setState(() => _query = v),
          ),
          if (s.categories.any((c) =>
              s.tasks.any((t) => t.categoryId == c.id))) ...[
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
                    if (s.tasks.any((t) => t.categoryId == c.id))
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
          const SizedBox(height: 4),
          if (filtered.isEmpty)
            EmptyState(
              icon: Icons.fact_check_outlined,
              title: totalAll == 0 ? 'Checklist kosong' : 'Tidak ditemukan',
              message: totalAll == 0
                  ? 'Tambahkan daftar hal yang perlu disiapkan.'
                  : 'Tidak ada tugas yang cocok dengan pencarian.',
            ),
          if (pending.isNotEmpty) ...[
            SectionHeader('Belum selesai (${pending.length})'),
            for (final t in pending) _TaskTile(task: t),
          ],
          if (done.isNotEmpty) ...[
            SectionHeader('Selesai (${done.length})'),
            for (final t in done) _TaskTile(task: t),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final due = task.dueDate;
    final category = s.categoryById(task.categoryId);
    final overdue =
        !task.done && due != null && daysBetween(DateTime.now(), due) < 0;
    final parts = <String>[
      if (due != null) '${formatDate(due)} • ${dueLabel(due)}',
      if (category != null) category.name,
    ];

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      onTap: () => pushPage(context, TaskFormScreen(task: task)),
      child: Row(
        children: [
          Checkbox(
            value: task.done,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (_) => s.toggleTask(task),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: task.done ? AppColors.muted : AppColors.ink,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (parts.isNotEmpty)
                  Text(
                    parts.join(' • '),
                    style: TextStyle(
                      fontSize: 12,
                      color: overdue ? AppColors.danger : AppColors.muted,
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
