import 'package:get/get.dart';
import 'package:task_trells/Controllers/notification_controller.dart';
import 'package:task_trells/Enums/status_enum.dart';
import 'package:task_trells/Enums/todo_priority_enum.dart';
import 'package:task_trells/Models/todo.dart';
import 'package:task_trells/todo_repository.dart';
import 'package:uuid/uuid.dart';

class TodoService {
  final TodoRepository _todoRepository = Get.find<TodoRepository>();
  final NotificationController _notificationController =
      Get.find<NotificationController>();
  final _uuid = const Uuid();

  List<Todo> initializeTodos() {
    final allTasks = _todoRepository.loadAllTodos();

    // 1. Create a map for quick lookup
    final taskMap = {for (var task in allTasks) task.id: task};

    // 2. Identify the root tasks (those with no parentId)
    final rootTasks = allTasks.where((t) => t.parentId == null).toList();

    // 3. Identify and link the subtasks to their parents
    for (final subtask in allTasks.where((t) => t.parentId != null)) {
      final parent = taskMap[subtask.parentId];
      if (parent != null) {
        // Ensure parent's children list is initialized
        parent.children ??= [];

        //  Use firstWhereOrNull to prevent adding duplicates.
        if (parent.children!.firstWhereOrNull((c) => c.id == subtask.id) ==
            null) {
          parent.children!.add(subtask);
        }
      }
    }

    // 4. Sort the children within each parent
    for (final root in rootTasks) {
      _sortChildren(root);
    }

    return rootTasks;
  }

  // Overdue handling

  void checkForOverdueTasks(Function(String, Status) moveTodoCallback) {
    final allTasks = _todoRepository.loadAllTodos();
    final now = DateTime.now();

    for (var t in allTasks) {
      if (t.scheduledAt != null &&
          t.scheduledAt!.isBefore(now) &&
          t.status != Status.done &&
          t.status != Status.overdue) {
        moveTodoCallback(t.id, Status.overdue);
      }

      for (var sub in t.children ?? []) {
        if (sub.scheduledAt != null &&
            sub.scheduledAt!.isBefore(now) &&
            sub.status != Status.done &&
            sub.status != Status.overdue) {
          sub.status = Status.overdue;
          _todoRepository.saveTodo(sub);
        }
      }
    }
  }

  bool _applyReminderChange({
    required String todoId,
    required String title,
    String? body,
    required DateTime? newReminderAt,
    required DateTime? previousReminderAt,
  }) {
    if (previousReminderAt != null && previousReminderAt != newReminderAt) {
      _notificationController.cancelReminder(todoId);
    }
    if (newReminderAt != null) {
      if (newReminderAt.isBefore(DateTime.now())) {
        return false; // Time is in the past, reminder skipped
      }
      _notificationController.scheduleReminder(
        todoId: todoId,
        title: title,
        body: body,
        when: newReminderAt,
      );
    }
    return true; // Reminder was either not set or successfully scheduled
  }

  void cancelReminderOnly(Todo? item, Todo? parent) {
    if (item == null) return;
    if (item.reminderAt != null) {
      final prevReminder = item.reminderAt;
      item.reminderAt = null;
      item.lastModified = DateTime.now();
      _todoRepository.saveTodo(item);
      if (parent != null) _todoRepository.saveTodo(parent);
      _applyReminderChange(
        todoId: item.id,
        title: item.title,
        previousReminderAt: prevReminder,
        newReminderAt: null,
      );
    }
  }

  // -----------------------------
  // CRUD: Root Todos
  // -----------------------------

  Todo addTodo(
    String title,
    String? description, {
    DateTime? scheduledAt,
    DateTime? reminderAt,
    TodoPriority? priority,
  }) {
    final newTodo = Todo(
      id: _uuid.v4(),
      title: title,
      description: description,
      status:
          (scheduledAt != null && scheduledAt.isBefore(DateTime.now()))
              ? Status.overdue
              : Status.todo,
      children: [],
      creationDate: DateTime.now(),
      scheduledAt: scheduledAt,
      lastModified: DateTime.now(),
      completionDate: null,
      reminderAt: reminderAt,
      tags: [],
      priority: priority,
    );
    _todoRepository.saveTodo(newTodo);
    final reminderSet = _applyReminderChange(
      todoId: newTodo.id,
      title: newTodo.title,
      body: newTodo.description,
      previousReminderAt: null,
      newReminderAt: reminderAt,
    );
    // return newTodo;
    // Return the new todo and the reminder status
    newTodo.reminderSkipped = !reminderSet;
    return newTodo;
  }

