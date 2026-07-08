// Exports the platform-specific notification service and shared notification types so the app can use one notification interface everywhere.

export 'notification_types.dart';
export 'notification_service_io.dart'
    if (dart.library.html) 'notification_service_web.dart';
