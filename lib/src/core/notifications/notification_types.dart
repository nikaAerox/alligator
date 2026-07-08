// Defines the notification action data used to pass reminder responses from the notification system back to the app state.

class NotificationAction {
  const NotificationAction({
    required this.scheduleId,
    required this.action,
  });

  final String scheduleId;
  final String action;
}

typedef NotificationActionHandler = void Function(NotificationAction action);
