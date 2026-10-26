import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class IncomeFormScreen extends StatefulWidget {
  const IncomeFormScreen({super.key, this.income});

  final Income? income;

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  int? _contributorId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final i = widget.income;
    _contributorId = i?.contributorId ??
        (s.contributors.isNotEmpty ? s.contributors.first.id : null);
    _amount = TextEditingController(text: i == null ? '' : amountToText(i.amount));
    _note = TextEditingController(text: i?.note ?? '');
    _date = i?.date ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final contributorId = _contributorId;
    if (contributorId == null) {
      showSnack(context, 'Pilih siapa yang menyetor dulu');
      return;
    }
    await context.read<AppState>().saveIncome(Income(
          id: widget.income?.id,
          contributorId: contributorId,
          amount: parseAmount(_amount.text),
          date: _date,
          note: _note.text.trim(),
        ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.income?.id;
    if (id == null) return;
    final ok = await confirmDialog(context,
        title: 'Hapus setoran?', message: 'Data setoran ini akan dihapus.');
    if (!ok || !mounted) return;
    await context.read<AppState>().deleteIncome(id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final editing = widget.income != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Setoran' : 'Tambah Setoran'),
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
            const Text('Siapa yang menyetor?',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (s.contributors.isEmpty)
              const Text(
                'Belum ada penyetor. Tambahkan di menu Pengaturan.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in s.contributors)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _contributorId == c.id,
                      selectedColor:
                          paletteColor(c.colorIndex).withValues(alpha: 0.25),
                      onSelected: (_) => setState(() => _contributorId = c.id),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            MoneyField(controller: _amount, label: 'Nominal setoran'),
            const SizedBox(height: 16),
            DateField(
              label: 'Tanggal',
              value: _date,
              onChanged: (d) {
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Catatan (opsional)',
                  icon: Icons.notes, hint: 'Misal: gaji bulan ini, bonus'),
            ),
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
