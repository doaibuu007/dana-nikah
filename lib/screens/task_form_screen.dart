import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../utils/category_icons.dart';
import '../widgets/common.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskItem? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  DateTime? _dueDate;
  int? _categoryId;
  late bool _done;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _note = TextEditingController(text: t?.note ?? '');
    _dueDate = t?.dueDate;
    _categoryId = context.read<AppState>().categoryById(t?.categoryId)?.id;
    _done = t?.done ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AppState>().saveTask(TaskItem(
          id: widget.task?.id,
          title: _title.text.trim(),
          done: _done,
          dueDate: _dueDate,
          categoryId: _categoryId,
          note: _note.text.trim(),
        ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.task?.id;
    if (id == null) return;
    final ok = await confirmDialog(context,
        title: 'Hapus tugas?', message: 'Tugas ini akan dihapus dari checklist.');
    if (!ok || !mounted) return;
    await context.read<AppState>().deleteTask(id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final editing = widget.task != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Tugas' : 'Tambah Tugas'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Nama tugas',
                  icon: Icons.fact_check_outlined,
                  hint: 'Misal: Booking gedung'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Tenggat (opsional)',
              value: _dueDate,
              allowClear: true,
              onChanged: (d) => setState(() => _dueDate = d),
            ),
            const SizedBox(height: 16),
            PickerField<int>(
              label: 'Kategori (opsional)',
              value: _categoryId,
              icon: Icons.label_outline,
              noneLabel: 'Tanpa kategori',
              options: [
                for (final c in s.categories)
                  PickerOption<int>(
                    value: c.id!,
                    label: c.name,
                    icon: iconFor(c.iconKey),
                  ),
              ],
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  fieldDecoration('Catatan (opsional)', icon: Icons.notes),
            ),
            if (editing) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sudah selesai'),
                value: _done,
                onChanged: (v) => setState(() => _done = v),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              style: bigButtonStyle,
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
