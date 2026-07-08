// Exports the correct storage factory based on the platform.
// Web uses local storage, while other platforms use SQLite storage.

export 'app_storage_factory_io.dart'
    if (dart.library.html) 'app_storage_factory_web.dart';
