import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Pembungkus flutter_local_notifications untuk pengingat terjadwal.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'wedding_reminders',
      'Pengingat Pernikahan',
      channelDescription:
          'Pengingat nabung, jatuh tempo pembayaran vendor, dan checklist',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: Color(0xFFB5677A),
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(_detectLocation());
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e, st) {
      debugPrint('Gagal inisialisasi notifikasi: $e\n$st');
    }
  }

  /// Cari zona waktu IANA yang cocok dengan offset perangkat
  /// (prioritas WIB / WITA / WIT).
  tz.Location _detectLocation() {
    final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    const preferred = ['Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura'];
    for (final name in preferred) {
      final loc = tz.getLocation(name);
      if (loc.currentTimeZone.offset == offsetMs) return loc;
    }
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == offsetMs) return loc;
    }
    return tz.UTC;
  }

  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Gagal membatalkan notifikasi: $e');
    }
  }

  /// Jadwalkan notifikasi sekali pada waktu lokal [when].
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready) return;
    final scheduled = tz.TZDateTime(
        tz.local, when.year, when.month, when.day, when.hour, when.minute);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi $id: $e');
    }
  }

  /// Notifikasi berulang setiap bulan pada tanggal [day] jam [hour]:[minute].
  Future<void> scheduleMonthly({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
  }) async {
    if (!_ready) return;
    final int safeDay = day.clamp(1, 28).toInt();
    final now = tz.TZDateTime.now(tz.local);
    var next =
        tz.TZDateTime(tz.local, now.year, now.month, safeDay, hour, minute);
    if (!next.isAfter(now)) {
      final year = now.month == 12 ? now.year + 1 : now.year;
      final month = now.month == 12 ? 1 : now.month + 1;
      next = tz.TZDateTime(tz.local, year, month, safeDay, hour, minute);
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        next,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan pengingat bulanan: $e');
    }
  }
}
