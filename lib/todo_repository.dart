import 'package:hive/hive.dart';
import 'package:task_trells/Models/todo.dart';

class TodoRepository {
  final _box = Hive.box('tasks');

  // Load all tasks from Hive
  List<Todo> loadAllTodos() {
    return _box.values
        .map((data) => Todo.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  // Save a single todo to Hive
  void saveTodo(Todo todo) {
    _box.put(todo.id, todo.toJson());
  }

  // Delete a todo from Hive by ID
  void deleteTodo(String id) {
    _box.delete(id);
  }
}
