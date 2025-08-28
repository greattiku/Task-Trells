import 'package:flutter/material.dart';

class TodoFormConfig {
  final String title;
  final String? initialTitle;
  final String? initialDescription;
  final String saveButtonText;
  final bool showReminderCancelButton;
  final bool shouldPopTwiceOnSave;
  final Function(String, String?) onSave;

  const TodoFormConfig({
    required this.title,
    this.initialTitle,
    this.initialDescription,
    this.saveButtonText = 'Save',
    this.showReminderCancelButton = false,
    this.shouldPopTwiceOnSave = false,
    required this.onSave,
  });
}
