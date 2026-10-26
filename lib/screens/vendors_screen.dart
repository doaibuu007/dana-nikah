import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'vendor_form_screen.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  VendorStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final filter = _filter;
    final list = filter == null
        ? s.vendors
        : s.vendors.where((v) => s.vendorStatus(v) == filter).toList();

    int countOf(VendorStatus st) =>
        s.vendors.where((v) => s.vendorStatus(v) == st).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => pushPage(context, const VendorFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Vendor'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: MiniStat(
                      label: 'Total kontrak',
                      value: rupiahShort(s.totalContract)),
                ),
                Expanded(
                  child: MiniStat(
                    label: 'Sudah dibayar',
                    value: rupiahShort(s.totalPaidToVendors),
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: MiniStat(
                    label: 'Sisa tagihan',
                    value: rupiahShort(s.totalOutstanding),
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Semua (${s.vendors.length})'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final st in VendorStatus.values)
                ChoiceChip(
                  label: Text('${st.label} (${countOf(st)})'),
                  selected: _filter == st,
                  onSelected: (_) => setState(() => _filter = st),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            EmptyState(
              icon: Icons.storefront_outlined,
              title: s.vendors.isEmpty ? 'Belum ada vendor' : 'Tidak ada data',
              message: s.vendors.isEmpty
                  ? 'Simpan daftar vendor (gedung, katering, MUA, dll) beserta '
                      'kontak dan nilai kontraknya.'
                  : 'Tidak ada vendor dengan status ini.',
            ),
          for (final v in list) VendorTile(vendor: v),
        ],
      ),
    );
  }
}
