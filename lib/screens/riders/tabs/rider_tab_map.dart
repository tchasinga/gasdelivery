import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../services/api_services.dart';
import '../../../services/auth_service.dart';
import '../../../services/places_service.dart';
import '../../../utils/format_api_label.dart';
import '../../../utils/map_marker_helper.dart';

class RiderTabMap extends StatefulWidget {
  const RiderTabMap({super.key, required this.isActive});

  /// When false (another bottom tab selected), GPS and the map surface are paused.
  final bool isActive;

  @override
  State<RiderTabMap> createState() => _RiderTabMapState();
}

class _RiderTabMapState extends State<RiderTabMap> {
  static const _brand = Color(0xFF014F5B);
  static final _defaultCenter = const LatLng(-1.286389, 36.817223);

  GoogleMapController? _mapController;
  int _mapSession = 0;

  List<dynamic> _orders = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;
  bool _drawerOpen = false;
  bool _showMapsSetupHint = true;
  String? _locationError;

  LatLng _riderPosition = _defaultCenter;
  LatLng? _destination;
  List<LatLng> _routePoints = [];

  BitmapDescriptor? _bikeIcon;
  BitmapDescriptor? _destinationIcon;

  StreamSubscription<Position>? _positionSub;
  Timer? _syncTimer;

