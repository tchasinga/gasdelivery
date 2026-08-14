import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Interactive map tab — free pan / zoom / rotate.
class MapTabScreen extends StatefulWidget {
  const MapTabScreen({super.key});

  @override
  State<MapTabScreen> createState() => _MapTabScreenState();
}

class _MapTabScreenState extends State<MapTabScreen> {
  static const Color _brand = Color(0xFF014F5B);
  static const LatLng _nairobi = LatLng(-1.286389, 36.817223);

  GoogleMapController? _controller;
  LatLng _center = _nairobi;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = target;
        _loadingLocation = false;
      });
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 14),
      );
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _recenter() async {
    await _loadUserLocation();
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(_center, 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        elevation: 0,
        title: const Text(
          'Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'My location',
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _recenter,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 13),
            onMapCreated: (c) => _controller = c,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
          ),
          if (_loadingLocation)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _brand,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Finding your location…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Material(
              color: Colors.white.withValues(alpha: 0.95),
              elevation: 3,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Drag to move · pinch to zoom · use +/− or rotate with two fingers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
