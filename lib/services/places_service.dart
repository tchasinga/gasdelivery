import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String apiKey = 'AIzaSyC_tn_IK4hjPvbzQSp66E2MIgmBXm1fOck';
  static const String baseUrl = 'https://maps.googleapis.com/maps/api';

  /// Roadmap preview (Static Maps API). Falls back in UI if the request fails.
  static String staticMapUrl({
    double latitude = -1.286389,
    double longitude = 36.817223,
    int zoom = 11,
    int width = 640,
    int height = 400,
  }) {
    final center = '$latitude,$longitude';
    return '$baseUrl/staticmap?center=$center&zoom=$zoom&size=${width}x$height&scale=2&maptype=roadmap&key=$apiKey';
  }

  /// Get place predictions based on input query
  static Future<List<Map<String, dynamic>>> getPlacePredictions(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$baseUrl/place/autocomplete/json?input=$encodedQuery&key=$apiKey&components=country:ke',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['predictions'] != null) {
        return List<Map<String, dynamic>>.from(data['predictions']);
      }
      return [];
    } catch (e) {
      print('Error getting place predictions: $e');
      return [];
    }
  }

  /// Geocode a free-text address to lat/lng (Kenya-biased).
  static Future<({double lat, double lng})?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final encoded = Uri.encodeComponent(address);
      final url = Uri.parse(
        '$baseUrl/geocode/json?address=$encoded&key=$apiKey&components=country:KE',
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' &&
          data['results'] is List &&
          (data['results'] as List).isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        return (lat: (loc['lat'] as num).toDouble(), lng: (loc['lng'] as num).toDouble());
      }
    } catch (e) {
      print('Geocode error: $e');
    }
    return null;
  }

  /// Driving route polyline points (Directions API). Falls back to straight line.
  static Future<List<LatLng>> getDrivingRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final fallback = [
      LatLng(originLat, originLng),
      LatLng(destLat, destLng),
    ];
    try {
      final url = Uri.parse(
        '$baseUrl/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=driving'
        '&region=ke'
        '&key=$apiKey',
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? '';
      if (status != 'OK' || (data['routes'] as List?)?.isEmpty != false) {
        // Enable "Directions API" in Google Cloud if status is REQUEST_DENIED.
        return fallback;
      }
      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final encoded = route['overview_polyline']?['points'] as String?;
      if (encoded == null || encoded.isEmpty) return fallback;

      final decoded = PolylinePoints().decodePolyline(encoded);
      if (decoded.isEmpty) return fallback;
      return decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (e) {
      return fallback;
    }
  }

  static String staticMapWithRoute({
    required double riderLat,
    required double riderLng,
    required double destLat,
    required double destLng,
    int width = 640,
    int height = 480,
  }) {
    final path = 'color:0x014F5Bff|weight:5|$riderLat,$riderLng|$destLat,$destLng';
    return '$baseUrl/staticmap?size=${width}x$height&scale=2&maptype=roadmap'
        '&markers=color:blue%7Clabel:B%7C$riderLat,$riderLng'
        '&markers=color:red%7Clabel:C%7C$destLat,$destLng'
        '&path=$path&key=$apiKey';
  }

  /// Get place details by place_id
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$baseUrl/place/details/json?place_id=$placeId&key=$apiKey&fields=formatted_address,name',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['result'] != null) {
        return Map<String, dynamic>.from(data['result']);
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }
}

