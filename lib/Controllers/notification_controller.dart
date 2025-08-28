import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:workmanager/workmanager.dart'; // ⭐ Add this import

class NotificationController extends GetxController {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'todo_reminders';
  static const _channelName = 'Todo Reminders';
  static const _channelDesc = 'Task reminder notifications';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    tz.initializeTimeZones();

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    debugPrint("📌 Current Timezone set to: $currentTimeZone");

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (details) async {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        Get.snackbar(
          "Notifications Disabled",
          "Please enable notifications in Settings to receive reminders.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return status.isGranted;
    }
    return false;
  }

  Future<bool> checkPermissionStatus() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  // The method for scheduling the reminder is now much simpler.
  Future<void> scheduleReminder({
    required String todoId,
    required String title,
    String? body,
    required DateTime when,
  }) async {
    final scheduledTime = when.difference(DateTime.now());

    if (scheduledTime.isNegative) {
      debugPrint(
        "⚠ Skipping reminder for '$title' ($todoId) - time is in the past",
      );
      return;
    }

    // ✅ FIX: Provide a default value for 'body' if it is null.
    final Map<String, dynamic> data = {
      'id': todoId,
      'title': title,
      'body':
          body ?? 'No description provided', // Default value to prevent null
    };

    // ✅ FIX: Register the one-off task with the checked data.
    Workmanager().registerOneOffTask(
      "todoReminderTask_$todoId",
      "reminderTask",
      initialDelay: scheduledTime,
      inputData: data,
    );
    debugPrint("⏰ Scheduled WorkManager task for '$title' ($todoId) at $when");
  }

  // This method will be called from the WorkManager callback dispatcher.
  // We need to pass the data to it.
  static Future<void> showReminderNotification(
    Map<String, dynamic> inputData,
  ) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    final title = inputData['title'] as String;
    final body = inputData['body'] as String?;
    final id = inputData['id'].hashCode & 0x7fffffff;

    // ✅ FIX: Construct the descriptive notification title.
    final notificationTitle = 'Reminder for "$title" will soon be due.';

    await plugin.show(
      id,
      notificationTitle, // Use the new title
      body,
      details,
      payload: inputData['id'],
    );
    debugPrint("✅ Notification shown for task: $notificationTitle");
  }

  Future<void> cancelReminder(String todoId) async {
    // WorkManager provides a method to cancel by unique ID.
    Workmanager().cancelByUniqueName("todoReminderTask_$todoId");
    debugPrint("❌ Canceled WorkManager task for: $todoId");
  }

  Future<void> cancelAll() async {
    // This will cancel all scheduled WorkManager tasks.
    Workmanager().cancelAll();
  }
}
