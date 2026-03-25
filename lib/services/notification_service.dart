import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ==========================
  // 🔔 INIT
  // ==========================
  static Future<void> init() async {
    // init timezone
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  // ==========================
  // 🔔 NOTIFIKASI LANGSUNG
  // ==========================
  static Future<void> showNotification(String title, String body) async {
    await _notifications.show(
      0, // id notif
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Reminder Obat',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