  DateTime? _lastMarkerUiUpdate;
  LatLng? _lastReportedPosition;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _loadOrders();
    if (widget.isActive) {
      _resumeTracking();
    }
  }

  @override
  void didUpdateWidget(RiderTabMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _resumeTracking();
    } else if (!widget.isActive && oldWidget.isActive) {
      _pauseTracking();
      _mapSession++;
      _mapController = null;
    }
  }

  @override
  void dispose() {
    _mapSession++;
    _mapController = null;
    _pauseTracking();
    super.dispose();
  }

  void _pauseTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _resumeTracking() async {
    if (_positionSub != null) return;
    await _startLiveTracking();
  }

  Future<void> _loadMarkerIcons() async {
    final bike = await bitmapBicycleRiderMarker();
    final dest = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    if (mounted) {
      setState(() {
        _bikeIcon = bike;
        _destinationIcon = dest;
      });
      _refreshMapOverlays();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final res = await ApiService.getRiderDeliveryOrders(token);
    if (!mounted) return;

    final orders = (res['orders'] as List<dynamic>? ?? [])
        .where((o) {
          final s = (o as Map)['status']?.toString();
          return s != 'completed' && s != 'cancelled';
        })
        .toList();

    setState(() {
      _orders = orders;
      _loading = false;
      if (_selected == null && orders.isNotEmpty) {
        _selected = Map<String, dynamic>.from(orders.first as Map);
      }
    });

    if (_selected != null && widget.isActive) {
      await _prepareRouteForOrder(_selected!);
    }
  }

  Future<void> _startLiveTracking() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationError = 'Location permission is required for live tracking.';
        });
      }
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationError = 'Turn on device location (GPS) to track your route.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _locationError = null);
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _applyRiderPosition(LatLng(current.latitude, current.longitude), force: true);
    } catch (_) {
      // Stream will provide a fix shortly.
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 15,
      ),
    ).listen((position) {
      _applyRiderPosition(LatLng(position.latitude, position.longitude));
    });

    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pushLocationToBackend();
    });
  }

  void _applyRiderPosition(LatLng pos, {bool force = false}) {
    if (!mounted || !widget.isActive) return;

    if (!force && _lastReportedPosition != null) {
      final moved = Geolocator.distanceBetween(
        _lastReportedPosition!.latitude,
        _lastReportedPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      final sinceLastUi = _lastMarkerUiUpdate == null
          ? const Duration(days: 1)
          : DateTime.now().difference(_lastMarkerUiUpdate!);
      if (moved < 12 && sinceLastUi < const Duration(seconds: 2)) {
        return;
      }
    }

    _lastReportedPosition = pos;
    _lastMarkerUiUpdate = DateTime.now();
    setState(() {
      _riderPosition = pos;
      _markers = _buildMarkers();
      _polylines = _buildPolylines();
    });
  }

  Future<void> _pushLocationToBackend() async {
    if (!widget.isActive) return;
    final sel = _selected;
    if (sel == null) return;
    final token = await AuthService.getToken();
    if (token == null) return;
    await ApiService.riderUpdateLocation(
      token: token,
      orderId: sel['id'] as int,
      lat: _riderPosition.latitude,
      lng: _riderPosition.longitude,
    );
  }

  Future<LatLng?> _resolveDestination(Map<String, dynamic> order) async {
    final address = (order['delivery_address']?.toString() ??
            (order['customer'] is Map ? (order['customer'] as Map)['address']?.toString() : null) ??
            '')
        .trim();

    if (address.isNotEmpty) {
      final geocoded = await PlacesService.geocodeAddress(address);
      if (geocoded != null) {
        return LatLng(geocoded.lat, geocoded.lng);
      }
    }

    final lat = (order['delivery_lat'] as num?)?.toDouble();
    final lng = (order['delivery_lng'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  Future<void> _prepareRouteForOrder(Map<String, dynamic> order) async {
    final dest = await _resolveDestination(order);
    if (!mounted) return;

    if (dest == null) {
      setState(() {
        _destination = null;
        _routePoints = [];
        _markers = _buildMarkers();
        _polylines = {};
      });
      return;
    }

    final route = await PlacesService.getDrivingRoute(
      originLat: _riderPosition.latitude,
      originLng: _riderPosition.longitude,
      destLat: dest.latitude,
      destLng: dest.longitude,
    );

    if (!mounted) return;
    setState(() {
      _destination = dest;
      _routePoints = route.length >= 2 ? route : [_riderPosition, dest];
      _markers = _buildMarkers();
      _polylines = _buildPolylines();
    });
    if (mounted && widget.isActive) {
      await _fitCameraToRoute();
    }
    await _pushLocationToBackend();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderPosition,
        icon: _bikeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 2,
      ),
    };

    final dest = _destination;
    if (dest != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: dest,
          icon: _destinationIcon ?? BitmapDescriptor.defaultMarker,
          zIndexInt: 1,
          infoWindow: InfoWindow(
            title: 'Delivery',
            snippet: _selected?['delivery_address']?.toString() ?? 'Customer',
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_routePoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: List<LatLng>.from(_routePoints),
        color: _brand,
        width: 6,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  void _refreshMapOverlays() {
    setState(() {
      _markers = _buildMarkers();
      _polylines = _buildPolylines();
    });
  }

  Future<void> _fitCameraToRoute() async {
    if (!mounted || !widget.isActive) return;
    final controller = _mapController;
    if (controller == null) return;

    final session = _mapSession;
    final points = <LatLng>[_riderPosition];
    if (_destination != null) points.add(_destination!);
    points.addAll(_routePoints);

    Future<void> animate(CameraUpdate update) async {
      if (!mounted || !widget.isActive || session != _mapSession) return;
      await controller.animateCamera(update);
    }

    try {
      if (points.length == 1) {
        await animate(CameraUpdate.newLatLngZoom(_riderPosition, 15));
        return;
      }

      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final p in points) {
        minLat = minLat < p.latitude ? minLat : p.latitude;
        maxLat = maxLat > p.latitude ? maxLat : p.latitude;
        minLng = minLng < p.longitude ? minLng : p.longitude;
        maxLng = maxLng > p.longitude ? maxLng : p.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      await animate(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (_) {
      if (!mounted || !widget.isActive || session != _mapSession) return;
      try {
        await animate(CameraUpdate.newLatLngZoom(_riderPosition, 14));
      } catch (_) {}
    }
  }

  void _selectOrder(Map<String, dynamic> order) {
    setState(() {
      _selected = order;
      _drawerOpen = false;
    });
    _prepareRouteForOrder(order);
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;

    if (!widget.isActive) {
      return const ColoredBox(color: Color(0xFFE8F4F6));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_loading)
            const ColoredBox(
              color: Color(0xFFE8F4F6),
              child: Center(child: CircularProgressIndicator(color: _brand)),
            )
          else
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(target: _riderPosition, zoom: 14),
              onMapCreated: (controller) {
                _mapController = controller;
                if (widget.isActive) {
                  _fitCameraToRoute();
                }
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
          if (_showMapsSetupHint && !_loading)
            Positioned(
              left: 12,
              right: 12,
              bottom: 88,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: _brand, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enable Directions API in Google Cloud for road routes. '
                          'Also Maps SDK for Android + billing.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800, height: 1.35),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _showMapsSetupHint = false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_locationError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Material(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _locationError!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(backgroundColor: _brand),
                  onPressed: () => setState(() => _drawerOpen = !_drawerOpen),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: _brand),
                  onPressed: _fitCameraToRoute,
                ),
                if (sel != null)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _brand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sel['order_number']?.toString() ?? 'Route',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_drawerOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _drawerOpen = false),
                child: Container(color: Colors.black54),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.82,
              child: Material(
                elevation: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: _brand,
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Active orders',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _drawerOpen = false);
                              _loadOrders();
                            },
                            icon: const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _orders.isEmpty
                          ? const Center(child: Text('No active routes'))
                          : ListView.builder(
                              itemCount: _orders.length,
                              itemBuilder: (context, i) {
                                final o = _orders[i] as Map<String, dynamic>;
                                final address = (o['delivery_address']?.toString() ??
                                        (o['customer'] is Map
                                            ? (o['customer'] as Map)['address']?.toString()
                                            : null) ??
                                        '')
                                    .trim();
                                final statusUi = formatApiLabelForUi(o['status']?.toString());
                                final subtitle = [
                                  if (address.isNotEmpty) address else 'No address',
                                  if (statusUi != '—') statusUi,
                                ].join(' · ');
                                return ListTile(
                                  selected: sel?['id'] == o['id'],
                                  selectedTileColor: _brand.withValues(alpha: 0.08),
                                  leading: const Icon(Icons.local_shipping_outlined, color: _brand),
                                  title: Text(o['order_number']?.toString() ?? 'Order'),
                                  subtitle: Text(subtitle),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _selectOrder(o),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
