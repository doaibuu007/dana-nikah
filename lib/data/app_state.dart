import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/notification_service.dart';
import '../utils/format.dart';
import 'database.dart';

/// Bobot persentase rekomendasi alokasi anggaran per icon_key kategori.
const Map<String, int> defaultCategoryWeights = {
  'catering': 35,
  'venue': 15,
  'decor': 10,
  'makeup': 10,
  'camera': 7,
  'ring': 5,
  'gift': 5,
  'mail': 5,
  'music': 3,
  'other': 3,
  'document': 2,
};

/// State utama aplikasi: memuat data dari database, menyediakan
/// perhitungan ringkasan, dan menjadwalkan ulang pengingat.
class AppState extends ChangeNotifier {
  AppState(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  WeddingProfile profile = WeddingProfile.empty;
  List<Contributor> contributors = [];
  List<BudgetCategory> categories = [];
  List<Income> incomes = [];
  List<Vendor> vendors = [];
  List<Payment> payments = [];
  List<TaskItem> tasks = [];
  List<SeserahanItem> seserahanItems = [];

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    profile = WeddingProfile.fromSettings(await _db.loadSettings());
    await _reloadAll();
    notifyListeners();
    await _syncReminders();
  }

  Future<void> _reloadAll() async {
    contributors = (await _db.queryAll('contributors', orderBy: 'id'))
        .map(Contributor.fromMap)
        .toList();
    categories = (await _db.queryAll('categories', orderBy: 'sort_order, id'))
        .map(BudgetCategory.fromMap)
        .toList();
    incomes = (await _db.queryAll('incomes', orderBy: 'date DESC, id DESC'))
        .map(Income.fromMap)
        .toList();
    vendors = (await _db.queryAll('vendors', orderBy: 'name COLLATE NOCASE'))
        .map(Vendor.fromMap)
        .toList();
    payments = (await _db.queryAll('payments', orderBy: 'date DESC, id DESC'))
        .map(Payment.fromMap)
        .toList();
    tasks = (await _db.queryAll('tasks', orderBy: 'id'))
        .map(TaskItem.fromMap)
        .toList();
    seserahanItems = (await _db.queryAll('seserahan_items', orderBy: 'id'))
        .map(SeserahanItem.fromMap)
        .toList();
  }

  Future<void> _afterChange() async {
    await _reloadAll();
    notifyListeners();
    await _syncReminders();
  }

  Future<void> requestNotificationPermission() =>
      _notifications.requestPermission();

  // ---------------------------------------------------------------------------
  // Lookup
  // ---------------------------------------------------------------------------

  Contributor? contributorById(int id) {
    for (final c in contributors) {
      if (c.id == id) return c;
    }
    return null;
  }

