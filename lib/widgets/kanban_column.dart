import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Enums/status_enum.dart';
import '../Models/todo.dart';
import 'todo_display_card/todo_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final RxList<Todo> todos;
  final Function(String) onAccept;
  final Status status;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.todos,
    required this.onAccept,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ExpansionTile(
        shape: const Border(),
        title: Text(
          "$title (${todos.length})",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          DragTarget<String>(
            onWillAcceptWithDetails: (DragTargetDetails<String> details) {
              return status != Status.overdue;
            },
            onAcceptWithDetails: (DragTargetDetails<String> details) {
              onAccept(details.data);
            },
            builder: (context, candidateData, rejectedData) {
              return todos.isEmpty
                  ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No tasks here yet!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return TodoCard(todo: todo);
                    },
                  );
              // );
            },
          ),
        ],
      ),
    );
  }
}
