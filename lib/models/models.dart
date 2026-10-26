enum VendorStatus { unpaid, partial, paid }

extension VendorStatusLabel on VendorStatus {
  String get label => switch (this) {
        VendorStatus.unpaid => 'Belum Bayar',
        VendorStatus.partial => 'DP / Cicil',
        VendorStatus.paid => 'Lunas',
      };
}

const List<String> paymentTypes = ['DP', 'Cicilan', 'Pelunasan', 'Lainnya'];

int? _writeDate(DateTime? d) => d?.millisecondsSinceEpoch;
DateTime? _readDate(Object? v) =>
    v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

/// Profil pasangan + pengaturan aplikasi (disimpan di tabel settings).
class WeddingProfile {
  const WeddingProfile({
    this.partner1 = '',
    this.partner2 = '',
    this.weddingDate,
    this.targetAmount = 0,
    this.setupDone = false,
    this.savingReminderEnabled = false,
    this.savingReminderDay = 1,
    this.savingReminderHour = 19,
    this.savingReminderMinute = 0,
    this.dueReminderEnabled = true,
  });

  static const WeddingProfile empty = WeddingProfile();

  final String partner1;
  final String partner2;
  final DateTime? weddingDate;
  final int targetAmount;
  final bool setupDone;
  final bool savingReminderEnabled;
  final int savingReminderDay;
  final int savingReminderHour;
  final int savingReminderMinute;
  final bool dueReminderEnabled;

  String get coupleName {
    final a = partner1.trim();
    final b = partner2.trim();
    if (a.isEmpty && b.isEmpty) return 'Rencana Pernikahan Kita';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a & $b';
  }

  WeddingProfile copyWith({
    String? partner1,
    String? partner2,
    DateTime? weddingDate,
    bool clearWeddingDate = false,
    int? targetAmount,
    bool? setupDone,
    bool? savingReminderEnabled,
    int? savingReminderDay,
    int? savingReminderHour,
    int? savingReminderMinute,
    bool? dueReminderEnabled,
  }) {
    return WeddingProfile(
      partner1: partner1 ?? this.partner1,
      partner2: partner2 ?? this.partner2,
      weddingDate: clearWeddingDate ? null : (weddingDate ?? this.weddingDate),
      targetAmount: targetAmount ?? this.targetAmount,
      setupDone: setupDone ?? this.setupDone,
      savingReminderEnabled:
          savingReminderEnabled ?? this.savingReminderEnabled,
      savingReminderDay: savingReminderDay ?? this.savingReminderDay,
      savingReminderHour: savingReminderHour ?? this.savingReminderHour,
      savingReminderMinute: savingReminderMinute ?? this.savingReminderMinute,
      dueReminderEnabled: dueReminderEnabled ?? this.dueReminderEnabled,
    );
  }

  Map<String, String> toSettings() => {
        'partner1': partner1,
        'partner2': partner2,
        'wedding_date': weddingDate?.millisecondsSinceEpoch.toString() ?? '',
        'target_amount': targetAmount.toString(),
        'setup_done': setupDone ? '1' : '0',
        'saving_reminder_enabled': savingReminderEnabled ? '1' : '0',
        'saving_reminder_day': savingReminderDay.toString(),
        'saving_reminder_hour': savingReminderHour.toString(),
        'saving_reminder_minute': savingReminderMinute.toString(),
        'due_reminder_enabled': dueReminderEnabled ? '1' : '0',
      };

  factory WeddingProfile.fromSettings(Map<String, String> s) {
    int readInt(String key, int fallback) =>
        int.tryParse(s[key] ?? '') ?? fallback;
    bool readBool(String key, bool fallback) {
      final v = s[key];
      if (v == null || v.isEmpty) return fallback;
      return v == '1';
    }

    final dateMillis = int.tryParse(s['wedding_date'] ?? '');
    return WeddingProfile(
      partner1: s['partner1'] ?? '',
      partner2: s['partner2'] ?? '',
      weddingDate: dateMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dateMillis),
      targetAmount: readInt('target_amount', 0),
      setupDone: readBool('setup_done', false),
      savingReminderEnabled: readBool('saving_reminder_enabled', false),
      savingReminderDay: readInt('saving_reminder_day', 1),
      savingReminderHour: readInt('saving_reminder_hour', 19),
      savingReminderMinute: readInt('saving_reminder_minute', 0),
      dueReminderEnabled: readBool('due_reminder_enabled', true),
    );
  }
}

/// Orang yang menyetor dana (calon suami, calon istri, keluarga, dll).
class Contributor {
  const Contributor({this.id, required this.name, this.colorIndex = 0});

  final int? id;
  final String name;
  final int colorIndex;

