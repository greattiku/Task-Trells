import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Enums/sort_type_enum.dart';
import 'package:task_trells/Controllers/todo_controller.dart';
import 'package:task_trells/widgets/sortedtask_view.dart';

class SortDropdown extends StatelessWidget {
  const SortDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final TodoController controller = Get.find<TodoController>();
    return PopupMenuButton<SortType>(
      icon: const Icon(Icons.sort),
      onSelected: (SortType sortType) {
        Get.to(() => SortedTaskView(sortType: sortType));
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: SortType.priority,
            child: Text('By Priority'),
          ),
          const PopupMenuItem(
            value: SortType.dueDate,
            child: Text('By Due Date'),
          ),
          PopupMenuItem(
            value: SortType.title,

            child: Row(
              children: [
                const Text('By Title'),
                Tooltip(
                  message:
                      controller.isAscending.value ? 'Ascending' : 'Descending',
                  child: Obx(
                    () => IconButton(
                      icon: Icon(
                        controller.isAscending.value
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                      onPressed: () {
                        controller.toggleSortDirection();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: SortType.creationDate,
            child: Text('By Creation Date'),
          ),
        ];
      },
    );
  }
}
