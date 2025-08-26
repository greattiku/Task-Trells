import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Enums/sort_type_enum.dart';
import 'package:task_trells/Models/todo.dart';
import 'package:task_trells/Controllers/todo_controller.dart';
import 'package:task_trells/todo_details_screen.dart';
import 'package:task_trells/widgets/todo_display_card/todoDisplay_card.dart';
import 'package:task_trells/widgets/todo_display_card/todoItemConfig.dart';

class SortedTaskView extends StatelessWidget {
  final SortType sortType;

  const SortedTaskView({super.key, required this.sortType});

  @override
  Widget build(BuildContext context) {
    final TodoController controller = Get.find<TodoController>();
    final List<Todo> sortedList = controller.getSortedTodos(sortType, false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sorted by ${sortType.toString().split('.').last.capitalizeFirst}',
        ),
      ),
      body: ListView.builder(
        itemCount: sortedList.length,
        itemBuilder: (context, index) {
          final todo = sortedList[index];
          return TodoDisplayCard(
            config: TodoItemConfig(
              item: todo,
              isSubtask: false,
              onTap: () {
                Get.to(() => TodoDetailsView(todo: todo));
              },
              onEdit: () {},
              onDelete: () {},
            ),
          );
        },
      ),
    );
  }
}
