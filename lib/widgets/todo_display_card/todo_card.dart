import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Enums/status_enum.dart';
import 'package:task_trells/Models/todo.dart';
import 'package:task_trells/Controllers/todo_controller.dart';
import 'package:task_trells/widgets/bottomshets/addtodo_bottomsheet.dart';
import 'package:task_trells/widgets/todo_display_card/todoDisplay_card.dart';
import 'package:task_trells/widgets/todo_display_card/todoItemConfig.dart';
import '../../todo_details_screen.dart';
import 'package:task_trells/Utilities/helpers.dart';

class TodoCard extends GetView<TodoController> {
  final Todo todo;

  const TodoCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final liveTodo = controller.getLiveTodo(todo.id);

      if (liveTodo == null) {
        return const SizedBox.shrink();
      }

      return TodoDisplayCard(
        config: TodoItemConfig(
          item: liveTodo,
          onTap: () {
            if (liveTodo.status != Status.done) {
              Get.to(() => TodoDetailsView(todo: liveTodo));
            }
          },
          onCheckboxChanged: (bool? value) {
            if (value != null) {
              final newStatus =
                  value
                      ? Status.done
                      : (liveTodo.previousStatus ?? Status.todo);
              controller.moveTodo(liveTodo.id, newStatus);
            }
          },
          onEdit: () {
            Get.bottomSheet(
              EditTodoBottomSheet(todo: liveTodo),
              isScrollControlled: true,
            );
          },
          onDelete: () {
            Get.dialog(
              AlertDialog(
                title: const Text('Delete Task'),
                content: Text(
                  'Are you sure you want to delete "${truncateWithEllipsis(liveTodo.title, 20)}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.deleteTodo(liveTodo.id);
                      Get.back();
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
