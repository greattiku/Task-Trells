enum TodoPriority { important, high, medium, low }

String priorityToString(TodoPriority priority) =>
    priority.toString().split('.').last;

TodoPriority priorityFromString(String priority) => TodoPriority.values
    .firstWhere((e) => e.toString().split('.').last == priority);
