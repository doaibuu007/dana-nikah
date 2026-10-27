import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class CateringCalculatorScreen extends StatefulWidget {
  const CateringCalculatorScreen({super.key});

  @override
  State<CateringCalculatorScreen> createState() =>
      _CateringCalculatorScreenState();
}

class _CateringCalculatorScreenState extends State<CateringCalculatorScreen> {
  late final TextEditingController _invitations;
  late final TextEditingController _familyGuests;
  late final TextEditingController _buffetPrice;
  late final TextEditingController _stallPrice;
  late int _guestsPerInvite;
  late int _bufferPercent;
  late int _buffetPercent;
  late int _stallMultiplier;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _invitations = TextEditingController(text: amountToText(p.invitationCount));
    _familyGuests =
        TextEditingController(text: amountToText(p.extraFamilyGuests));
    _buffetPrice = TextEditingController(text: amountToText(p.buffetPrice));
    _stallPrice = TextEditingController(text: amountToText(p.stallPrice));
    _guestsPerInvite = p.guestsPerInvite.clamp(1, 4);
    _bufferPercent = p.guestBufferPercent.clamp(0, 30);
    _buffetPercent = p.buffetPercent.clamp(30, 100);
    _stallMultiplier = p.stallMultiplier.clamp(1, 5);
  }

  @override
  void dispose() {
    _invitations.dispose();
    _familyGuests.dispose();
    _buffetPrice.dispose();
    _stallPrice.dispose();
    super.dispose();
  }

  int get _inviteCount => parseAmount(_invitations.text);
  int get _familyCount => parseAmount(_familyGuests.text);
  int get _buffetUnitPrice => parseAmount(_buffetPrice.text);
  int get _stallUnitPrice => parseAmount(_stallPrice.text);

  int get _baseGuests => (_inviteCount * _guestsPerInvite) + _familyCount;
  int get _totalGuests =>
      (_baseGuests * (1 + _bufferPercent / 100)).ceil();

  int get _buffetPortions =>
      (_totalGuests * (_buffetPercent / 100)).ceil();
  int get _stallPercent => 100 - _buffetPercent;
  int get _stallPortions =>
      (_totalGuests * (_stallPercent / 100) * _stallMultiplier).ceil();

  int get _buffetCost => _buffetPortions * _buffetUnitPrice;
  int get _stallCost => _stallPortions * _stallUnitPrice;
  int get _totalCateringCost => _buffetCost + _stallCost;

  int get _recommendedPrintedInvites => (_inviteCount * 1.05).ceil();
  int get _recommendedSouvenirs => (_inviteCount * 1.15).ceil();

  Future<void> _saveNumbers({bool applyToCategory = false}) async {
    final s = context.read<AppState>();
    await s.saveProfile(s.profile.copyWith(
      invitationCount: _inviteCount,
      guestsPerInvite: _guestsPerInvite,
      extraFamilyGuests: _familyCount,
      guestBufferPercent: _bufferPercent,
      buffetPercent: _buffetPercent,
      buffetPrice: _buffetUnitPrice,
      stallPrice: _stallUnitPrice,
      stallMultiplier: _stallMultiplier,
    ));

    if (applyToCategory) {
      BudgetCategory? catering;
      for (final c in s.categories) {
        if (c.iconKey == 'catering' ||
            c.name.toLowerCase().contains('katering')) {
          catering = c;
          break;
        }
      }
      if (catering != null) {
        await s.saveCategory(catering.copyWith(budget: _totalCateringCost));
        if (mounted) {
          showSnack(
            context,
            'Anggaran "${catering.name}" diperbarui menjadi ${rupiah(_totalCateringCost)}',
          );
        }
        return;
      }
    }
    if (mounted) {
      showSnack(context, 'Perhitungan tamu & katering disimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Tamu & Katering'),
        actions: [
          IconButton(
            tooltip: 'Simpan perhitungan',
            icon: const Icon(Icons.save_outlined),
            onPressed: () => _saveNumbers(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            color: AppColors.roseSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, color: AppColors.rose),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Estimasi Total Biaya Katering',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_totalGuests tamu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rupiah(_totalCateringCost),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.roseDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InfoRow(
                  'Prasmanan / Buffet ($_buffetPortions porsi)',
                  rupiah(_buffetCost),
                ),
                InfoRow(
                  'Pondokan / Gubukan ($_stallPortions porsi)',
                  rupiah(_stallCost),
                ),
                const Divider(height: 18),
                InfoRow(
                  'Saran cetak undangan (+5%)',
                  '$_recommendedPrintedInvites pcs',
                ),
                InfoRow(
                  'Saran jumlah souvenir (+15%)',
                  '$_recommendedSouvenirs pcs',
                ),
              ],
            ),
          ),
          const SectionHeader('1. Jumlah Tamu'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _invitations,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  decoration: fieldDecoration(
                    'Jumlah undangan disebar',
                    icon: Icons.mail_outline,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                const Text('Asumsi hadir per 1 undangan',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final n in [1, 2, 3])
                      ChoiceChip(
                        label: Text('$n orang'),
                        selected: _guestsPerInvite == n,
                        onSelected: (_) =>
                            setState(() => _guestsPerInvite = n),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _familyGuests,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  decoration: fieldDecoration(
                    'Tambahan keluarga & panitia (orang)',
                    icon: Icons.groups_outlined,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Cadangan / Buffer tamu',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text('+$_bufferPercent%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose)),
                  ],
                ),
                Slider(
                  value: _bufferPercent.toDouble(),
                  min: 0,
                  max: 30,
                  divisions: 6,
                  label: '$_bufferPercent%',
                  onChanged: (v) =>
                      setState(() => _bufferPercent = v.round()),
                ),
                InfoRow('Tamu dasar', '$_baseGuests orang'),
                InfoRow('Total tamu (+buffer)', '$_totalGuests orang',
                    bold: true),
              ],
            ),
          ),
          const SectionHeader('2. Komposisi Porsi & Harga'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Buffet $_buffetPercent% : Gubukan $_stallPercent%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _buffetPercent.toDouble(),
                  min: 40,
                  max: 100,
                  divisions: 12,
                  onChanged: (v) =>
                      setState(() => _buffetPercent = v.round()),
                ),
                const Text(
                  'Tips WO: Umumnya 60% Buffet : 40% Gubukan (atau 70% : 30%).',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                MoneyField(
                  controller: _buffetPrice,
                  label: 'Harga Buffet per porsi',
                  required: false,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                MoneyField(
                  controller: _stallPrice,
                  label: 'Harga rata-rata Gubukan per porsi',
                  required: false,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pengali porsi Gubukan (rata-rata tamu ambil berapa jenis)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in [2, 3, 4, 5])
                      ChoiceChip(
                        label: Text('${m}x porsi'),
                        selected: _stallMultiplier == m,
                        onSelected: (_) =>
                            setState(() => _stallMultiplier = m),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: bigButtonStyle,
            onPressed: () => _saveNumbers(applyToCategory: true),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Terapkan ke Anggaran Katering'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _saveNumbers(),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Simpan Saja Tanpa Ubah Anggaran'),
          ),
        ],
      ),
    );
  }
}