  void updateTodo(
    Todo todo,
    String newTitle,
    String? newDescription, {
    DateTime? newScheduledAt,
    DateTime? newReminderAt,
    TodoPriority? newPriority,
  }) {
    final previousReminder = todo.reminderAt;
    todo
      ..title = newTitle
      ..description = newDescription
      ..scheduledAt = newScheduledAt
      ..reminderAt = newReminderAt
      ..priority = newPriority
      ..lastModified = DateTime.now();
    _todoRepository.saveTodo(todo);

    final reminderSet = _applyReminderChange(
      todoId: todo.id,
      title: todo.title,
      body: todo.description,
      previousReminderAt: previousReminder,
      newReminderAt: newReminderAt,
    );
    todo.reminderSkipped = !reminderSet;
  }

  void deleteTodo(Todo todo, Function deleteFromController) {
    _notificationController.cancelReminder(todo.id);
    if (todo.children != null) {
      for (final subtask in todo.children!) {
        _notificationController.cancelReminder(subtask.id);
        _todoRepository.deleteTodo(subtask.id);
      }
    }
    _todoRepository.deleteTodo(todo.id);
    deleteFromController();
  }

  // -----------------------------
  // CRUD: Subtasks
  // -----------------------------

  Todo addSubtask(
    String parentId,
    String title,
    String? description, {
    DateTime? scheduledAt,
    DateTime? reminderAt,
    TodoPriority? priority,
  }) {
    final subtask = Todo(
      id: _uuid.v4(),
      title: title,
      description: description,
      status:
          (scheduledAt != null && scheduledAt.isBefore(DateTime.now()))
              ? Status.overdue
              : Status.todo,
      creationDate: DateTime.now(),
      lastModified: DateTime.now(),
      scheduledAt: scheduledAt,
      reminderAt: reminderAt,
      children: [],
      tags: [],
      priority: priority,
      parentId: parentId,
    );

    _todoRepository.saveTodo(subtask);

    final reminderSet = _applyReminderChange(
      todoId: subtask.id,
      title: subtask.title,
      body: subtask.description,
      previousReminderAt: null,
      newReminderAt: reminderAt,
    );

    subtask.reminderSkipped = !reminderSet;
    return subtask;
  }

  void updateSubtask(
    Todo subtask,
    String newTitle,
    String? newDescription, {
    DateTime? newScheduledAt,
    DateTime? newReminderAt,
    TodoPriority? newPriority,
  }) {
    final previousReminder = subtask.reminderAt;
    subtask
      ..title = newTitle
      ..description = newDescription
      ..scheduledAt = newScheduledAt
      ..reminderAt = newReminderAt
      ..priority = newPriority
      ..lastModified = DateTime.now();

    final now = DateTime.now();
    if (subtask.scheduledAt != null &&
        subtask.scheduledAt!.isBefore(now) &&
        subtask.status != Status.done) {
      subtask.status = Status.overdue;
    } else if (subtask.status == Status.overdue &&
        subtask.scheduledAt != null &&
        subtask.scheduledAt!.isAfter(now)) {
      subtask.status = Status.todo;
    }

    _todoRepository.saveTodo(subtask);
    final reminderSet = _applyReminderChange(
      todoId: subtask.id,
      title: subtask.title,
      body: subtask.description,
      previousReminderAt: previousReminder,
      newReminderAt: newReminderAt,
    );
    subtask.reminderSkipped = !reminderSet;
  }

  void updateSubtaskStatus(Todo subtask, bool isChecked) {
    final now = DateTime.now();
    if (isChecked) {
      subtask.status = Status.done;
      subtask.completionDate = now;
    } else if (subtask.scheduledAt != null &&
        subtask.scheduledAt!.isBefore(now)) {
      subtask.status = Status.overdue;
      subtask.completionDate = null;
    } else {
      subtask.status = Status.todo;
      subtask.completionDate = null;
    }
    subtask.lastModified = now;
    _todoRepository.saveTodo(subtask);
  }

  void deleteSubtask(Todo subtask, Todo parent) {
    // Cancel notification for this subtask
    _notificationController.cancelReminder(subtask.id);

    // Delete subtask record from repo (if stored individually)
    _todoRepository.deleteTodo(subtask.id);

    // Remove from parent in-memory
    parent.children?.removeWhere((c) => c.id == subtask.id);

    // Update parent metadata
    parent.lastModified = DateTime.now();

    // Persist parent with updated children list
    _todoRepository.saveTodo(parent);
  }

  // -----------------------------
  // Moving & Reordering
  // -----------------------------

  void moveTodo(Todo todo, Status newStatus) {
    todo.previousStatus = todo.status;
    todo.status = newStatus;
    todo.lastModified = DateTime.now();
    _todoRepository.saveTodo(todo);
  }

  void reorderTodos(List<Todo> list) {
    for (var todo in list) {
      _todoRepository.saveTodo(todo);
    }
  }

  void reorderSubtasks(Todo parent) {
    _todoRepository.saveTodo(parent);
  }

  //helpers

  void _sortChildren(Todo parent) {
    parent.children!.sort((a, b) {
      if (a.status == Status.done && b.status != Status.done) return 1;
      if (a.status != Status.done && b.status == Status.done) return -1;
      return 0;
    });
  }
}
