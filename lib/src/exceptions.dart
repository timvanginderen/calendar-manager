class CalendarManagerException implements Exception {
  final String message;

  CalendarManagerException(this.message);

  @override
  String toString() {
    return "$CalendarManagerException: $message";
  }
}
