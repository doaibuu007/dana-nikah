import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Penyimpanan lokal (offline) berbasis SQLite.
///
/// Semua akses data lewat kelas ini, sehingga nanti mudah ditambahkan
/// sinkronisasi online (misalnya Firebase) tanpa mengubah UI.
class AppDatabase {
  static const _fileName = 'dana_nikah.db';
  static const _version = 1;

  static const List<String> _tables = [
    'settings',
    'contributors',
    'categories',
    'incomes',
    'vendors',
    'payments',
    'tasks',
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

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _fileName),
      version: _version,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
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
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> loadSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {
      for (final r in rows) r['key'] as String: (r['value'] as String?) ?? '',
    };
  }

  Future<void> saveSettings(Map<String, String> values) async {
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
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    final data = Map<String, Object?>.from(values)..remove('id');
    return db.insert(table, data);
  }

  Future<void> update(String table, Map<String, Object?> values, int id) async {
    final db = await database;
    final data = Map<String, Object?>.from(values)..remove('id');
    await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String table, int id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> execute(String sql, [List<Object?>? args]) async {
    final db = await database;
    await db.execute(sql, args);
  }

  /// Hapus semua data lalu isi ulang data bawaan.
  Future<void> resetAll() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
      }
      await _seed(txn);
    });
  }
}
