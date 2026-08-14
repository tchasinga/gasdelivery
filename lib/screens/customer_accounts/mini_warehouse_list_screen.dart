import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MiniWarehouseListScreen extends StatefulWidget {
  const MiniWarehouseListScreen({
    super.key,
    required this.warehouses,
    required this.currentLat,
    required this.currentLng,
  });

  final List<Map<String, dynamic>> warehouses;
  final double currentLat;
  final double currentLng;

  @override
  State<MiniWarehouseListScreen> createState() =>
      _MiniWarehouseListScreenState();
}

class _MiniWarehouseListScreenState extends State<MiniWarehouseListScreen>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF014F5B);
  late final TabController _tabController;
  GoogleMapController? _mapController;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _mapController = null;
    _tabController.dispose();
    super.dispose();
  }

  bool get _isMapTab => _tabController.index == 1;

  Future<void> _fitToMarkers(Set<Marker> markers) async {
    final controller = _mapController;
    if (controller == null || markers.isEmpty) return;

    if (markers.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 14),
      );
      return;
    }

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;
    for (final m in markers) {
      final p = m.position;
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          64,
        ),
      );
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.currentLat, widget.currentLng),
          12.5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.warehouses.map((w) {
      final id = w['id'].toString();
      final selected = _asInt(w['id']) == _selectedId;
      return Marker(
        markerId: MarkerId(id),
        position: LatLng(
          (w['latitude'] as num?)?.toDouble() ?? 0,
          (w['longitude'] as num?)?.toDouble() ?? 0,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: 'Taifa Gas • ${w['name']}',
          snippet: 'Tap marker or use List tab to select',
          onTap: () {
            final wid = _asInt(w['id']);
            if (wid != null) setState(() => _selectedId = wid);
          },
        ),
        onTap: () {
          final wid = _asInt(w['id']);
          if (wid != null) setState(() => _selectedId = wid);
        },
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('Shops list'),
        actions: [
          if (_isMapTab)
            IconButton(
              tooltip: 'Fit all shops',
              icon: const Icon(Icons.zoom_out_map_rounded),
              onPressed: () => _fitToMarkers(markers),
            ),
          if (_isMapTab)
            IconButton(
              tooltip: 'My location',
              icon: const Icon(Icons.my_location),
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(widget.currentLat, widget.currentLng),
                    14,
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Text('List', style: TextStyle(color: Colors.white)),
            ),
            Tab(
              child: Text('Map view', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Keep swipes on the map — don't let TabBarView steal pan gestures.
        physics: _isMapTab
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.warehouses.length,
            itemBuilder: (_, i) {
              final w = widget.warehouses[i];
              final id = _asInt(w['id']);
              final selected = id != null && id == _selectedId;
              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: selected ? _brand : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F4F6),
                    child: Icon(Icons.local_gas_station, color: _brand),
                  ),
                  title: Text(w['name']?.toString() ?? ''),
                  subtitle: Text(
                    '${w['address'] ?? ''}\n${w['distance_km']} km • Shop ${w['attendant_phone_number'] ?? 'N/A'}',
                  ),
                  isThreeLine: true,
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => setState(() => _selectedId = id),
                ),
              );
            },
          ),
          Stack(
            fit: StackFit.expand,
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.currentLat, widget.currentLng),
                  zoom: 12.5,
                ),
                onMapCreated: (controller) async {
                  _mapController = controller;
                  await _fitToMarkers(markers);
                },
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
                mapToolbarEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
                markers: markers,
                padding: const EdgeInsets.only(bottom: 88, top: 8),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      'Drag to move · pinch to zoom · tap a shop marker to select it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _brand),
            onPressed: _selectedId == null
                ? null
                : () {
                    final selected = widget.warehouses.firstWhere(
                      (w) => _asInt(w['id']) == _selectedId,
                    );
                    Navigator.pop(context, selected);
                  },
            child: const Text('Use selected warehouse'),
          ),
        ),
      ),
    );
  }

  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}
