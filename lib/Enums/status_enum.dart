enum Status { todo, inProgress, done, overdue, archived }

// Convert enum to string
String statusToString(Status status) => status.toString().split('.').last;

// Convert string to enum
Status statusFromString(String status) =>
    Status.values.firstWhere((e) => e.toString().split('.').last == status);
