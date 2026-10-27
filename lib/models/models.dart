enum VendorStatus { unpaid, partial, paid }

extension VendorStatusLabel on VendorStatus {
  String get label => switch (this) {
        VendorStatus.unpaid => 'Belum Bayar',
        VendorStatus.partial => 'DP / Cicil',
        VendorStatus.paid => 'Lunas',
      };
}

const List<String> paymentTypes = ['DP', 'Cicilan', 'Pelunasan', 'Lainnya'];
const List<String> seserahanTypes = ['Seserahan', 'Mahar'];

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
    this.invitationCount = 250,
    this.guestsPerInvite = 2,
    this.extraFamilyGuests = 50,
    this.guestBufferPercent = 10,
    this.buffetPercent = 60,
    this.buffetPrice = 75000,
    this.stallPrice = 25000,
    this.stallMultiplier = 3,
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

  // Parameter kalkulator tamu & katering
  final int invitationCount;
  final int guestsPerInvite;
  final int extraFamilyGuests;
  final int guestBufferPercent;
  final int buffetPercent;
  final int buffetPrice;
  final int stallPrice;
  final int stallMultiplier;

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
    int? invitationCount,
    int? guestsPerInvite,
    int? extraFamilyGuests,
    int? guestBufferPercent,
    int? buffetPercent,
    int? buffetPrice,
    int? stallPrice,
    int? stallMultiplier,
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
      invitationCount: invitationCount ?? this.invitationCount,
      guestsPerInvite: guestsPerInvite ?? this.guestsPerInvite,
      extraFamilyGuests: extraFamilyGuests ?? this.extraFamilyGuests,
      guestBufferPercent: guestBufferPercent ?? this.guestBufferPercent,
      buffetPercent: buffetPercent ?? this.buffetPercent,
      buffetPrice: buffetPrice ?? this.buffetPrice,
      stallPrice: stallPrice ?? this.stallPrice,
      stallMultiplier: stallMultiplier ?? this.stallMultiplier,
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
        'invitation_count': invitationCount.toString(),
        'guests_per_invite': guestsPerInvite.toString(),
        'extra_family_guests': extraFamilyGuests.toString(),
        'guest_buffer_percent': guestBufferPercent.toString(),
        'buffet_percent': buffetPercent.toString(),
        'buffet_price': buffetPrice.toString(),
        'stall_price': stallPrice.toString(),
        'stall_multiplier': stallMultiplier.toString(),
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
      invitationCount: readInt('invitation_count', 250),
      guestsPerInvite: readInt('guests_per_invite', 2),
      extraFamilyGuests: readInt('extra_family_guests', 50),
      guestBufferPercent: readInt('guest_buffer_percent', 10),
      buffetPercent: readInt('buffet_percent', 60),
      buffetPrice: readInt('buffet_price', 75000),
      stallPrice: readInt('stall_price', 25000),
      stallMultiplier: readInt('stall_multiplier', 3),
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

  BudgetCategory copyWith({
    String? name,
    String? iconKey,
    int? budget,
    int? sortOrder,
  }) =>
      BudgetCategory(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        budget: budget ?? this.budget,
        sortOrder: sortOrder ?? this.sortOrder,
      );

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

/// Item rincian barang Seserahan & Mahar.
class SeserahanItem {
  const SeserahanItem({
    this.id,
    required this.name,
    this.itemType = 'Seserahan',
    this.estimatedPrice = 0,
    this.actualPrice = 0,
    this.bought = false,
    this.note = '',
  });

  final int? id;
  final String name;

  /// 'Seserahan' atau 'Mahar'
  final String itemType;
  final int estimatedPrice;
  final int actualPrice;
  final bool bought;
  final String note;

  SeserahanItem copyWith({
    String? name,
    String? itemType,
    int? estimatedPrice,
    int? actualPrice,
    bool? bought,
    String? note,
  }) =>
      SeserahanItem(
        id: id,
        name: name ?? this.name,
        itemType: itemType ?? this.itemType,
        estimatedPrice: estimatedPrice ?? this.estimatedPrice,
        actualPrice: actualPrice ?? this.actualPrice,
        bought: bought ?? this.bought,
        note: note ?? this.note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'item_type': itemType,
        'estimated_price': estimatedPrice,
        'actual_price': actualPrice,
        'bought': bought ? 1 : 0,
        'note': note,
      };

  factory SeserahanItem.fromMap(Map<String, Object?> m) => SeserahanItem(
        id: m['id'] as int,
        name: m['name'] as String,
        itemType: (m['item_type'] as String?) ?? 'Seserahan',
        estimatedPrice: (m['estimated_price'] as int?) ?? 0,
        actualPrice: (m['actual_price'] as int?) ?? 0,
        bought: (m['bought'] as int?) == 1,
        note: (m['note'] as String?) ?? '',
      );
}
