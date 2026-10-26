import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class VendorFormScreen extends StatefulWidget {
  const VendorFormScreen({super.key, this.vendor});

  final Vendor? vendor;

  @override
  State<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _price;
  late final TextEditingController _note;
  int? _categoryId;
  DateTime? _dueDate;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    final v = widget.vendor;
    _name = TextEditingController(text: v?.name ?? '');
    _phone = TextEditingController(text: v?.phone ?? '');
    _price = TextEditingController(
        text: v == null ? '' : amountToText(v.contractPrice));
    _note = TextEditingController(text: v?.note ?? '');
    final s = context.read<AppState>();
    _categoryId = s.categoryById(v?.categoryId)?.id;
    _dueDate = v?.dueDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _categoryError = 'Pilih kategori');
    }
    if (!formOk || categoryId == null) return;
    await context.read<AppState>().saveVendor(Vendor(
          id: widget.vendor?.id,
          name: _name.text.trim(),
          categoryId: categoryId,
          phone: _phone.text.trim(),
          contractPrice: parseAmount(_price.text),
          dueDate: _dueDate,
          note: _note.text.trim(),
        ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vendor == null ? 'Tambah Vendor' : 'Edit Vendor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Nama vendor',
                  icon: Icons.storefront_outlined,
                  hint: 'Misal: Gedung Serbaguna Melati'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            PickerField<int>(
              label: 'Kategori',
              value: _categoryId,
              icon: Icons.label_outline,
              errorText: _categoryError,
              options: [
                for (final c in s.categories)
                  PickerOption<int>(
                    value: c.id!,
                    label: c.name,
                    icon: iconFor(c.iconKey),
                  ),
              ],
              onChanged: (id) => setState(() {
                _categoryId = id;
                _categoryError = null;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration('No. HP / WhatsApp (opsional)',
                  icon: Icons.phone, hint: '08xxxxxxxxxx'),
            ),
            const SizedBox(height: 16),
            MoneyField(
              controller: _price,
              label: 'Nilai kontrak / harga total',
              required: false,
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Jatuh tempo pelunasan (opsional)',
              value: _dueDate,
              allowClear: true,
              onChanged: (d) => setState(() => _dueDate = d),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Catatan (opsional)',
                  icon: Icons.notes,
                  hint: 'Paket yang diambil, alamat, rekening, dll'),
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
