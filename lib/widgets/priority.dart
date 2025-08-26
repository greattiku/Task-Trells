// In a new file, e.g., widgets/priority_dropdown.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Enums/todo_priority_enum.dart';
import 'package:task_trells/Controllers/todo_controller.dart';

class PriorityDropdown extends StatelessWidget {
  const PriorityDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final TodoController controller = Get.find<TodoController>();

    final priorityColors = {
      TodoPriority.important: Colors.red,
      TodoPriority.high: Colors.orange,
      TodoPriority.medium: Colors.green,
      TodoPriority.low: Colors.blue,
    };

    return Obx(() {
      return PopupMenuButton<TodoPriority>(
        initialValue: controller.priority.value,
        onSelected: (TodoPriority newPriority) {
          FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
          controller.priority.value = newPriority;
        },
        itemBuilder: (BuildContext context) {
          return TodoPriority.values.map((priority) {
            return PopupMenuItem<TodoPriority>(
              value: priority,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: priorityColors[priority],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(priority.toString().split('.').last.capitalizeFirst!),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            controller.priority.value != null
                ? controller.priority.value!
                    .toString()
                    .split('.')
                    .last
                    .capitalizeFirst!
                : 'Select Priority',
          ),
        ),
      );
    });
  }
}
