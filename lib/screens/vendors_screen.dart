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
  VendorStatus? _statusFilter;
  int? _categoryFilter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _query.trim().toLowerCase();

    final list = s.vendors.where((v) {
      if (_statusFilter != null && s.vendorStatus(v) != _statusFilter) {
        return false;
      }
      if (_categoryFilter != null && v.categoryId != _categoryFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final catName =
            s.categoryById(v.categoryId)?.name.toLowerCase() ?? '';
        final match = v.name.toLowerCase().contains(q) ||
            v.note.toLowerCase().contains(q) ||
            v.phone.toLowerCase().contains(q) ||
            catName.contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

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
          SearchBarField(
            hint: 'Cari nama vendor, kategori, atau catatan...',
            value: _query,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Semua (${s.vendors.length})'),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              for (final st in VendorStatus.values)
                ChoiceChip(
                  label: Text('${st.label} (${countOf(st)})'),
                  selected: _statusFilter == st,
                  onSelected: (_) => setState(() => _statusFilter = st),
                ),
            ],
          ),
          if (s.categories.isNotEmpty) ...[
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
                    if (s.vendors.any((v) => v.categoryId == c.id))
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
          const SizedBox(height: 12),
          if (list.isEmpty)
            EmptyState(
              icon: Icons.storefront_outlined,
              title: s.vendors.isEmpty ? 'Belum ada vendor' : 'Tidak ada data',
              message: s.vendors.isEmpty
                  ? 'Simpan daftar vendor (gedung, katering, MUA, dll) beserta '
                      'kontak dan nilai kontraknya.'
                  : 'Tidak ada vendor yang cocok dengan filter / pencarian.',
            ),
          for (final v in list) VendorTile(vendor: v),
        ],
      ),
    );
  }
}
