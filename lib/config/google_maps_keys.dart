/// Google Maps / Places API keys used by Gas express.
///
/// Keep these separate so each key can have its own Google Cloud restrictions.
class GoogleMapsKeys {
  /// Places, Geocoding, Directions, autocomplete (HTTP APIs).
  static const String places = 'AIzaSyC_tn_IK4hjPvbzQSp66E2MIgmBXm1fOck';

  /// Maps SDK only (map tiles / GoogleMap widget).
  /// Wired in AndroidManifest (`com.google.android.geo.API_KEY`) and iOS
  /// `GMSServices.provideAPIKey(...)`.
  static const String mapView = 'AIzaSyAsnzLvfYFjOEZ-3Oh_pZ99-z7ubb4LLQk';
}
