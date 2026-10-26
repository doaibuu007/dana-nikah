import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'task_form_screen.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pending = s.tasks.where((t) => !t.done).toList()
      ..sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return (a.id ?? 0).compareTo(b.id ?? 0);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    final done = s.tasks.where((t) => t.done).toList();
    final total = s.tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
                      '${done.length}/$total selesai',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RoundedProgress(
                  value: total == 0 ? 0 : done.length / total,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          if (total == 0)
            const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Checklist kosong',
              message: 'Tambahkan daftar hal yang perlu disiapkan.',
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
