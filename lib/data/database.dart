import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Penyimpanan lokal (offline):
/// - Android / iOS / Desktop: menggunakan SQLite (`sqflite`)
/// - Web / PWA (Safari iPhone, Chrome): menggunakan `SharedPreferences` (`localStorage`)
///
/// Format struktur tabel dan Backup/Restore JSON 100% kompatibel antar platform.
class AppDatabase {
  static const _fileName = 'dana_nikah.db';
  static const _webStorageKey = 'dana_nikah_web_db_v2';
  static const _version = 2;

  static const List<String> _tables = [
    'settings',
    'contributors',
    'categories',
    'incomes',
    'vendors',
    'payments',
    'tasks',
    'seserahan_items',
  ];

  static const List<List<String>> _defaultCategories = [
    ['Gedung / Venue', 'venue'],
    ['Katering', 'catering'],
    ['Dekorasi', 'decor'],
    ['MUA & Busana', 'makeup'],
    ['Foto & Video', 'camera'],
    ['Mahar & Cincin', 'ring'],
    ['Seserahan', 'gift'],
    ['Undangan & Souvenir', 'mail'],
    ['Hiburan & Musik', 'music'],
    ['Administrasi (KUA/Capil)', 'document'],
    ['Lain-lain', 'other'],
  ];

  static const List<String> _defaultContributors = [
    'Calon Suami',
    'Calon Istri',
    'Keluarga',
  ];

  static const List<String> _defaultTasks = [
    'Tentukan tanggal & total budget pernikahan',
    'Survei dan booking gedung / venue',
    'Pilih katering & jadwalkan test food',
    'Booking MUA & busana pengantin',
    'Booking fotografer & videografer',
    'Urus berkas pernikahan ke KUA / Catatan Sipil',
    'Beli cincin & siapkan mahar',
    'Siapkan seserahan',
    'Finalisasi daftar tamu',
    'Cetak & sebar undangan',
    'Pesan souvenir',
    'Fitting baju pengantin',
    'Technical meeting dengan semua vendor',
  ];

  static const List<List<String>> _defaultSeserahan = [
    ['Cincin Nikah Sepasang', 'Mahar'],
    ['Seperangkat Alat Sholat / Kitab Suci', 'Mahar'],
    ['Uang Tunai / Logam Mulia Mahar', 'Mahar'],
    ['Set Skincare & Kosmetik', 'Seserahan'],
    ['Tas & Sepatu Pesta', 'Seserahan'],
    ['Pakaian / Kain Kebaya', 'Seserahan'],
    ['Perlengkapan Mandi & Parfum', 'Seserahan'],
    ['Buah-buahan & Kue Hantaran', 'Seserahan'],
  ];

  Database? _db;
  Map<String, List<Map<String, Object?>>>? _webTables;

  Future<Database> get database async => _db ??= await _open();

  // ---------------------------------------------------------------------------
  // Web Storage Engine (iPhone Safari PWA & Browser)
  // ---------------------------------------------------------------------------