  BudgetCategory? categoryById(int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Vendor? vendorById(int? id) {
    if (id == null) return null;
    for (final v in vendors) {
      if (v.id == id) return v;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Ringkasan
  // ---------------------------------------------------------------------------

  int get totalIncome => incomes.fold<int>(0, (sum, i) => sum + i.amount);
  int get totalSpent => payments.fold<int>(0, (sum, p) => sum + p.amount);
  int get balance => totalIncome - totalSpent;
  int get totalBudget => categories.fold<int>(0, (sum, c) => sum + c.budget);

  /// Sisa target dana yang belum dialokasikan ke anggaran kategori.
  int get unallocatedTarget => profile.targetAmount - totalBudget;

  int get remainingTarget => math.max(0, profile.targetAmount - totalIncome);

  double get savingProgress => profile.targetAmount <= 0
      ? 0
      : (totalIncome / profile.targetAmount).clamp(0.0, 1.0).toDouble();

  int incomeOf(int contributorId) => incomes
      .where((i) => i.contributorId == contributorId)
      .fold<int>(0, (sum, i) => sum + i.amount);

  int spentInCategory(int categoryId) => payments
      .where((p) => p.categoryId == categoryId)
      .fold<int>(0, (sum, p) => sum + p.amount);

  int paidToVendor(int vendorId) => payments
      .where((p) => p.vendorId == vendorId)
      .fold<int>(0, (sum, p) => sum + p.amount);

  int vendorRemaining(Vendor v) =>
      math.max(0, v.contractPrice - paidToVendor(v.id!));

  VendorStatus vendorStatus(Vendor v) {
    final paid = paidToVendor(v.id!);
    if (paid <= 0) return VendorStatus.unpaid;
    if (v.contractPrice <= 0 || paid >= v.contractPrice) {
      return VendorStatus.paid;
    }
    return VendorStatus.partial;
  }

  int get totalContract => vendors.fold<int>(0, (s, v) => s + v.contractPrice);
  int get totalPaidToVendors =>
      vendors.fold<int>(0, (s, v) => s + paidToVendor(v.id!));
  int get totalOutstanding =>
      vendors.fold<int>(0, (s, v) => s + vendorRemaining(v));

  int get tasksDone => tasks.where((t) => t.done).length;

  int get totalSeserahanEstimated =>
      seserahanItems.fold<int>(0, (s, i) => s + i.estimatedPrice);
  int get totalSeserahanActual =>
      seserahanItems.fold<int>(0, (s, i) => s + i.actualPrice);
  int get seserahanBoughtCount =>
      seserahanItems.where((i) => i.bought).length;

  /// Sisa hari menuju hari H (negatif jika sudah lewat).
  int? get daysToWedding {
    final d = profile.weddingDate;
    if (d == null) return null;
    return daysBetween(DateTime.now(), d);
  }

  int? get monthsToWedding {
    final days = daysToWedding;
    if (days == null || days <= 0) return null;
    return math.max(1, (days / 30.44).ceil());
  }

  /// Saran nominal nabung per bulan agar target tercapai sebelum hari H.
  int? get monthlySavingSuggestion {
    final months = monthsToWedding;
    if (months == null || remainingTarget <= 0) return null;
    return (remainingTarget / months).ceil();
  }

  /// Menghitung rekomendasi anggaran tiap kategori dari [totalAmount].
  Map<int, int> calculateRecommendedBudgets(int totalAmount) {
    if (categories.isEmpty || totalAmount <= 0) return {};
    final weights = <int, int>{};
    var weightSum = 0;
    for (final c in categories) {
      final w = defaultCategoryWeights[c.iconKey] ?? 4;
      weights[c.id!] = w;
      weightSum += w;
    }
    if (weightSum <= 0) return {};
    final result = <int, int>{};
    var allocated = 0;
    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      if (i == categories.length - 1) {
        result[c.id!] = math.max(0, totalAmount - allocated);
      } else {
        final raw = (totalAmount * (weights[c.id!] ?? 4)) / weightSum;
        // Bulatkan ke kelipatan Rp 50.000 terdekat agar rapi
        final rounded = totalAmount >= 1000000
            ? ((raw / 50000).round() * 50000)
            : raw.round();
        result[c.id!] = rounded;
        allocated += rounded;
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Profil & Backup
  // ---------------------------------------------------------------------------

  Future<void> saveProfile(WeddingProfile p,
      {bool renameContributors = false}) async {
    await _db.saveSettings(p.toSettings());
    profile = p;
    if (renameContributors) {
      final names = [p.partner1.trim(), p.partner2.trim()];
      for (var i = 0; i < names.length && i < contributors.length; i++) {
        if (names[i].isEmpty) continue;
        final c = contributors[i];
        await _db.update(
            'contributors', c.copyWith(name: names[i]).toMap(), c.id!);
      }
    }
    await _afterChange();
  }

  Future<String> exportBackupJson() async {
    final map = await _db.exportAllData();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<void> importBackupJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Format data backup tidak dikenali.');
    }
    await _db.importAllData(Map<String, Object?>.from(decoded));
    profile = WeddingProfile.fromSettings(await _db.loadSettings());
    await _afterChange();
  }

  Future<void> resetAll() async {
    await _db.resetAll();
    profile = WeddingProfile.empty;
    await _afterChange();
  }

  // ---------------------------------------------------------------------------
  // Penyetor
  // ---------------------------------------------------------------------------

  Future<void> saveContributor(Contributor c) async {
    if (c.id == null) {
      await _db.insert('contributors', c.toMap());
    } else {
      await _db.update('contributors', c.toMap(), c.id!);
    }
    await _afterChange();
  }

  /// Mengembalikan pesan error jika tidak bisa dihapus.
  Future<String?> deleteContributor(int id) async {
    if (incomes.any((i) => i.contributorId == id)) {
      return 'Penyetor ini masih punya riwayat setoran. Hapus setorannya dulu.';
    }
    await _db.delete('contributors', id);
    await _afterChange();
    return null;
  }

  // ---------------------------------------------------------------------------
  // Kategori anggaran
  // ---------------------------------------------------------------------------

  Future<void> saveCategory(BudgetCategory c) async {
    if (c.id == null) {
      await _db.insert('categories', c.toMap());
    } else {
      await _db.update('categories', c.toMap(), c.id!);
    }
    await _afterChange();
  }

  /// Simpan anggaran banyak kategori sekaligus (misal dari fitur bagi otomatis).
  Future<void> saveCategoryBudgets(Map<int, int> budgets) async {
    for (final c in categories) {
      final newBudget = budgets[c.id];
      if (newBudget != null && c.id != null) {
        await _db.update(
          'categories',
          c.copyWith(budget: newBudget).toMap(),
          c.id!,
        );
      }
    }
    await _afterChange();
  }

  Future<String?> deleteCategory(int id) async {
    final used = payments.any((p) => p.categoryId == id) ||
        vendors.any((v) => v.categoryId == id);
    if (used) {
      return 'Kategori masih dipakai oleh pengeluaran atau vendor. '
          'Pindahkan atau hapus datanya dulu.';
    }
    await _db.delete('categories', id);
    await _db.clearTaskCategory(id);
    await _afterChange();
    return null;
  }

  // ---------------------------------------------------------------------------
  // Setoran
  // ---------------------------------------------------------------------------

  Future<void> saveIncome(Income i) async {
    if (i.id == null) {
      await _db.insert('incomes', i.toMap());
    } else {
      await _db.update('incomes', i.toMap(), i.id!);
    }
    await _afterChange();
  }

  Future<void> deleteIncome(int id) async {
    await _db.delete('incomes', id);
    await _afterChange();
  }

  // ---------------------------------------------------------------------------
  // Vendor
  // ---------------------------------------------------------------------------

  Future<void> saveVendor(Vendor v) async {
    if (v.id == null) {
      await _db.insert('vendors', v.toMap());
    } else {
      await _db.update('vendors', v.toMap(), v.id!);
    }
    await _afterChange();
  }

  /// Riwayat pembayaran tetap disimpan (vendor_id dikosongkan).
  Future<void> deleteVendor(int id) async {
    await _db.delete('vendors', id);
    await _db.clearPaymentVendor(id);
    await _afterChange();
  }

  // ---------------------------------------------------------------------------
  // Pengeluaran
  // ---------------------------------------------------------------------------

  Future<void> savePayment(Payment p) async {
    if (p.id == null) {
      await _db.insert('payments', p.toMap());
    } else {
      await _db.update('payments', p.toMap(), p.id!);
    }
    await _afterChange();
  }

  Future<void> deletePayment(int id) async {
    await _db.delete('payments', id);
    await _afterChange();
  }

  // ---------------------------------------------------------------------------
  // Checklist
  // ---------------------------------------------------------------------------

  Future<void> saveTask(TaskItem t) async {
    if (t.id == null) {
      await _db.insert('tasks', t.toMap());
    } else {
      await _db.update('tasks', t.toMap(), t.id!);
    }
    await _afterChange();
  }

  Future<void> toggleTask(TaskItem t) async {
    await _db.update('tasks', t.copyWith(done: !t.done).toMap(), t.id!);
    await _afterChange();
  }

  Future<void> deleteTask(int id) async {
    await _db.delete('tasks', id);
    await _afterChange();
  }

  // ---------------------------------------------------------------------------
  // Seserahan & Mahar
  // ---------------------------------------------------------------------------

  Future<void> saveSeserahanItem(SeserahanItem item) async {
    if (item.id == null) {
      await _db.insert('seserahan_items', item.toMap());
    } else {
      await _db.update('seserahan_items', item.toMap(), item.id!);
    }
    await _afterChange();
  }

  Future<void> toggleSeserahanBought(SeserahanItem item) async {
    final nextBought = !item.bought;
    final nextActual = (nextBought && item.actualPrice <= 0)
        ? item.estimatedPrice
        : item.actualPrice;
    await _db.update(
      'seserahan_items',
      item.copyWith(bought: nextBought, actualPrice: nextActual).toMap(),
      item.id!,
    );
    await _afterChange();
  }

  Future<void> deleteSeserahanItem(int id) async {
    await _db.delete('seserahan_items', id);
    await _afterChange();
  }

  // ---------------------------------------------------------------------------
  // Pengingat
  // ---------------------------------------------------------------------------

  static const int _savingReminderId = 1;
  static const int _vendorReminderBase = 100000;
  static const int _taskReminderBase = 500000;

  Future<void> _syncReminders() async {
    try {
      await _notifications.cancelAll();
      final p = profile;
      if (!p.setupDone) return;

      if (p.savingReminderEnabled) {
        final suggestion = monthlySavingSuggestion;
        await _notifications.scheduleMonthly(
          id: _savingReminderId,
          title: 'Waktunya nabung untuk hari bahagia 💍',
          body: suggestion != null
              ? 'Target nabung bulan ini sekitar ${rupiah(suggestion)}. Semangat!'
              : 'Yuk sisihkan dana untuk persiapan pernikahan.',
          day: p.savingReminderDay,
          hour: p.savingReminderHour,
          minute: p.savingReminderMinute,
        );
      }

      if (!p.dueReminderEnabled) return;

      for (final v in vendors) {
        final due = v.dueDate;
        if (due == null || v.id == null) continue;
        if (vendorStatus(v) == VendorStatus.paid) continue;
        final remaining = vendorRemaining(v);
        final body = remaining > 0
            ? 'Sisa pembayaran ${rupiah(remaining)}'
            : 'Cek kembali pembayaran vendor ini.';
        await _notifications.scheduleOnce(
          id: _vendorReminderBase + v.id! * 2,
          title: 'Besok jatuh tempo: ${v.name}',
          body: body,
          when: DateTime(due.year, due.month, due.day - 1, 9),
        );
        await _notifications.scheduleOnce(
          id: _vendorReminderBase + v.id! * 2 + 1,
          title: 'Hari ini jatuh tempo: ${v.name}',
          body: body,
          when: DateTime(due.year, due.month, due.day, 8),
        );
      }

      for (final t in tasks) {
        final due = t.dueDate;
        if (t.done || due == null || t.id == null) continue;
        await _notifications.scheduleOnce(
          id: _taskReminderBase + t.id!,
          title: 'Checklist hari ini: ${t.title}',
          body: 'Jangan lupa ya, semangat persiapannya!',
          when: DateTime(due.year, due.month, due.day, 8),
        );
      }
    } catch (e) {
      debugPrint('Gagal menyinkronkan pengingat: $e');
    }
  }
}
