import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'payment_form_screen.dart';
import 'vendor_form_screen.dart';

class VendorDetailScreen extends StatelessWidget {
  const VendorDetailScreen({super.key, required this.vendorId});

  final int vendorId;

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showSnack(context, 'Tidak bisa membuka aplikasi.');
      }
    } catch (_) {
      if (context.mounted) showSnack(context, 'Tidak bisa membuka aplikasi.');
    }
  }

  Future<void> _delete(BuildContext context, AppState s, Vendor v) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus vendor?',
      message: 'Vendor "${v.name}" akan dihapus. Riwayat pembayarannya tetap '
          'tersimpan di kategori anggaran.',
    );
    if (!ok || !context.mounted) return;
    await s.deleteVendor(v.id!);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = s.vendorById(vendorId);
    if (v == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.storefront_outlined,
          title: 'Vendor tidak ditemukan',
          message: 'Vendor ini mungkin sudah dihapus.',
        ),
      );
    }
    final category = s.categoryById(v.categoryId);
    final status = s.vendorStatus(v);
    final paid = s.paidToVendor(vendorId);
    final remaining = s.vendorRemaining(v);
    final due = v.dueDate;
    final payments = s.payments.where((p) => p.vendorId == vendorId);
    final phone = v.phone.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(v.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => pushPage(context, VendorFormScreen(vendor: v)),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, s, v),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            pushPage(context, PaymentFormScreen(presetVendorId: vendorId)),
        icon: const Icon(Icons.add),
        label: const Text('Bayar'),
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
                    IconBox(iconFor(category?.iconKey), size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Text(category?.name ?? '-',
                              style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    StatusBadge(status),
                  ],
                ),
                const SizedBox(height: 14),
                InfoRow('Nilai kontrak',
                    v.contractPrice > 0 ? rupiah(v.contractPrice) : '-'),
                InfoRow('Sudah dibayar', rupiah(paid),
                    valueColor: AppColors.success),
                InfoRow('Sisa tagihan', rupiah(remaining),
                    valueColor:
                        remaining > 0 ? AppColors.danger : AppColors.success,
                    bold: true),
                if (v.contractPrice > 0) ...[
                  const SizedBox(height: 10),
                  RoundedProgress(
                    value: paid / v.contractPrice,
                    color: vendorStatusColor(status),
                  ),
                ],
                if (due != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 18, color: AppColors.rose),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Jatuh tempo: ${formatDateLong(due)}'
                          '${status == VendorStatus.paid ? '' : ' (${dueLabel(due)})'}',
                        ),
                      ),
                    ],
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: AppColors.rose),
                      const SizedBox(width: 6),
                      Text(phone),
                    ],
                  ),
                ],
                if (v.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 18, color: AppColors.rose),
                      const SizedBox(width: 6),
                      Expanded(child: Text(v.note)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _launch(context, Uri(scheme: 'tel', path: phone)),
                      icon: const Icon(Icons.phone),
                      label: const Text('Telepon'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _launch(context,
                          Uri.parse('https://wa.me/${waNumber(phone)}')),
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ),
          const SectionHeader('Riwayat Pembayaran'),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Belum ada pembayaran ke vendor ini.',
                  style: TextStyle(color: AppColors.muted)),
            ),
          for (final p in payments) PaymentTile(payment: p),
        ],
      ),
    );
  }
}
