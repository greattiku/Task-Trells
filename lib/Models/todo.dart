import 'package:task_trells/Enums/status_enum.dart';
import '../Enums/todo_priority_enum.dart';

class Todo {
  String id;
  String title;
  String? description;
  Status status;
  String? parentId;
  List<Todo>? children;
  Status? previousStatus;
  DateTime? scheduledAt;
  TodoPriority? priority;
  String? color;
  DateTime creationDate;
  DateTime? lastModified;
  DateTime? completionDate;
  DateTime? reminderAt;
  List<String>? tags;
  bool reminderSkipped = false;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.status = Status.todo,
    this.parentId,
    this.children,
    this.previousStatus,
    this.scheduledAt,
    this.priority,
    this.color,
    required this.creationDate,
    this.lastModified,
    this.completionDate,
    this.reminderAt,
    this.tags,
    this.reminderSkipped = false,
  });

  bool get isOverdue =>
      scheduledAt != null && scheduledAt!.isBefore(DateTime.now());

  // From JSON
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: statusFromString(json['status']),
      parentId: json['parentId'],
      children:
          json['children'] != null
              ? (json['children'] as List)
                  .map(
                    (child) => Todo.fromJson(Map<String, dynamic>.from(child)),
                  )
                  .toList()
              : null,
      previousStatus:
          json['previousStatus'] != null
              ? statusFromString(json['previousStatus'])
              : null,
      scheduledAt:
          json['scheduledAt'] != null
              ? DateTime.parse(json['scheduledAt'])
              : null,
      priority:
          json['priority'] != null
              ? priorityFromString(json['priority'])
              : null,
      color: json['color'],
      creationDate: DateTime.parse(json['creationDate']),
      lastModified:
          json['lastModified'] != null
              ? DateTime.parse(json['lastModified'])
              : null,
      completionDate:
          json['completionDate'] != null
              ? DateTime.parse(json['completionDate'])
              : null,
      reminderAt:
          json['reminderAt'] != null
              ? DateTime.parse(json['reminderAt'])
              : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      reminderSkipped: json['reminderSkipped'] ?? false,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': statusToString(status),
      'parentId': parentId,
      'children': children?.map((child) => child.toJson()).toList(),
      'previousStatus':
          previousStatus != null ? statusToString(previousStatus!) : null,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'priority': priority != null ? priorityToString(priority!) : null,
      'color': color,
      'creationDate': creationDate.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'tags': tags,
      'reminderSkipped': reminderSkipped,
    };
  }
}
