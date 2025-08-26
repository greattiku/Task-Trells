import 'package:get/get.dart';
import 'package:task_trells/Controllers/notification_controller.dart';
import 'package:task_trells/Controllers/todo_controller.dart';
import 'package:task_trells/todo_repository.dart';
import 'package:task_trells/todo_service.dart';

class MyBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TodoController>(() => TodoController());

    Get.lazyPut<NotificationController>(() => NotificationController());

    Get.lazyPut<TodoRepository>(() => TodoRepository());

    Get.lazyPut<TodoService>(() => TodoService());
  }
}
