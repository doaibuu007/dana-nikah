import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Dipakai untuk onboarding pertama kali sekaligus edit profil.
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _partner1;
  late final TextEditingController _partner2;
  late final TextEditingController _target;
  DateTime? _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _partner1 = TextEditingController(text: p.partner1);
    _partner2 = TextEditingController(text: p.partner2);
    _target = TextEditingController(text: amountToText(p.targetAmount));
    _date = p.weddingDate;
  }

  @override
  void dispose() {
    _partner1.dispose();
    _partner2.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final updated = state.profile.copyWith(
      partner1: _partner1.text.trim(),
      partner2: _partner2.text.trim(),
      weddingDate: _date,
      clearWeddingDate: _date == null,
      targetAmount: parseAmount(_target.text),
      setupDone: true,
    );
    await state.saveProfile(updated, renameContributors: widget.isOnboarding);
    if (!mounted) return;
    if (!widget.isOnboarding) {
      Navigator.pop(context);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final onboarding = widget.isOnboarding;
    return Scaffold(
      appBar: onboarding ? null : AppBar(title: const Text('Profil Pernikahan')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (onboarding) ...[
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      gradient: heroGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Selamat datang 💍',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yuk mulai rencanakan dana pernikahan kalian. '
                  'Semua data tersimpan aman di HP ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
              ],
              TextFormField(
                controller: _partner1,
                textCapitalization: TextCapitalization.words,
                decoration: fieldDecoration('Nama calon pengantin pria',
                    icon: Icons.person_outline),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partner2,
                textCapitalization: TextCapitalization.words,
                decoration: fieldDecoration('Nama calon pengantin wanita',
                    icon: Icons.person_outline),
                validator: _required,
              ),
              const SizedBox(height: 16),
              DateField(
                label: 'Tanggal pernikahan (opsional)',
                value: _date,
                allowClear: true,
                icon: Icons.favorite_border,
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: 16),
              MoneyField(
                controller: _target,
                label: 'Target total dana',
                required: false,
                helperText: 'Perkiraan total biaya yang ingin dikumpulkan',
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: bigButtonStyle,
                onPressed: _saving ? null : _save,
                child: Text(onboarding ? 'Mulai Rencanakan' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
