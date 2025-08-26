import 'package:task_trells/Utilities/helpers.dart';
import 'package:task_trells/widgets/bottomshets/todoformConfig_model.dart';
import 'package:task_trells/widgets/bottomshets/todoform_bottomsheet.dart';

import '../../Models/todo.dart';
import '../../Controllers/todo_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSubtaskBottomSheet extends StatelessWidget {
  final Todo parentTodo;

  const AddSubtaskBottomSheet({super.key, required this.parentTodo});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TodoController>();
    controller.resetAll();
    final shortenedTitle = truncateWithEllipsis(parentTodo.title, 20);

    return TodoFormBottomSheet(
      config: TodoFormConfig(
        title: 'New Sub-task for $shortenedTitle',
        saveButtonText: 'Save Sub-task',
        onSave: (title, description) {
          controller.addSubtask(
            parentTodo.id,
            title,
            description!.isNotEmpty ? description : null,
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

class EditSubtaskBottomSheet extends StatelessWidget {
  final Todo parentTodo;
  final Todo subtask;

  const EditSubtaskBottomSheet({
    super.key,
    required this.parentTodo,
    required this.subtask,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TodoController>();
    controller.scheduleAt.value = subtask.scheduledAt;
    controller.reminderTime.value = subtask.reminderAt;
    controller.priority.value = subtask.priority;

    return TodoFormBottomSheet(
      config: TodoFormConfig(
        title: 'Edit Sub-task',
        initialTitle: subtask.title,
        initialDescription: subtask.description,
        showReminderCancelButton: true,
        onSave: (title, description) {
          controller.updateSubtask(
            parentTodo.id,
            subtask.id,
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
