// In a new file, e.g., utils/string_utils.dart

import 'package:intl/intl.dart';

String truncateWithEllipsis(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}...';
}

// Global helper functions
String formatReminderDate(DateTime? date) {
  if (date == null) return 'None';
  return DateFormat('MMM d, hh:mm a').format(date);
}

String formatDate(DateTime? date) {
  if (date == null) return 'None';
  return DateFormat('MMM d, hh:mm a').format(date);
}
