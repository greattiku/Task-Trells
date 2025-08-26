// In todo_display_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Utilities/helpers.dart';
import 'package:task_trells/Enums/status_enum.dart';
import 'package:task_trells/Controllers/todo_controller.dart';
import 'package:task_trells/widgets/todo_display_card/todoItemConfig.dart';

// reusable widget for displaying a Todo or Subtask.
class TodoDisplayCard extends GetView<TodoController> {
  final TodoItemConfig config;

  const TodoDisplayCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final isDone = config.item.status == Status.done;
    final isOverdue = config.item.isOverdue;
    final overdueColor = Colors.red.shade700;
    final textColor = isOverdue ? overdueColor : (isDone ? Colors.grey : null);
    final isDraggable = !isDone && !isOverdue && !config.isSubtask;
    final priorityColor = controller.getPriorityColor(config.item.priority);
    final textDecoration = isDone ? TextDecoration.lineThrough : null;

    final card = Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: config.onTap,
        leading:
            config.onCheckboxChanged != null
                ? Checkbox(
                  value: isDone,
                  onChanged: config.onCheckboxChanged,
                  activeColor:
                      isDone ? Colors.grey : (isOverdue ? overdueColor : null),
                  checkColor: isOverdue ? Colors.white : null,
                )
                : null, // Don't show checkbox if no onChanged handler is provided.
        title: SizedBox(
          child: Row(
            children: [
              if (priorityColor != null)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
              if (priorityColor != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.item.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: textDecoration,
                    //  isDone ? TextDecoration.lineThrough : TextDecoration.none,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.item.description != null &&
                config.item.description!.isNotEmpty)
              Text(
                config.item.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  decoration:
                      isDone ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            if (config.item.scheduledAt != null)
              TodoInfoRow(
                icon: Icons.calendar_today,
                text: formatDate(config.item.scheduledAt),
                color: textColor,
              ),
            if (config.item.reminderAt != null)
              TodoInfoRow(
                icon: Icons.alarm,
                text: formatReminderDate(config.item.reminderAt),
                color: textColor,
              ),
          ],
        ),
        trailing: IconTheme(
          data: IconThemeData(color: textColor),
          child: PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'edit') {
                config.onEdit();
              } else if (result == 'delete') {
                config.onDelete();
              }
            },
            itemBuilder: (BuildContext context) {
              if (isDone) {
                return const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                ];
              } else {
                return const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                  PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                ];
              }
            },
          ),
        ),
      ),
    );

    if (isDraggable) {
      return Draggable<String>(
        data: config.item.id,
        feedback: Material(
          elevation: 4.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            width: 200,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 40, 2, 74).withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              config.item.title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.5, child: card),
        child: card,
      );
    } else {
      return card;
    }
  }
}

// A small reusable widget for displaying a row with an icon and text.
class TodoInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const TodoInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