  Future<Map<String, List<Map<String, Object?>>>> _ensureWebTables() async {
    if (_webTables != null) return _webTables!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final parsed = <String, List<Map<String, Object?>>>{};
          for (final t in _tables) {
            final list = decoded[t];
            if (list is List) {
              parsed[t] = list
                  .whereType<Map>()
                  .map((m) => Map<String, Object?>.from(m))
                  .toList();
            } else {
              parsed[t] = <Map<String, Object?>>[];
            }
          }
          _webTables = parsed;
          return _webTables!;
        }
      } catch (_) {
        // Jika korup, inisialisasi ulang di bawah
      }
    }

    final initial = <String, List<Map<String, Object?>>>{
      for (final t in _tables) t: <Map<String, Object?>>[],
    };
    _seedWeb(initial);
    _webTables = initial;
    await _persistWebTables();
    return _webTables!;
  }

  void _seedWeb(Map<String, List<Map<String, Object?>>> store) {
    for (var i = 0; i < _defaultContributors.length; i++) {
      store['contributors']!.add({
        'id': i + 1,
        'name': _defaultContributors[i],
        'color_index': i,
      });
    }
    for (var i = 0; i < _defaultCategories.length; i++) {
      store['categories']!.add({
        'id': i + 1,
        'name': _defaultCategories[i][0],
        'icon_key': _defaultCategories[i][1],
        'budget': 0,
        'sort_order': i,
      });
    }
    for (var i = 0; i < _defaultTasks.length; i++) {
      store['tasks']!.add({
        'id': i + 1,
        'title': _defaultTasks[i],
        'done': 0,
        'due_date': null,
        'category_id': null,
        'note': '',
      });
    }
    for (var i = 0; i < _defaultSeserahan.length; i++) {
      store['seserahan_items']!.add({
        'id': i + 1,
        'name': _defaultSeserahan[i][0],
        'item_type': _defaultSeserahan[i][1],
        'estimated_price': 0,
        'actual_price': 0,
        'bought': 0,
        'note': '',
      });
    }
  }

  Future<void> _persistWebTables() async {
    if (_webTables == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webStorageKey, jsonEncode(_webTables));
  }

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // SQLite Engine (Android / iOS Native)
  // ---------------------------------------------------------------------------

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _fileName),
      version: _version,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSeserahanTable(db);
          await _seedSeserahan(db);
        }
      },
    );
  }

  Future<void> _createSeserahanTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS seserahan_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        item_type TEXT NOT NULL DEFAULT 'Seserahan',
        estimated_price INTEGER NOT NULL DEFAULT 0,
        actual_price INTEGER NOT NULL DEFAULT 0,
        bought INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT ''
      )''');
  }

  Future<void> _seedSeserahan(DatabaseExecutor db) async {
    final existing = await db.query('seserahan_items', limit: 1);
    if (existing.isNotEmpty) return;
    for (final item in _defaultSeserahan) {
      await db.insert('seserahan_items', {
        'name': item[0],
        'item_type': item[1],
        'estimated_price': 0,
        'actual_price': 0,
        'bought': 0,
        'note': '',
      });
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.execute('''
      CREATE TABLE contributors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_index INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        budget INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contributor_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        contract_price INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        note TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        vendor_id INTEGER,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        type TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        category_id INTEGER,
        note TEXT NOT NULL DEFAULT ''
      )''');
    await _createSeserahanTable(db);
  }

  Future<void> _seed(DatabaseExecutor db) async {
    for (var i = 0; i < _defaultContributors.length; i++) {
      await db.insert('contributors', {
        'name': _defaultContributors[i],
        'color_index': i,
      });
    }
    for (var i = 0; i < _defaultCategories.length; i++) {
      await db.insert('categories', {
        'name': _defaultCategories[i][0],
        'icon_key': _defaultCategories[i][1],
        'budget': 0,
        'sort_order': i,
      });
    }
    for (final title in _defaultTasks) {
      await db.insert('tasks', {'title': title, 'done': 0});
    }
    await _seedSeserahan(db);
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> loadSettings() async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      final rows = store['settings'] ?? const [];
      return {
        for (final r in rows)
          if (r['key'] is String)
            r['key'] as String: (r['value']?.toString()) ?? '',
      };
    }
    final db = await database;
    final rows = await db.query('settings');
    return {
      for (final r in rows) r['key'] as String: (r['value'] as String?) ?? '',
    };
  }

  Future<void> saveSettings(Map<String, String> values) async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      final settingsList = store['settings']!;
      for (final e in values.entries) {
        final idx = settingsList.indexWhere((r) => r['key'] == e.key);
        final row = <String, Object?>{'key': e.key, 'value': e.value};
        if (idx >= 0) {
          settingsList[idx] = row;
        } else {
          settingsList.add(row);
        }
      }
      await _persistWebTables();
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      for (final e in values.entries) {
        await txn.insert(
          'settings',
          {'key': e.key, 'value': e.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // CRUD generik
  // ---------------------------------------------------------------------------

  Future<List<Map<String, Object?>>> queryAll(String table,
      {String? orderBy}) async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      final rows = (store[table] ?? const [])
          .map((r) => Map<String, Object?>.from(r))
          .toList();
      if (orderBy == 'id') {
        rows.sort((a, b) => _asInt(a['id']).compareTo(_asInt(b['id'])));
      } else if (orderBy == 'sort_order, id') {
        rows.sort((a, b) {
          final cmp =
              _asInt(a['sort_order']).compareTo(_asInt(b['sort_order']));
          return cmp != 0 ? cmp : _asInt(a['id']).compareTo(_asInt(b['id']));
        });
      } else if (orderBy == 'date DESC, id DESC') {
        rows.sort((a, b) {
          final cmp = _asInt(b['date']).compareTo(_asInt(a['date']));
          return cmp != 0 ? cmp : _asInt(b['id']).compareTo(_asInt(a['id']));
        });
      } else if (orderBy == 'name COLLATE NOCASE') {
        rows.sort((a, b) => (a['name']?.toString().toLowerCase() ?? '')
            .compareTo(b['name']?.toString().toLowerCase() ?? ''));
      }
      return rows;
    }
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      final list = store.putIfAbsent(table, () => <Map<String, Object?>>[]);
      var maxId = 0;
      for (final r in list) {
        final rid = _asInt(r['id']);
        if (rid > maxId) maxId = rid;
      }
      final nextId = maxId + 1;
      final data = Map<String, Object?>.from(values)..['id'] = nextId;
      list.add(data);
      await _persistWebTables();
      return nextId;
    }
    final db = await database;
    final data = Map<String, Object?>.from(values)..remove('id');
    return db.insert(table, data);
  }

  Future<void> update(String table, Map<String, Object?> values, int id) async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      final list = store[table];
      if (list == null) return;
      final idx = list.indexWhere((r) => _asInt(r['id']) == id);
      if (idx >= 0) {
        list[idx] = Map<String, Object?>.from(values)..['id'] = id;
        await _persistWebTables();
      }
      return;
    }
    final db = await database;
    final data = Map<String, Object?>.from(values)..remove('id');
    await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String table, int id) async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      final list = store[table];
      if (list == null) return;
      list.removeWhere((r) => _asInt(r['id']) == id);
      await _persistWebTables();
      return;
    }
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTaskCategory(int categoryId) async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      for (final row in store['tasks'] ?? const <Map<String, Object?>>[]) {
        if (_asInt(row['category_id']) == categoryId) {
          row['category_id'] = null;
        }
      }
      await _persistWebTables();
      return;
    }
    final db = await database;
    await db.execute(
        'UPDATE tasks SET category_id = NULL WHERE category_id = ?',
        [categoryId]);
  }

  Future<void> clearPaymentVendor(int vendorId) async {
    if (kIsWeb) {
      final store = await _ensureWebTables();
      for (final row in store['payments'] ?? const <Map<String, Object?>>[]) {
        if (_asInt(row['vendor_id']) == vendorId) {
          row['vendor_id'] = null;
        }
      }
      await _persistWebTables();
      return;
    }
    final db = await database;
    await db.execute(
        'UPDATE payments SET vendor_id = NULL WHERE vendor_id = ?', [vendorId]);
  }

  // ---------------------------------------------------------------------------
  // Backup & Restore
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> exportAllData() async {
    final data = <String, Object?>{
      'app': 'dana_nikah',
      'version': _version,
      'exported_at': DateTime.now().toIso8601String(),
    };
    if (kIsWeb) {
      final store = await _ensureWebTables();
      for (final t in _tables) {
        data[t] = (store[t] ?? const [])
            .map((r) => Map<String, Object?>.from(r))
            .toList();
      }
      return data;
    }
    final db = await database;
    for (final t in _tables) {
      data[t] = await db.query(t);
    }
    return data;
  }

  Future<void> importAllData(Map<String, Object?> payload) async {
    if (payload['app'] != 'dana_nikah') {
      throw const FormatException('Bukan file backup Dana Nikah yang valid.');
    }
    if (kIsWeb) {
      final next = <String, List<Map<String, Object?>>>{};
      for (final t in _tables) {
        final rows = payload[t];
        if (rows is List) {
          next[t] = rows
              .whereType<Map>()
              .map((m) => Map<String, Object?>.from(m))
              .toList();
        } else {
          next[t] = <Map<String, Object?>>[];
        }
      }
      _webTables = next;
      await _persistWebTables();
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
        final rows = payload[t];
        if (rows is List) {
          for (final item in rows) {
            if (item is Map) {
              await txn.insert(
                t,
                Map<String, Object?>.from(item),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }
    });
  }

  /// Hapus semua data lalu isi ulang data bawaan.
  Future<void> resetAll() async {
    if (kIsWeb) {
      final fresh = <String, List<Map<String, Object?>>>{
        for (final t in _tables) t: <Map<String, Object?>>[],
      };
      _seedWeb(fresh);
      _webTables = fresh;
      await _persistWebTables();
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
      }
      await _seed(txn);
    });
  }
}
