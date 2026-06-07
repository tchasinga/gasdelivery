import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/phone_launcher.dart';
import 'return_select_cylinder_screen.dart';

class SelectReturnRiderScreen extends StatefulWidget {
  const SelectReturnRiderScreen({super.key});

  @override
  State<SelectReturnRiderScreen> createState() =>
      _SelectReturnRiderScreenState();
}

class _SelectReturnRiderScreenState extends State<SelectReturnRiderScreen> {
  static const _brand = Color(0xFF014F5B);

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _riders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRiders({String? query}) async {
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

    final result = await ApiService.getCustomerReturnRiders(
      token: token,
      query: query,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final list = result['riders'];
        _riders = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      } else {
        _error = result['message'] as String? ?? 'Could not load riders';
      }
    });
  }

  void _onSearchChanged(String value) {
    _loadRiders(query: value.trim().isEmpty ? null : value.trim());
  }

  void _selectRider(Map<String, dynamic> rider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReturnSelectCylinderScreen(rider: rider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Rider'),
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
                hintText: 'Search by name, phone, or plate',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _onSearchChanged,
              onChanged: (v) {
                if (v.trim().isEmpty) {
                  _loadRiders();
                }
              },
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
                onPressed: () => _loadRiders(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_riders.isEmpty) {
      return const Center(child: Text('No approved riders found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _riders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rider = _riders[index];
        final name = rider['full_name']?.toString() ?? 'Rider';
        final phone = rider['phone_number']?.toString() ?? '';
        final plate = rider['vehicle_plate_number']?.toString() ?? '';
        final vehicle = rider['vehicle_type']?.toString() ?? '';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _brand.withValues(alpha: 0.12),
              child: const Icon(Icons.two_wheeler, color: _brand),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (vehicle.isNotEmpty) vehicle,
                if (plate.isNotEmpty) plate,
                if (phone.isNotEmpty) phone,
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (phone.isNotEmpty)
                  IconButton(
                    tooltip: 'Call rider',
                    icon: const Icon(Icons.phone_outlined, color: _brand),
                    onPressed: () => launchPhoneCall(phone),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _selectRider(rider),
          ),
        );
      },
    );
  }
}
