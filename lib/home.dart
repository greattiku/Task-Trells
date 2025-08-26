import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Enums/status_enum.dart';
import 'package:task_trells/widgets/sort_dropdown.dart';
import 'Controllers/todo_controller.dart';
import 'widgets/kanban_column.dart';
import 'widgets/bottomshets/addtodo_bottomsheet.dart';

class HomeView extends GetView<TodoController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Kanban Todo App'),
        centerTitle: true,

        actions: [SortDropdown()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              KanbanColumn(
                title: 'To Do',
                todos: controller.todos,
                onAccept:
                    (String todoId) => controller.moveTodo(todoId, Status.todo),
                status: Status.todo,
              ),
              KanbanColumn(
                title: 'In Progress',
                todos: controller.inProgress,
                onAccept:
                    (String todoId) =>
                        controller.moveTodo(todoId, Status.inProgress),
                status: Status.inProgress,
              ),
              KanbanColumn(
                title: 'Overdue',
                todos: controller.overdue,
                onAccept:
                    (String todoId) =>
                        controller.moveTodo(todoId, Status.overdue),
                status: Status.overdue,
              ),
              KanbanColumn(
                title: 'Done',
                todos: controller.done,
                onAccept:
                    (String todoId) => controller.moveTodo(todoId, Status.done),
                status: Status.done,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.scheduleAt.value = null;

          Get.bottomSheet(
            const AddTodoBottomSheet(),
            isScrollControlled: true,
            ignoreSafeArea: false,
            enableDrag: true,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
