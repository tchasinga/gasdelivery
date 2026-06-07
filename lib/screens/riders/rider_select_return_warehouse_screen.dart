import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';

/// Searchable list of mini warehouses for rider cylinder drop-off.
class RiderSelectReturnWarehouseScreen extends StatefulWidget {
  const RiderSelectReturnWarehouseScreen({super.key});

  @override
  State<RiderSelectReturnWarehouseScreen> createState() =>
      _RiderSelectReturnWarehouseScreenState();
}

class _RiderSelectReturnWarehouseScreenState
    extends State<RiderSelectReturnWarehouseScreen> {
  static const _brand = Color(0xFF014F5B);

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allWarehouses = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }

    final result = await ApiService.getRiderReturnMiniWarehouses(token);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final list = result['mini_warehouses'];
        _allWarehouses = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _applyFilter(_searchController.text);
      } else {
        _error = result['message'] as String? ?? 'Could not load warehouses';
      }
    });
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List<Map<String, dynamic>>.from(_allWarehouses);
    } else {
      _filtered = _allWarehouses.where((w) {
        final name = w['name']?.toString().toLowerCase() ?? '';
        final address = w['address']?.toString().toLowerCase() ?? '';
        final attendant = w['attendant_name']?.toString().toLowerCase() ?? '';
        return name.contains(q) || address.contains(q) || attendant.contains(q);
      }).toList();
    }
    setState(() {});
  }

  void _selectWarehouse(Map<String, dynamic> warehouse) {
    Navigator.of(context).pop(warehouse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Select mini warehouse'),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, address, or attendant',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: _applyFilter,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brand));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadWarehouses,
                style: FilledButton.styleFrom(backgroundColor: _brand),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _searchController.text.trim().isEmpty
                ? 'No mini warehouses available'
                : 'No warehouses match your search',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final w = _filtered[index];
        final name = w['name']?.toString() ?? 'Warehouse';
        final address = w['address']?.toString() ?? '';
        final attendant = w['attendant_name']?.toString() ?? '';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: _brand.withValues(alpha: 0.12),
              child: const Icon(Icons.storefront_outlined, color: _brand),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(address),
                ],
                if (attendant.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Attendant: $attendant',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectWarehouse(w),
          ),
        );
      },
    );
  }
}
