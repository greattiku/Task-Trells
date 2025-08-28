import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_trells/Controllers/notification_controller.dart';
import 'package:task_trells/home.dart';
import 'bindings/app_bindings.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart'; // ⭐ Add this import

// ⭐ This is the callback dispatcher that will run in the background.
// It must be a top-level function or a static method.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Inside the callbackDispatcher function
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == "reminderTask") {
      // Call the static method from the NotificationController to show the notification
      await NotificationController.showReminderNotification(inputData!);
      return Future.value(true);
    }
    return Future.value(false);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // ⭐ Initialize WorkManager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false for production
    );
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Open box for storing todos as JSON maps
  await Hive.openBox('tasks');

  // Initialize dependencies
  MyBindings().dependencies();
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Task Trello',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomeView(),
    );
  }
}

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Hive
//   await Hive.initFlutter();

//   // Open box for storing todos as JSON maps
//   await Hive.openBox('tasks');

//   // Initialize dependencies
//   MyBindings().dependencies();
//   tz.initializeTimeZones();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Task Trello',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: HomeView(),
//     );
//   }
// }
