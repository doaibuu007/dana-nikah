import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'format.dart';

/// Membuat ringkasan laporan keuangan rapi untuk dikirim ke WhatsApp.
String buildWhatsappSummary(AppState s) {
  final b = StringBuffer();
  final p = s.profile;
  b.writeln('💍 *LAPORAN DANA PERNIKAHAN*');
  b.writeln('*${p.coupleName}*');
  if (p.weddingDate != null) {
    final days = s.daysToWedding;
    final countdown = (days != null && days > 0) ? ' (H-$days)' : '';
    b.writeln('📅 Hari H: ${formatDateLong(p.weddingDate!)}$countdown');
  }
  b.writeln('────────────────────');

  b.writeln('💰 *RINGKASAN DANA*');
  if (p.targetAmount > 0) {
    b.writeln('• Target Dana: ${rupiah(p.targetAmount)}');
  }
  b.writeln(
      '• Terkumpul: ${rupiah(s.totalIncome)}${p.targetAmount > 0 ? ' (${percent(s.savingProgress)})' : ''}');
  if (p.targetAmount > 0 && s.remainingTarget > 0) {
    b.writeln('• Kurang Tabungan: ${rupiah(s.remainingTarget)}');
  }
  b.writeln('• Total Pengeluaran: ${rupiah(s.totalSpent)}');
  b.writeln('• Saldo Kas Saat Ini: *${rupiah(s.balance)}*');

  if (s.contributors.isNotEmpty && s.totalIncome > 0) {
    b.writeln('\n👥 *KONTRIBUSI TABUNGAN*');
    for (final c in s.contributors) {
      final amt = s.incomeOf(c.id!);
      final pct = s.totalIncome > 0 ? percent(amt / s.totalIncome) : '0%';
      b.writeln('• ${c.name}: ${rupiah(amt)} ($pct)');
    }
  }

  if (s.vendors.isNotEmpty) {
    b.writeln('\n🏪 *TAGIHAN VENDOR*');
    b.writeln('• Total Kontrak: ${rupiah(s.totalContract)}');
    b.writeln('• Sudah Dibayar: ${rupiah(s.totalPaidToVendors)}');
    b.writeln('• Sisa Tagihan: *${rupiah(s.totalOutstanding)}*');
    final unpaid =
        s.vendors.where((v) => s.vendorStatus(v) != VendorStatus.paid).toList();
    for (final v in unpaid) {
      final rem = s.vendorRemaining(v);
      final due = v.dueDate != null ? ' (JT: ${formatDate(v.dueDate!)})' : '';
      b.writeln('  - ${v.name}: kurang ${rupiah(rem)}$due');
    }
  }

  if (s.seserahanItems.isNotEmpty) {
    b.writeln(
        '\n🎁 *SESERAHAN & MAHAR*: ${s.seserahanBoughtCount}/${s.seserahanItems.length} terbeli');
  }

  if (s.tasks.isNotEmpty) {
    b.writeln('✅ *CHECKLIST*: ${s.tasksDone}/${s.tasks.length} selesai');
  }

  b.writeln('\n_Dicatat via aplikasi Dana Nikah_');
  return b.toString();
}

String _csvEscape(String v) {
  final cleaned = v.replaceAll('"', '""');
  if (cleaned.contains(',') ||
      cleaned.contains('"') ||
      cleaned.contains('\n')) {
    return '"$cleaned"';
  }
  return cleaned;
}

/// Membuat teks CSV (bisa dibuka di Excel / Google Sheets).
String buildCsvExport(AppState s) {
  final b = StringBuffer();

  b.writeln('=== SETORAN TABUNGAN ===');
  b.writeln('Tanggal,Penyetor,Nominal,Catatan');
  for (final i in s.incomes) {
    final name = s.contributorById(i.contributorId)?.name ?? '-';
    b.writeln(
        '${formatDate(i.date)},${_csvEscape(name)},${i.amount},${_csvEscape(i.note)}');
  }

  b.writeln('\n=== PENGELUARAN & PEMBAYARAN ===');
  b.writeln('Tanggal,Kategori,Vendor,Jenis,Nominal,Catatan');
  for (final p in s.payments) {
    final cat = s.categoryById(p.categoryId)?.name ?? '-';
    final ven = s.vendorById(p.vendorId)?.name ?? '-';
    b.writeln(
        '${formatDate(p.date)},${_csvEscape(cat)},${_csvEscape(ven)},${_csvEscape(p.type)},${p.amount},${_csvEscape(p.note)}');
  }

  b.writeln('\n=== ANGGARAN PER KATEGORI ===');
  b.writeln('Kategori,Anggaran,Terpakai,Selisih');
  for (final c in s.categories) {
    final spent = s.spentInCategory(c.id!);
    b.writeln(
        '${_csvEscape(c.name)},${c.budget},$spent,${c.budget - spent}');
  }

  b.writeln('\n=== DAFTAR VENDOR ===');
  b.writeln('Nama Vendor,Kategori,Telepon,Nilai Kontrak,Sudah Dibayar,Sisa Tagihan,Status,Jatuh Tempo');
  for (final v in s.vendors) {
    final cat = s.categoryById(v.categoryId)?.name ?? '-';
    final paid = s.paidToVendor(v.id!);
    final rem = s.vendorRemaining(v);
    final st = s.vendorStatus(v).label;
    final due = v.dueDate == null ? '-' : formatDate(v.dueDate!);
    b.writeln(
        '${_csvEscape(v.name)},${_csvEscape(cat)},${_csvEscape(v.phone)},${v.contractPrice},$paid,$rem,$st,$due');
  }

  b.writeln('\n=== SESERAHAN & MAHAR ===');
  b.writeln('Nama Barang,Jenis,Estimasi Harga,Harga Aktual,Status,Catatan');
  for (final item in s.seserahanItems) {
    b.writeln(
        '${_csvEscape(item.name)},${item.itemType},${item.estimatedPrice},${item.actualPrice},${item.bought ? 'Sudah Dibeli' : 'Belum'},${_csvEscape(item.note)}');
  }

  return b.toString();
}

Future<void> copyToClipboard(
    BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    showSnack(context, message);
  }
}

Future<void> shareViaWhatsapp(BuildContext context, String text) async {
  final encoded = Uri.encodeComponent(text);
  final uri = Uri.parse('https://wa.me/?text=$encoded');
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      await copyToClipboard(
        context,
        text,
        'WhatsApp tidak ditemukan. Teks berhasil disalin ke clipboard.',
      );
    }
  } catch (_) {
    if (context.mounted) {
      await copyToClipboard(
        context,
        text,
        'Teks berhasil disalin ke clipboard.',
      );
    }
  }
}
