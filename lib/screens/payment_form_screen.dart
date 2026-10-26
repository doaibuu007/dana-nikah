import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({
    super.key,
    this.payment,
    this.presetCategoryId,
    this.presetVendorId,
  });

  final Payment? payment;
  final int? presetCategoryId;
  final int? presetVendorId;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  int? _categoryId;
  int? _vendorId;
  late String _type;
  late DateTime _date;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final p = widget.payment;

    int? vendorId = p?.vendorId ?? widget.presetVendorId;
    if (s.vendorById(vendorId) == null) vendorId = null;
    _vendorId = vendorId;

    _categoryId = p?.categoryId ?? widget.presetCategoryId;
    if (_categoryId == null && vendorId != null) {
      _categoryId = s.vendorById(vendorId)?.categoryId;
    }

    _type = p?.type ??
        (vendorId == null
            ? 'Lainnya'
            : (s.paidToVendor(vendorId) == 0 ? 'DP' : 'Cicilan'));
    _amount =
        TextEditingController(text: p == null ? '' : amountToText(p.amount));
    _note = TextEditingController(text: p?.note ?? '');
    _date = p?.date ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Sisa tagihan vendor, tanpa menghitung pembayaran yang sedang diedit.
  int _remainingFor(AppState s, Vendor v) {
    var paid = s.paidToVendor(v.id!);
    final p = widget.payment;
    if (p != null && p.vendorId == v.id) paid -= p.amount;
    return math.max(0, v.contractPrice - paid);
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _categoryError = 'Pilih kategori');
    }
    if (!formOk || categoryId == null) return;
    await context.read<AppState>().savePayment(Payment(
          id: widget.payment?.id,
          categoryId: categoryId,
          vendorId: _vendorId,
          amount: parseAmount(_amount.text),
          date: _date,
          type: _type,
          note: _note.text.trim(),
        ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.payment?.id;
    if (id == null) return;
    final ok = await confirmDialog(context,
        title: 'Hapus pengeluaran?',
        message: 'Data pengeluaran ini akan dihapus.');
    if (!ok || !mounted) return;
    await context.read<AppState>().deletePayment(id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final editing = widget.payment != null;
    final vendor = s.vendorById(_vendorId);

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
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
            PickerField<int>(
              label: 'Vendor (opsional)',
              value: _vendorId,
              icon: Icons.storefront_outlined,
              noneLabel: 'Tanpa vendor',
              options: [
                for (final v in s.vendors)
                  PickerOption<int>(
                    value: v.id!,
                    label: v.name,
                    icon: iconFor(s.categoryById(v.categoryId)?.iconKey),
                  ),
              ],
              onChanged: (id) => setState(() {
                _vendorId = id;
                final cat = s.vendorById(id)?.categoryId;
                if (cat != null) {
                  _categoryId = cat;
                  _categoryError = null;
                }
              }),
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
            if (vendor != null) ...[
              const SizedBox(height: 12),
              _VendorInfo(
                vendor: vendor,
                paid: vendor.contractPrice - _remainingFor(s, vendor),
                remaining: _remainingFor(s, vendor),
                onFillRemaining: () => setState(() {
                  _amount.text = amountToText(_remainingFor(s, vendor));
                  _type = 'Pelunasan';
                }),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Jenis pembayaran',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in paymentTypes)
                  ChoiceChip(
                    label: Text(t),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            MoneyField(controller: _amount, label: 'Nominal'),
            const SizedBox(height: 16),
            DateField(
              label: 'Tanggal bayar',
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
                  icon: Icons.notes, hint: 'Misal: transfer BCA, nota no. 12'),
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

class _VendorInfo extends StatelessWidget {
  const _VendorInfo({
    required this.vendor,
    required this.paid,
    required this.remaining,
    required this.onFillRemaining,
  });

  final Vendor vendor;
  final int paid;
  final int remaining;
  final VoidCallback onFillRemaining;

  @override
  Widget build(BuildContext context) {
    if (vendor.contractPrice <= 0) {
      return const Text(
        'Nilai kontrak vendor belum diisi.',
        style: TextStyle(fontSize: 12, color: AppColors.muted),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.roseSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow('Nilai kontrak', rupiah(vendor.contractPrice)),
          InfoRow('Sudah dibayar', rupiah(math.max(0, paid))),
          InfoRow('Sisa tagihan', rupiah(remaining),
              valueColor: remaining > 0 ? AppColors.danger : AppColors.success,
              bold: true),
          if (remaining > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onFillRemaining,
                icon: const Icon(Icons.done_all),
                label: const Text('Isi sisa tagihan (pelunasan)'),
              ),
            ),
        ],
      ),
    );
  }
}
