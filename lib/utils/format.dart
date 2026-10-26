import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _rupiahFormat =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final NumberFormat _plainFormat = NumberFormat.decimalPattern('id_ID');

/// Rp 1.500.000
String rupiah(num value) => _rupiahFormat.format(value);

/// Rp 1,5 jt — untuk tampilan ringkas.
String rupiahShort(num value) {
  final v = value.abs().toDouble();
  final sign = value < 0 ? '-' : '';
  String fmt(double x) {
    final rounded = (x * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) return rounded.toStringAsFixed(0);
    return rounded.toStringAsFixed(1).replaceAll('.', ',');
  }

  if (v >= 1e9) return '${sign}Rp ${fmt(v / 1e9)} M';
  if (v >= 1e6) return '${sign}Rp ${fmt(v / 1e6)} jt';
  if (v >= 1e3) return '${sign}Rp ${fmt(v / 1e3)} rb';
  return '${sign}Rp ${v.toStringAsFixed(0)}';
}

String percent(double ratio) => '${(ratio * 100).toStringAsFixed(0)}%';

String formatDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

String formatDateLong(DateTime d) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);

String formatMonthYear(DateTime d) =>
    DateFormat('MMMM yyyy', 'id_ID').format(d);

String formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Selisih hari kalender (to - from).
int daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
    .difference(DateTime.utc(from.year, from.month, from.day))
    .inDays;

/// Label jatuh tempo relatif terhadap hari ini.
String dueLabel(DateTime date) {
  final diff = daysBetween(DateTime.now(), date);
  if (diff < 0) return 'Telat ${-diff} hari';
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Besok';
  if (diff <= 30) return '$diff hari lagi';
  return formatDate(date);
}

String initialOf(String name) {
  final t = name.trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}

/// Nomor WhatsApp format internasional (08xx -> 628xx).
String waNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
  return digits;
}

int parseAmount(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

String amountToText(int value) => value <= 0 ? '' : _plainFormat.format(value);

/// Memformat input angka menjadi 1.500.000 saat diketik.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > 15) return oldValue;
    final text = _plainFormat.format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
