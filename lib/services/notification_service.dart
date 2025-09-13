import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialization
  static Future<void> init() async {
    if (_initialized) return;
  // Time zones already initialized & local location set in main().
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings, 
      iOS: iosSettings,
    );
    
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // Permission handling
  static Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // Request basic notification permission
      final notificationResult = await androidImplementation?.requestNotificationsPermission();
      
      // Request exact alarm permission (for Android 12+)
      final exactAlarmResult = await androidImplementation?.requestExactAlarmsPermission();
      
      return (notificationResult ?? false) && (exactAlarmResult ?? true);
    }
    return true;
  }

  // Show notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'General notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    await _plugin.show(id, title, body, details, payload: payload);
  }

  // Schedule notification (simplified)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await init();
    
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'General notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      // Fallback to showing immediate notification if scheduling fails
      // print('Scheduling failed, showing immediate notification: $e');
      await showNotification(
        id: id,
        title: title,
        body: 'Scheduled: $body',
        payload: payload,
      );
    }
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await init();
    return await _plugin.pendingNotificationRequests();
  }

  // Debug methods for step-by-step testing
  Future<String> debugTimezone() async {
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 30));
    final tzTestTime = tz.TZDateTime.from(testTime, tz.local);
    
    print('=== TIMEZONE DEBUG ===');
    print('Current DateTime: $now');
    print('Current TZDateTime: $tzNow');
    print('Test DateTime (now + 30s): $testTime');
    print('Test TZDateTime (now + 30s): $tzTestTime');
    print('Local timezone: ${tz.local}');
    print('Timezone offset: ${tzNow.timeZoneOffset}');
    
    return 'Timezone: ${tz.local.name}\nCurrent: $tzNow\nTest time: $tzTestTime';
  }

  Future<String> debugPendingNotifications() async {
    await init();
    final pending = await getPendingNotifications();
    print('=== PENDING NOTIFICATIONS ===');
    print('Count: ${pending.length}');
    
    if (pending.isEmpty) {
      return 'No pending notifications found';
    }
    
    String result = 'Pending: ${pending.length}\n';
    for (final notification in pending) {
      print('ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      result += 'ID: ${notification.id} - ${notification.title}\n';
    }
    return result;
  }

  Future<String> testImmediateScheduling() async {
    await init();
    final testTime = DateTime.now().add(const Duration(seconds: 5));
    print('=== TESTING 5-SECOND SCHEDULING ===');
    print('Scheduling for: $testTime');
    
    try {
      await scheduleNotification(
        id: 9999,
        title: 'Debug Test',
        body: 'This should appear in 5 seconds',
        scheduledTime: testTime,
      );
      print('Successfully scheduled notification for 5 seconds');
      return 'Scheduled test notification for 5 seconds from now';
    } catch (e) {
      print('Failed to schedule 5-second notification: $e');
      return 'Failed to schedule: $e';
    }
  }

  Future<String> testPermissions() async {
    await init();
    print('=== PERMISSION DEBUG ===');
    
    if (Platform.isAndroid) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      try {
        final canScheduleExact = await androidImplementation?.canScheduleExactNotifications() ?? false;
        print('Can schedule exact notifications: $canScheduleExact');
        
        // Try to request permissions again
        final notificationPermission = await androidImplementation?.requestNotificationsPermission() ?? false;
        final exactAlarmPermission = await androidImplementation?.requestExactAlarmsPermission() ?? false;
        
        print('Notification permission: $notificationPermission');
        print('Exact alarm permission: $exactAlarmPermission');
        
        return 'Notification: $notificationPermission\nExact Alarms: $exactAlarmPermission\nCan Schedule: $canScheduleExact';
      } catch (e) {
        print('Permission check failed: $e');
        return 'Permission check failed: $e';
      }
    }
    return 'Not on Android platform';
  }
}
