import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';

Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (ctx) {
          final width = MediaQuery.sizeOf(ctx).width;
          if (width < 760) return page;
          return ColoredBox(
            color: AppColors.cream,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: page,
              ),
            ),
          );
        },
      ),
    );

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

final ButtonStyle bigButtonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
);

InputDecoration fieldDecoration(
  String label, {
  IconData? icon,
  String? hint,
  String? prefixText,
  String? helperText,
  String? errorText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    helperText: helperText,
    errorText: errorText,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}

/// Kartu putih dengan sudut membulat & bayangan lembut.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14B5677A),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class RoundedProgress extends StatelessWidget {
  const RoundedProgress({
    super.key,
    required this.value,
    this.color = AppColors.rose,
    this.height = 10,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        color: color,
        backgroundColor: AppColors.roseSoft,
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox(this.icon,
      {super.key, this.color = AppColors.rose, this.size = 42});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value,
      {super.key, this.valueColor, this.bold = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistik kecil: label di atas, nilai di bawah.
class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.ink,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.blush),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Input nominal Rupiah dengan pemisah ribuan otomatis.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.required = true,
    this.helperText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsFormatter()],
      onChanged: onChanged,
      decoration: fieldDecoration(
        label,
        icon: Icons.payments_outlined,
        prefixText: 'Rp ',
        helperText: helperText,
      ),
      validator: (v) {
        if (required && parseAmount(v ?? '') <= 0) return 'Masukkan nominal';
        return null;
      },
    );
  }
}

/// Kolom pencarian dengan tombol hapus cepat.
class SearchBarField extends StatefulWidget {
  const SearchBarField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<SearchBarField> createState() => _SearchBarFieldState();
}

class _SearchBarFieldState extends State<SearchBarField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SearchBarField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                tooltip: 'Bersihkan',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  FocusScope.of(context).unfocus();
                  widget.onChanged('');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

/// Field tanggal yang membuka date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = false,
    this.icon = Icons.event,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;
  final IconData icon;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = DateTime(2015);
    final last = DateTime(now.year + 15, 12, 31);
    var initial = value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pick(context),
      child: InputDecorator(
        isEmpty: v == null,
        decoration: fieldDecoration(
          label,
          icon: icon,
          suffixIcon: allowClear && v != null
              ? IconButton(
                  tooltip: 'Kosongkan',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(v == null ? '' : formatDateLong(v)),
      ),
    );
  }
}

class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
}

class _PickResult<T> {
  const _PickResult(this.value);
  final T? value;
}

/// Pengganti dropdown: menampilkan pilihan dalam bottom sheet.
class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.noneLabel,
    this.errorText,
  });

  final String label;
  final T? value;
  final List<PickerOption<T>> options;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  /// Jika diisi, ada pilihan "kosong" dengan label ini.
  final String? noneLabel;
  final String? errorText;

  PickerOption<T>? get _selected {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<_PickResult<T>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final none = noneLabel;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (none != null)
                  ListTile(
                    leading: const Icon(Icons.block, color: AppColors.muted),
                    title: Text(none),
                    trailing: value == null
                        ? const Icon(Icons.check, color: AppColors.rose)
                        : null,
                    onTap: () => Navigator.pop(ctx, _PickResult<T>(null)),
                  ),
                for (final o in options)
                  ListTile(
                    leading: o.icon == null
                        ? null
                        : Icon(o.icon, color: o.color ?? AppColors.rose),
                    title: Text(o.label),
                    trailing: o.value == value
                        ? const Icon(Icons.check, color: AppColors.rose)
                        : null,
                    onTap: () => Navigator.pop(ctx, _PickResult<T>(o.value)),
                  ),
                if (options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Belum ada data.',
                        style: TextStyle(color: AppColors.muted)),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) onChanged(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final text = selected?.label ?? (value == null ? (noneLabel ?? '') : '');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _open(context),
      child: InputDecorator(
        isEmpty: text.isEmpty,
        decoration: fieldDecoration(
          label,
          icon: icon,
          errorText: errorText,
          suffixIcon: const Icon(Icons.expand_more),
        ),
        child: Text(text),
      ),
    );
  }
}
