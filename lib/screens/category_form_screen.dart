import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.category});

  final BudgetCategory? category;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _budget;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _budget = TextEditingController(text: c == null ? '' : amountToText(c.budget));
    _iconKey = c?.iconKey ?? 'other';
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<AppState>();
    final c = widget.category;
    await s.saveCategory(BudgetCategory(
      id: c?.id,
      name: _name.text.trim(),
      iconKey: _iconKey,
      budget: parseAmount(_budget.text),
      sortOrder: c?.sortOrder ?? s.categories.length,
    ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration:
                  fieldDecoration('Nama kategori', icon: Icons.label_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            MoneyField(
              controller: _budget,
              label: 'Anggaran',
              required: false,
              helperText: 'Perkiraan biaya untuk kategori ini',
            ),
            const SizedBox(height: 20),
            const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in categoryIcons.entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _iconKey = entry.key),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _iconKey == entry.key
                            ? AppColors.rose
                            : AppColors.roseSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        entry.value,
                        color: _iconKey == entry.key
                            ? Colors.white
                            : AppColors.rose,
                      ),
                    ),
                  ),
              ],
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
