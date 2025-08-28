import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Models/todo.dart';
import 'package:task_trells/Controllers/todo_controller.dart';
import 'package:task_trells/widgets/bottomshets/todoformConfig_model.dart';
import 'package:task_trells/widgets/bottomshets/todoform_bottomsheet.dart';

class AddTodoBottomSheet extends StatelessWidget {
  const AddTodoBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TodoController>();
    controller.resetAll();

    return TodoFormBottomSheet(
      config: TodoFormConfig(
        title: 'Add New Todo',
        onSave: (title, description) async {
          controller.addTodo(
            title,
            description,
            scheduledAt: controller.scheduleAt.value,
            reminderAt: controller.reminderTime.value,
            priority: controller.priority.value,
          );
          controller.resetAll();
          Get.back();
        },
      ),
    );
  }
}

class EditTodoBottomSheet extends StatelessWidget {
  final Todo todo;

  const EditTodoBottomSheet({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TodoController>();
    controller.scheduleAt.value = todo.scheduledAt;
    controller.reminderTime.value = todo.reminderAt;
    controller.priority.value = todo.priority;

    return TodoFormBottomSheet(
      config: TodoFormConfig(
        title: 'Edit Task',
        initialTitle: todo.title,
        initialDescription: todo.description,
        showReminderCancelButton: true,
        onSave: (title, description) async {
          controller.updateTodo(
            todo.id,
            title,
            description!.isNotEmpty ? description : null,
            newScheduledAt: controller.scheduleAt.value,
            newReminderAt: controller.reminderTime.value,
            newPriority: controller.priority.value,
          );
          controller.resetAll();
          Get.back();
        },
      ),
    );
  }
}
