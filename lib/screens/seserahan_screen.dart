import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class SeserahanScreen extends StatefulWidget {
  const SeserahanScreen({super.key, this.initialType});

  /// 'Mahar' atau 'Seserahan' jika dibuka dari kategori tertentu.
  final String? initialType;

  @override
  State<SeserahanScreen> createState() => _SeserahanScreenState();
}

class _SeserahanScreenState extends State<SeserahanScreen> {
  String _query = '';
  String? _typeFilter;
  bool? _boughtFilter;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialType;
  }

  Future<void> _openForm(BuildContext context, [SeserahanItem? item]) async {
    await pushPage(context, _SeserahanFormScreen(item: item));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _query.trim().toLowerCase();

    final filtered = s.seserahanItems.where((i) {
      if (_typeFilter != null && i.itemType != _typeFilter) return false;
      if (_boughtFilter != null && i.bought != _boughtFilter) return false;
      if (q.isNotEmpty) {
        final matchName = i.name.toLowerCase().contains(q);
        final matchNote = i.note.toLowerCase().contains(q);
        if (!matchName && !matchNote) return false;
      }
      return true;
    }).toList();

    final totalCount = s.seserahanItems.length;
    final boughtCount = s.seserahanBoughtCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Seserahan & Mahar'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Barang'),
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
                    Expanded(
                      child: MiniStat(
                        label: 'Total Estimasi',
                        value: rupiahShort(s.totalSeserahanEstimated),
                      ),
                    ),
                    Expanded(
                      child: MiniStat(
                        label: 'Harga Aktual',
                        value: rupiahShort(s.totalSeserahanActual),
                        color: AppColors.rose,
                      ),
                    ),
                    Expanded(
                      child: MiniStat(
                        label: 'Terbeli',
                        value: '$boughtCount/$totalCount item',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (totalCount > 0) ...[
                  const SizedBox(height: 12),
                  RoundedProgress(
                    value: boughtCount / totalCount,
                    color: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
          SearchBarField(
            hint: 'Cari barang seserahan / mahar...',
            value: _query,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _typeFilter == null && _boughtFilter == null,
                onSelected: (_) => setState(() {
                  _typeFilter = null;
                  _boughtFilter = null;
                }),
              ),
              for (final t in seserahanTypes)
                ChoiceChip(
                  label: Text(t),
                  selected: _typeFilter == t,
                  onSelected: (sel) =>
                      setState(() => _typeFilter = sel ? t : null),
                ),
              FilterChip(
                label: const Text('Belum Dibeli'),
                selected: _boughtFilter == false,
                onSelected: (sel) =>
                    setState(() => _boughtFilter = sel ? false : null),
              ),
              FilterChip(
                label: const Text('Sudah Dibeli'),
                selected: _boughtFilter == true,
                onSelected: (sel) =>
                    setState(() => _boughtFilter = sel ? true : null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.card_giftcard_outlined,
              title: 'Tidak ada barang',
              message:
                  'Catat daftar barang seserahan & mahar beserta estimasi harganya.',
            ),
          for (final item in filtered)
            _SeserahanTile(
              item: item,
              onTap: () => _openForm(context, item),
            ),
        ],
      ),
    );
  }
}

class _SeserahanTile extends StatelessWidget {
  const _SeserahanTile({required this.item, required this.onTap});

  final SeserahanItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final isMahar = item.itemType == 'Mahar';
    final badgeColor = isMahar ? AppColors.gold : AppColors.rose;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      onTap: onTap,
      child: Row(
        children: [
          Checkbox(
            value: item.bought,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (_) => s.toggleSeserahanBought(item),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.itemType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: item.bought ? AppColors.muted : AppColors.ink,
                          decoration:
                              item.bought ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.estimatedPrice > 0)
                      'Est: ${rupiah(item.estimatedPrice)}',
                    if (item.actualPrice > 0)
                      'Beli: ${rupiah(item.actualPrice)}',
                    if (item.estimatedPrice == 0 && item.actualPrice == 0)
                      'Harga belum diisi',
                    if (item.note.isNotEmpty) item.note,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}

class _SeserahanFormScreen extends StatefulWidget {
  const _SeserahanFormScreen({this.item});

  final SeserahanItem? item;

  @override
  State<_SeserahanFormScreen> createState() => _SeserahanFormScreenState();
}

class _SeserahanFormScreenState extends State<_SeserahanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _estimated;
  late final TextEditingController _actual;
  late final TextEditingController _note;
  late String _itemType;
  late bool _bought;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name ?? '');
    _estimated = TextEditingController(
        text: i == null ? '' : amountToText(i.estimatedPrice));
    _actual = TextEditingController(
        text: i == null ? '' : amountToText(i.actualPrice));
    _note = TextEditingController(text: i?.note ?? '');
    _itemType = i?.itemType ?? 'Seserahan';
    _bought = i?.bought ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _estimated.dispose();
    _actual.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AppState>().saveSeserahanItem(SeserahanItem(
          id: widget.item?.id,
          name: _name.text.trim(),
          itemType: _itemType,
          estimatedPrice: parseAmount(_estimated.text),
          actualPrice: parseAmount(_actual.text),
          bought: _bought,
          note: _note.text.trim(),
        ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.item?.id;
    if (id == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Hapus barang?',
      message: 'Barang ini akan dihapus dari daftar seserahan/mahar.',
    );
    if (!ok || !mounted) return;
    await context.read<AppState>().deleteSeserahanItem(id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Barang' : 'Tambah Barang'),
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
            const Text('Jenis',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final t in seserahanTypes)
                  ChoiceChip(
                    label: Text(t),
                    selected: _itemType == t,
                    onSelected: (_) => setState(() => _itemType = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration(
                'Nama barang',
                icon: Icons.card_giftcard_outlined,
                hint: 'Misal: Cincin nikah emas 5 gram',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            MoneyField(
              controller: _estimated,
              label: 'Estimasi harga (opsional)',
              required: false,
            ),
            const SizedBox(height: 16),
            MoneyField(
              controller: _actual,
              label: 'Harga beli aktual (opsional)',
              required: false,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration(
                'Catatan / toko / link (opsional)',
                icon: Icons.notes,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sudah dibeli'),
              value: _bought,
              onChanged: (v) => setState(() => _bought = v),
            ),
            const SizedBox(height: 24),
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
