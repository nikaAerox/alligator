class NotificationAction {
  const NotificationAction({
    required this.scheduleId,
    required this.action,
  });

  final String scheduleId;
  final String action;
}

typedef NotificationActionHandler = void Function(NotificationAction action);
