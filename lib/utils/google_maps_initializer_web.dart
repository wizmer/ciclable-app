// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Load Google Maps JavaScript API for web platform
void loadGoogleMapsScript(String apiKey) {
  // Check if already loaded
  if (html.document.querySelector('script[src*="maps.googleapis.com"]') !=
      null) {
    return;
  }

  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
    ..type = 'text/javascript';
  html.document.head?.append(script);
}
