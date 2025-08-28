import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task_trells/Controllers/notification_controller.dart';
import 'package:task_trells/Enums/sort_type_enum.dart';
import 'package:task_trells/Enums/status_enum.dart';
import 'package:task_trells/Enums/todo_priority_enum.dart';
import 'package:task_trells/todo_service.dart';
import '../Models/todo.dart';
import 'package:permission_handler/permission_handler.dart';

class TodoController extends GetxController {
  final TodoService _todoService = Get.find<TodoService>();
  final NotificationController notificationController =
      Get.find<NotificationController>();

  var todos = <Todo>[].obs;
  var inProgress = <Todo>[].obs;
  var done = <Todo>[].obs;
  var overdue = <Todo>[].obs;
  var archived = <Todo>[].obs;

  var priority = Rx<TodoPriority?>(null);
  var isAscending = true.obs;

  var scheduleAt = Rx<DateTime?>(null);
  late Timer _overdueChecker;
  var reminderTime = Rxn<DateTime>();
  final sortedTodosView = <Todo>[].obs;

  // -------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    final rootTodos = _todoService.initializeTodos();
    _categorizeTodos(rootTodos);
    _overdueChecker = Timer.periodic(const Duration(minutes: 1), (time) {
      _todoService.checkForOverdueTasks(moveTodo);
      _refreshAll();
    });
  }

  @override
  void onClose() {
    _overdueChecker.cancel();
    super.onClose();
  }

  List<Todo> get allTodos => [
    ...todos,
    ...inProgress,
    ...done,
    ...overdue,
    ...archived,
  ];

  void resetAll() {
    scheduleAt.value = null;
    reminderTime.value = null;
    priority.value = null;
  }

  void _refreshAll() {
    todos.refresh();
    inProgress.refresh();
    done.refresh();
    overdue.refresh();
    archived.refresh();
  }

  List<RxList<Todo>> _allLists() => [
    todos,
    inProgress,
    done,
    overdue,
    archived,
  ];

  Todo? _removeTaskFromAll(String id) {
    Todo? task;
    for (final list in _allLists()) {
      final idx = list.indexWhere((t) => t.id == id);
      if (idx != -1) {
        task = list.removeAt(idx);
        break;
      }
    }
    return task;
  }

  (Todo?, RxList<Todo>?, int) _findRoot(String id) {
    for (final list in _allLists()) {
      final idx = list.indexWhere((t) => t.id == id);
      if (idx != -1) return (list[idx], list, idx);
    }
    return (null, null, -1);
  }

  (Todo?, RxList<Todo>?, int, Todo?) _findAnyById(String id) {
    for (final list in _allLists()) {
      final idx = list.indexWhere((t) => t.id == id);
      if (idx != -1) return (list[idx], list, idx, null);

      for (final p in list) {
        final subIdx = p.children?.indexWhere((c) => c.id == id) ?? -1;
        if (subIdx != -1) return (p.children![subIdx], list, subIdx, p);
      }
    }
    return (null, null, -1, null);
  }

  void _categorizeTodos(List<Todo> allRoot) {
    todos.clear();
    inProgress.clear();
    overdue.clear();
    done.clear();
    archived.clear();

    for (var t in allRoot) {
      switch (t.status) {
        case Status.todo:
          todos.add(t);
          break;
        case Status.inProgress:
          inProgress.add(t);
          break;
        case Status.done:
          done.add(t);
          break;
        case Status.overdue:
          overdue.add(t);
          break;
        case Status.archived:
          archived.add(t);
          break;
      }
    }
  }

  // Reminders

  void cancelReminderOnly(String id) {
    final (item, _, __, parent) = _findAnyById(id);
    _todoService.cancelReminderOnly(item, parent);
    _refreshAll();
  }

  // CRUD: Root Todos

  void addTodo(
    String title,
    String? description, {
    DateTime? scheduledAt,
    DateTime? reminderAt,
    TodoPriority? priority,
  }) async {
    if (title.isEmpty) return;
    final newTodo = _todoService.addTodo(
      title,
      description,
      scheduledAt: scheduledAt,
      reminderAt: reminderAt,
      priority: priority,
    );
    // ✅ Call the new method to handle permission and reminder
    await _setReminderIfPermissionGranted(
      todoId: newTodo.id,
      title: newTodo.title,
      body: newTodo.description,
      newReminderAt: newTodo.reminderAt,
      previousReminderAt: null,
    );

    switch (newTodo.status) {
      case Status.overdue:
        overdue.insert(0, newTodo);
        break;
      default:
        todos.insert(0, newTodo);
        break;
    }
    _refreshAll();
    // return newTodo;
  }

  void updateTodo(
    String id,
    String newTitle,
    String? newDescription, {
    DateTime? newScheduledAt,
    DateTime? newReminderAt,
    TodoPriority? newPriority,
  }) async {
    if (newTitle.isEmpty) return;
    final (todo, _, __) = _findRoot(id);
    if (todo == null) return;

    final previousReminder = todo.reminderAt;
    _todoService.updateTodo(
      todo,
      newTitle,
      newDescription,
      newScheduledAt: newScheduledAt,
      newReminderAt: newReminderAt,
      newPriority: newPriority,
    );

    // ✅ Call the new method to handle permission and reminder
    await _setReminderIfPermissionGranted(
      todoId: todo.id,
      title: todo.title,
      body: todo.description,
      newReminderAt: newReminderAt,
      previousReminderAt: previousReminder,
    );

    if (todo.status == Status.overdue &&
        newScheduledAt != null &&
        newScheduledAt.isAfter(DateTime.now())) {
      moveTodo(id, Status.todo);
    } else {
      _refreshAll();
    }

    // Check if the reminder was skipped
    if (todo.reminderSkipped) {
      Get.snackbar(
        'Reminder Skipped ⚠️',
        'The new reminder time is in the past and was not set.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void deleteTodo(String todoId) {
    final (toDelete, fromList, index) = _findRoot(todoId);

    // Root todo case
    if (toDelete != null && fromList != null && index != -1) {
      _todoService.deleteTodo(toDelete, () => fromList.removeAt(index));
      _refreshAll();
      return;
    }

    // Subtask case
    for (final parentList in _allLists()) {
      for (final p in parentList) {
        final subtask = p.children?.firstWhereOrNull((c) => c.id == todoId);
        if (subtask != null) {
          _todoService.deleteSubtask(subtask, p);
          _refreshAll();
          return;
        }
      }
    }
  }
  // -----------------------------
  // CRUD: Subtasks
  // -----------------------------

  void addSubtask(
    String parentId,
    String title,
    String? description, {
    DateTime? scheduledAt,
    DateTime? reminderAt,
    TodoPriority? priority,
  }) async {
    if (title.isEmpty) return;
    final (parent, parentList, parentIndex) = _findRoot(parentId);
    if (parent == null || parentList == null || parentIndex == -1) return;

    final subtask = _todoService.addSubtask(
      parentId,
      title,
      description,
      scheduledAt: scheduledAt,
      reminderAt: reminderAt,
      priority: priority,
    );

    // ✅ Call the new method to handle permission and reminder
    await _setReminderIfPermissionGranted(
      todoId: subtask.id,
      title: subtask.title,
      body: subtask.description,
      newReminderAt: subtask.reminderAt,
      previousReminderAt: null,
    );

    parent.children ??= <Todo>[];
    parent.children!.insert(0, subtask);
    _sortChildren(parent);
    _refreshAll();
  }

  void updateSubtask(
    String parentId,
    String subtaskId,
    String newTitle,
    String? newDescription, {
    DateTime? newScheduledAt,
    DateTime? newReminderAt,
    TodoPriority? newPriority,
  }) async {
    final (parent, _, __) = _findRoot(parentId);
    final subtask = parent?.children?.firstWhereOrNull(
      (c) => c.id == subtaskId,
    );
    if (parent == null || subtask == null) return;

    final previousReminder = subtask.reminderAt;
    _todoService.updateSubtask(
      subtask,
      newTitle,
      newDescription,
      newScheduledAt: newScheduledAt,
      newReminderAt: newReminderAt,
      newPriority: newPriority,
    );

    // ✅ Call the new method to handle permission and reminder
    await _setReminderIfPermissionGranted(
      todoId: subtask.id,
      title: subtask.title,
      body: subtask.description,
      newReminderAt: newReminderAt,
      previousReminderAt: previousReminder,
    );
    _sortChildren(parent);
    _refreshAll();
  }

  void updateSubtaskStatus(String parentId, String subtaskId, bool isChecked) {
    final (parent, _, __) = _findRoot(parentId);
    final subtask = parent?.children?.firstWhereOrNull(
      (c) => c.id == subtaskId,
    );
    if (parent == null || subtask == null) return;

    _todoService.updateSubtaskStatus(subtask, isChecked);
    _sortChildren(parent);
    _refreshAll();
  }

  void deleteSubtask(String parentId, String subtaskId) {
    final (parent, _, __) = _findRoot(parentId);
    if (parent == null) return;

    final subtask = parent.children?.firstWhereOrNull((c) => c.id == subtaskId);

    if (subtask == null) return;

    // Let service handle actual deletion + persistence
    _todoService.deleteSubtask(subtask, parent);

    // Trigger UI refresh
    _refreshAll();
  }

  // -----------------------------
  // Moving & Reordering
  // -----------------------------

  void moveTodo(String todoId, Status newStatus) {
    Todo? task = _removeTaskFromAll(todoId);
    if (task == null) return;

    _todoService.moveTodo(task, newStatus);
    switch (newStatus) {
      case Status.todo:
        todos.add(task);
        break;
      case Status.inProgress:
        inProgress.add(task);
        break;
      case Status.done:
        done.add(task);
        break;
      case Status.overdue:
        overdue.add(task);
        break;
      case Status.archived:
        archived.add(task);
        break;
    }
    _refreshAll();
  }

  void reorderTodos(RxList<Todo> list, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    _todoService.reorderTodos(list);
    _refreshAll();
  }

  void reorderSubtasks(String parentId, int oldIndex, int newIndex) {
    final (parent, _, __) = _findRoot(parentId);
    if (parent == null || parent.children == null) return;
    if (newIndex > parent.children!.length) newIndex = parent.children!.length;
    if (oldIndex < newIndex) newIndex -= 1;

    final moved = parent.children!.removeAt(oldIndex);
    parent.children!.insert(newIndex, moved);
    _todoService.reorderSubtasks(parent);
    _refreshAll();
  }

  // -----------------------------
  // UI helpers
  // -----------------------------

  pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: scheduleAt.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    scheduleAt.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  showReminderOptions(BuildContext context, {DateTime? initialDate}) {
    if (initialDate == null) {
      Get.snackbar(
        "Can't set reminder",
        "Please schedule a date first to set a reminder.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final reminderOptions = <String, Duration>{
      '1 minutes before': const Duration(minutes: 1),
      '3 minutes before': const Duration(minutes: 3),
      '10 minutes before': const Duration(minutes: 10),
      '15 minutes before': const Duration(minutes: 15),
      '20 minutes before': const Duration(minutes: 20),
      '30 minutes before': const Duration(minutes: 30),
      '1 hour before': const Duration(hours: 1),
      '2 hour before': const Duration(hours: 2),
      '3 hour before': const Duration(hours: 3),
      '1 day before': const Duration(days: 1),
      'At scheduled time': const Duration(seconds: 0),
    };
    Get.dialog(
      SimpleDialog(
        title: const Text('Set Reminder'),
        children:
            reminderOptions.entries.map((option) {
                final reminderTime = initialDate.subtract(option.value);
                return SimpleDialogOption(
                  onPressed: () {
                    this.reminderTime.value = reminderTime;
                    Get.back();
                  },
                  child: Text(
                    '${option.key} (${DateFormat('MMM d, hh:mm a').format(reminderTime)})',
                  ),
                );
              }).toList()
              ..add(
                SimpleDialogOption(
                  onPressed: () {
                    reminderTime.value = null;
                    Get.back();
                  },
                  child: const Text('None'),
                ),
              ),
      ),
    );
  }

  void setReminders(DateTime? reminder) {
    reminderTime.value = reminder;
  }
  // helpers

  void _sortChildren(Todo parent) {
    parent.children!.sort((a, b) {
      if (a.status == Status.done && b.status != Status.done) return 1;
      if (a.status != Status.done && b.status == Status.done) return -1;
      return 0;
    });
  }

  Todo? getLiveTodo(String id) {
    return todos.firstWhereOrNull((t) => t.id == id) ??
        inProgress.firstWhereOrNull((t) => t.id == id) ??
        done.firstWhereOrNull((t) => t.id == id) ??
        overdue.firstWhereOrNull((t) => t.id == id);
  }

  Color? getPriorityColor(TodoPriority? priority) {
    if (priority == null) return null;
    switch (priority) {
      case TodoPriority.important:
        return Colors.red;
      case TodoPriority.high:
        return Colors.orange;
      case TodoPriority.medium:
        return Colors.green;
      case TodoPriority.low:
        return Colors.blue;
    }
  }

  void toggleSortDirection() {
    isAscending.value = !isAscending.value;
  }

  int getPrioritySortValue(TodoPriority? priority) {
    if (priority == null) {
      return 0;
    }
    switch (priority) {
      case TodoPriority.important:
        return 4;
      case TodoPriority.high:
        return 3;
      case TodoPriority.medium:
        return 2;
      case TodoPriority.low:
        return 1;
    }
  }

  List<Todo> getSortedTodos(SortType sortType, bool ascending) {
    final List<Todo> sortedList = allTodos;

    sortedList.sort((a, b) {
      int comparison = 0;

      switch (sortType) {
        case SortType.priority:
          final aValue = getPrioritySortValue(a.priority);
          final bValue = getPrioritySortValue(b.priority);
          // Corrected logic: To sort from highest priority to lowest, we compare b to a.
          comparison = bValue.compareTo(aValue);
          break;
        case SortType.dueDate:
          final aDate = a.scheduledAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
          final bDate = b.scheduledAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
          // Corrected logic: To sort from most due to least due, we compare a to b.
          comparison = aDate.compareTo(bDate);
          break;
        case SortType.title:
          comparison = a.title.compareTo(b.title);
          break;
        case SortType.creationDate:
          final aDate = a.creationDate;
          final bDate = b.creationDate;
          // Corrected logic: To sort from latest to oldest, we compare b to a.
          comparison = bDate.compareTo(aDate);
          break;
      }

      // The ascending/descending logic remains untouched, as per your request.
      return isAscending.value ? comparison : -comparison;
    });

    return sortedList;
  }

  // In lib/controllers/todo_controller.dart

  // Add this new method to your controller
  //

  Future<void> _setReminderIfPermissionGranted({
    required String todoId,
    required String title,
    String? body,
    required DateTime? newReminderAt,
    required DateTime? previousReminderAt,
  }) async {
    if (newReminderAt != null) {
      // Check the current permission status
      final status = await Permission.notification.status;
      print('permission status: $status');

      // If permission is not granted, request it.
      if (status.isDenied || status.isRestricted || status.isLimited) {
        await Future.delayed(const Duration(milliseconds: 100));
        final newStatus = await notificationController.requestPermissions();

        // If permission is still not granted after the request, show a snackbar.
        if (!newStatus) {
          Get.snackbar(
            'Permission Required',
            'Please enable notifications in your device settings to set reminders.',
            snackPosition: SnackPosition.BOTTOM,
            mainButton: TextButton(
              onPressed: () {
                notificationController.openSystemSettings();
              },
              child: const Text('Open Settings'),
            ),
          );
          return;
        }
      } else if (status.isGranted) {
        // Permission is already granted. Proceed with scheduling.
      } else {
        // Permission is permanently denied. Guide user to settings.
        Get.snackbar(
          'Permission Required',
          'Please enable notifications in your device settings to set reminders.',
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: () {
              notificationController.openSystemSettings();
            },
            child: const Text('Open Settings'),
          ),
        );
        return;
      }
    }

    // If all checks pass or no new reminder is set, proceed
    _todoService.applyReminderChange(
      todoId: todoId,
      title: title,
      body: body,
      newReminderAt: newReminderAt,
      previousReminderAt: previousReminderAt,
    );
  }
}
