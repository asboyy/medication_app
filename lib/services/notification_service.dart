import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/medication.dart';

class NotificationService {
  NotificationService._();

  static const String _channelId = 'medication_reminder_channel_custom_sound';
  static const RawResourceAndroidNotificationSound _notificationSound =
      RawResourceAndroidNotificationSound('reminder_sound');

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    'Medication Reminder',
    description: 'Reminder jadwal minum obat pasien',
    importance: Importance.high,
    playSound: true,
    sound: _notificationSound,
  );

  static Future<void> init() async {
    if (kIsWeb) {
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(_resolveLocalLocation());

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification payload: ${response.payload}');
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _details(),
    );
  }

  static Future<void> scheduleMedicationNotifications(Medication medication) async {
    if (kIsWeb) {
      return;
    }

    await cancelMedicationNotifications(medication.id);

    final start = _dateOnly(medication.startDate);
    final end = _dateOnly(medication.endDate);

    for (
      DateTime day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      for (var index = 0; index < medication.times.length; index++) {
        final time = medication.times[index];
        final scheduledDate = _combine(day, time);
        if (scheduledDate.isBefore(DateTime.now())) {
          continue;
        }

        final notificationId = buildNotificationId(
          medicationId: medication.id,
          date: day,
          timeIndex: index,
        );

        await _plugin.zonedSchedule(
          notificationId,
          'Waktunya minum obat',
          '${medication.name} dijadwalkan pada $time',
          tz.TZDateTime.from(scheduledDate, tz.local),
          _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'medication:${medication.id}|time:$time|date:${_storageDate(day)}',
        );
      }
    }
  }

  static Future<void> cancelMedicationNotifications(int medicationId) async {
    if (kIsWeb) {
      return;
    }

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload ?? '';
      if (payload.startsWith('medication:$medicationId|')) {
        await _plugin.cancel(request.id);
      }
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) {
      return;
    }

    await _plugin.cancelAll();
  }

  static int buildNotificationId({
    required int medicationId,
    required DateTime date,
    required int timeIndex,
  }) {
    final compactDate = date.year * 10000 + date.month * 100 + date.day;
    return medicationId.hashCode ^ compactDate ^ (timeIndex * 100003);
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Medication Reminder',
        channelDescription: 'Reminder jadwal minum obat pasien',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: _notificationSound,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
      ),
    );
  }

  static tz.Location _resolveLocalLocation() {
    final timeZoneName = DateTime.now().timeZoneName;
    try {
      return tz.getLocation(timeZoneName);
    } catch (_) {
      final offset = DateTime.now().timeZoneOffset;
      if (offset.inMinutes % 60 == 0 && offset.inHours != 0) {
        final sign = offset.isNegative ? '+' : '-';
        final locationName = 'Etc/GMT$sign${offset.inHours.abs()}';
        try {
          return tz.getLocation(locationName);
        } catch (_) {}
      }
      return tz.getLocation('UTC');
    }
  }

  static DateTime _combine(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _storageDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