  Contributor copyWith({String? name, int? colorIndex}) => Contributor(
        id: id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
      );

  Map<String, Object?> toMap() =>
      {'id': id, 'name': name, 'color_index': colorIndex};

  factory Contributor.fromMap(Map<String, Object?> m) => Contributor(
        id: m['id'] as int,
        name: m['name'] as String,
        colorIndex: (m['color_index'] as int?) ?? 0,
      );
}

/// Kategori anggaran (gedung, katering, MUA, ...).
class BudgetCategory {
  const BudgetCategory({
    this.id,
    required this.name,
    required this.iconKey,
    this.budget = 0,
    this.sortOrder = 0,
  });

  final int? id;
  final String name;
  final String iconKey;
  final int budget;
  final int sortOrder;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon_key': iconKey,
        'budget': budget,
        'sort_order': sortOrder,
      };

  factory BudgetCategory.fromMap(Map<String, Object?> m) => BudgetCategory(
        id: m['id'] as int,
        name: m['name'] as String,
        iconKey: (m['icon_key'] as String?) ?? 'other',
        budget: (m['budget'] as int?) ?? 0,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );
}

/// Setoran / pemasukan tabungan nikah.
class Income {
  const Income({
    this.id,
    required this.contributorId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final int? id;
  final int contributorId;
  final int amount;
  final DateTime date;
  final String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'contributor_id': contributorId,
        'amount': amount,
        'date': _writeDate(date),
        'note': note,
      };

  factory Income.fromMap(Map<String, Object?> m) => Income(
        id: m['id'] as int,
        contributorId: m['contributor_id'] as int,
        amount: m['amount'] as int,
        date: _readDate(m['date']) ?? DateTime.now(),
        note: (m['note'] as String?) ?? '',
      );
}

/// Vendor pernikahan.
class Vendor {
  const Vendor({
    this.id,
    required this.name,
    required this.categoryId,
    this.phone = '',
    this.contractPrice = 0,
    this.dueDate,
    this.note = '',
  });

  final int? id;
  final String name;
  final int categoryId;
  final String phone;
  final int contractPrice;

  /// Jatuh tempo pelunasan.
  final DateTime? dueDate;
  final String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'phone': phone,
        'contract_price': contractPrice,
        'due_date': _writeDate(dueDate),
        'note': note,
      };

  factory Vendor.fromMap(Map<String, Object?> m) => Vendor(
        id: m['id'] as int,
        name: m['name'] as String,
        categoryId: (m['category_id'] as int?) ?? 0,
        phone: (m['phone'] as String?) ?? '',
        contractPrice: (m['contract_price'] as int?) ?? 0,
        dueDate: _readDate(m['due_date']),
        note: (m['note'] as String?) ?? '',
      );
}

/// Pengeluaran / pembayaran (DP, cicilan, pelunasan, dll).
class Payment {
  const Payment({
    this.id,
    required this.categoryId,
    this.vendorId,
    required this.amount,
    required this.date,
    this.type = 'Lainnya',
    this.note = '',
  });

  final int? id;
  final int categoryId;
  final int? vendorId;
  final int amount;
  final DateTime date;
  final String type;
  final String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'vendor_id': vendorId,
        'amount': amount,
        'date': _writeDate(date),
        'type': type,
        'note': note,
      };

  factory Payment.fromMap(Map<String, Object?> m) => Payment(
        id: m['id'] as int,
        categoryId: m['category_id'] as int,
        vendorId: m['vendor_id'] as int?,
        amount: m['amount'] as int,
        date: _readDate(m['date']) ?? DateTime.now(),
        type: (m['type'] as String?) ?? 'Lainnya',
        note: (m['note'] as String?) ?? '',
      );
}

/// Item checklist persiapan pernikahan.
class TaskItem {
  const TaskItem({
    this.id,
    required this.title,
    this.done = false,
    this.dueDate,
    this.categoryId,
    this.note = '',
  });

  final int? id;
  final String title;
  final bool done;
  final DateTime? dueDate;
  final int? categoryId;
  final String note;

  TaskItem copyWith({bool? done}) => TaskItem(
        id: id,
        title: title,
        done: done ?? this.done,
        dueDate: dueDate,
        categoryId: categoryId,
        note: note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'done': done ? 1 : 0,
        'due_date': _writeDate(dueDate),
        'category_id': categoryId,
        'note': note,
      };

  factory TaskItem.fromMap(Map<String, Object?> m) => TaskItem(
        id: m['id'] as int,
        title: m['title'] as String,
        done: (m['done'] as int?) == 1,
        dueDate: _readDate(m['due_date']),
        categoryId: m['category_id'] as int?,
        note: (m['note'] as String?) ?? '',
      );
}
