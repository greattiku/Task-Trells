import 'package:flutter/material.dart';
import 'package:task_trells/Models/todo.dart';

class TodoItemConfig {
  final Todo item;
  final bool isSubtask;
  final VoidCallback? onTap;
  final Function(bool?)? onCheckboxChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoItemConfig({
    required this.item,
    this.isSubtask = false,
    this.onTap,
    this.onCheckboxChanged,
    required this.onEdit,
    required this.onDelete,
  });
}
