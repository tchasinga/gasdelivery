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
  State<MiniWarehouseListScreen> createState() => _MiniWarehouseListScreenState();
}

class _MiniWarehouseListScreenState extends State<MiniWarehouseListScreen>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF014F5B);
  late final TabController _tabController;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.warehouses.map((w) {
      final id = w['id'].toString();
      return Marker(
        markerId: MarkerId(id),
        position: LatLng(
          (w['latitude'] as num?)?.toDouble() ?? 0,
          (w['longitude'] as num?)?.toDouble() ?? 0,
        ),
        infoWindow: InfoWindow(
          title: 'Taifa Gas • ${w['name']}',
          snippet: 'Tap list tab to select warehouse',
        ),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('Shops list'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: Text('List' , style: TextStyle(color: Colors.white))),
            Tab(child: Text('Map view' , style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
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
                  trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () => setState(() => _selectedId = id),
                ),
              );
            },
          ),
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.currentLat, widget.currentLng),
              zoom: 12.5,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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

