import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Utilities/helpers.dart';
import 'package:task_trells/widgets/bottomshets/addsubtask_bottomsheet.dart';
import 'package:task_trells/widgets/todo_display_card/todoDisplay_card.dart';
import 'package:task_trells/widgets/todo_display_card/todoItemConfig.dart';
import 'Models/todo.dart';
import 'Controllers/todo_controller.dart';

class TodoDetailsView extends GetView<TodoController> {
  final Todo todo;

  const TodoDetailsView({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            final liveTodo = controller.getLiveTodo(todo.id) ?? todo;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (liveTodo.scheduledAt != null)
                  TodoInfoRow(
                    icon: Icons.calendar_today,
                    text: 'Scheduled: ${formatDate(liveTodo.scheduledAt)}',
                    color: liveTodo.isOverdue ? Colors.red.shade700 : null,
                  ),
                if (liveTodo.reminderAt != null)
                  TodoInfoRow(
                    icon: Icons.alarm,
                    text:
                        'Reminder: ${formatReminderDate(liveTodo.reminderAt)}',
                    color: liveTodo.isOverdue ? Colors.red.shade700 : null,
                  ),

                const SizedBox(height: 16),
                Text(
                  liveTodo.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (liveTodo.description != null)
                  Text(
                    liveTodo.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: 16),
                _buildSubtaskList(liveTodo),
              ],
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.scheduleAt.value = null; // Reset scheduled date
          Get.bottomSheet(
            AddSubtaskBottomSheet(parentTodo: todo),
            isScrollControlled: true,
            ignoreSafeArea: false, // 👈 allow keyboard to push sheet
            enableDrag: true, // optional
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubtaskList(Todo liveTodo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sub-tasks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final children = controller.getLiveTodo(liveTodo.id)?.children ?? [];
          if (children.isEmpty) {
            return const Center(child: Text('No sub-tasks yet.'));
          }
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: children.length,
            onReorder: (oldIndex, newIndex) {
              controller.reorderSubtasks(liveTodo.id, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final subtask = children[index];
              // print('subtask id is: ${subtask.id}');
              // print('subtask title is: ${subtask.title}');
              return TodoDisplayCard(
                key: ValueKey(subtask.id),
                config: TodoItemConfig(
                  item: subtask,
                  isSubtask: true,
                  onCheckboxChanged: (bool? value) {
                    if (value != null) {
                      controller.updateSubtaskStatus(
                        liveTodo.id,
                        subtask.id,
                        value,
                      );
                    }
                  },
                  onEdit: () {
                    Get.bottomSheet(
                      EditSubtaskBottomSheet(
                        parentTodo: liveTodo,
                        subtask: subtask,
                      ),
                      isScrollControlled: true,
                    );
                  },
                  onDelete: () {
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Delete Sub-task'),
                        content: Text(
                          'Are you sure you want to delete "${subtask.title}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              controller.deleteSubtask(liveTodo.id, subtask.id);
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
            },
          );
        }),
      ],
    );
  }
}
