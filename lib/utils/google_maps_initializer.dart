/// Conditional export for Google Maps initialization
/// Uses web implementation on web, stub on other platforms
library;

export 'google_maps_initializer_stub.dart'
    if (dart.library.html) 'google_maps_initializer_web.dart';
