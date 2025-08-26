import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

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

    // ✅ Detect the user’s current timezone
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    debugPrint("📌 Current Timezone set to: $currentTimeZone");

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) async {
        // Handle taps if needed: resp.payload contains the todoId
      },
    );

    await requestPermissions();
  }

  /// Ask for notification permission; show UX hint if denied.
  Future<void> requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        Get.snackbar(
          "Notifications Disabled",
          "Please enable notifications in Settings to receive reminders.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<bool> checkPermissionStatus() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  int _idFor(String todoId) => todoId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String todoId,
    required String title,
    String? body,
    required DateTime when,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint(
        "⚠ Skipping reminder for '$title' ($todoId) - time is in the past",
      );
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _idFor(todoId),
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: todoId,
    );
  }

  Future<void> cancelReminder(String todoId) async {
    await _plugin.cancel(_idFor(todoId));
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}










// class NotificationController extends GetxController {
//   final _plugin = FlutterLocalNotificationsPlugin();

//   static const _channelId = 'todo_reminders';
//   static const _channelName = 'Todo Reminders';
//   static const _channelDesc = 'Task reminder notifications';

//   @override
//   void onInit() {
//     super.onInit();
//     _init();
//   }

//   Future<void> _init() async {
//     tz.initializeTimeZones();

//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     final darwinInit = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     final settings = InitializationSettings(
//       android: androidInit,
//       iOS: darwinInit,
//       macOS: darwinInit,
//     );

//     await _plugin.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (resp) async {
//         // Handle taps if needed: resp.payload contains the todoId
//       },
//     );

//     await requestPermissions();
//   }

//   /// Ask for notification permission; show UX hint if denied.
//   Future<void> requestPermissions() async {
//     if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
//       final status = await Permission.notification.request();
//       if (!status.isGranted) {
//         Get.snackbar(
//           "Notifications Disabled",
//           "Please enable notifications in Settings to receive reminders.",
//           snackPosition: SnackPosition.BOTTOM,
//         );
//       }
//     }
//   }

//   Future<bool> checkPermissionStatus() async {
//     final status = await Permission.notification.status;
//     return status.isGranted;
//   }

//   Future<void> openSystemSettings() async {
//     await openAppSettings();
//   }

//   int _idFor(String todoId) => todoId.hashCode & 0x7fffffff;

//   Future<void> scheduleReminder({
//     required String todoId,
//     required String title,
//     String? body,
//     required DateTime when,
//   }) async {
//     final scheduled = tz.TZDateTime.from(when, tz.local);
//     if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
//       debugPrint(
//         "⚠ Skipping reminder for '$title' ($todoId) - time is in the past",
//       );
//       return;
//     }

//     const androidDetails = AndroidNotificationDetails(
//       _channelId,
//       _channelName,
//       channelDescription: _channelDesc,
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const details = NotificationDetails(android: androidDetails);

//     await _plugin.zonedSchedule(
//       _idFor(todoId),
//       title,
//       body,
//       scheduled,
//       details,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       payload: todoId,
//     );
//   }

//   Future<void> cancelReminder(String todoId) async {
//     await _plugin.cancel(_idFor(todoId));
//   }

//   Future<void> cancelAll() => _plugin.cancelAll();
// }












// class NotificationController extends GetxController {
//   final _plugin = FlutterLocalNotificationsPlugin();

//   static const _channelId = 'todo_reminders';
//   static const _channelName = 'Todo Reminders';
//   static const _channelDesc = 'Task reminder notifications';

//   @override
//   void onInit() {
//     super.onInit();
//     _init();
//   }

//   Future<void> _init() async {
//     tz.initializeTimeZones();

//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     final darwinInit = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     final settings = InitializationSettings(
//       android: androidInit,
//       iOS: darwinInit,
//       macOS: darwinInit,
//     );

//     await _plugin.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (resp) async {
//         // Handle taps: resp.payload contains todoId
//       },
//     );

//     // 🔑 Ask for notification permissions
//     await requestPermissions();
//   }

//   /// 🔔 Request permissions cross-platform
//   Future<void> requestPermissions() async {
//     if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
//       final status = await Permission.notification.request();
//       if (!status.isGranted) {
//         // If denied, open settings
//         openSystemSettings();
//       }
//     }
//   }

//   /// ✅ Check if notifications are allowed
//   Future<bool> checkPermissionStatus() async {
//     final status = await Permission.notification.status;
//     return status.isGranted;
//   }

//   /// ⚙ Open app settings if user has disabled notifications
//   Future<void> openSystemSettings() async {
//     await openAppSettings();
//   }

//   int _idFor(String todoId) => todoId.hashCode & 0x7fffffff;

//   Future<void> scheduleReminder({
//     required String todoId,
//     required String title,
//     String? body,
//     required DateTime when,
//   }) async {
//     final scheduled = tz.TZDateTime.from(when, tz.local);
//     if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

//     const androidDetails = AndroidNotificationDetails(
//       _channelId,
//       _channelName,
//       channelDescription: _channelDesc,
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const details = NotificationDetails(android: androidDetails);

//     await _plugin.zonedSchedule(
//       _idFor(todoId),
//       title,
//       body,
//       scheduled,
//       details,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       payload: todoId,
//     );
//   }

//   Future<void> cancelReminder(String todoId) async {
//     await _plugin.cancel(_idFor(todoId));
//   }

//   Future<void> cancelAll() => _plugin.cancelAll();
// }
