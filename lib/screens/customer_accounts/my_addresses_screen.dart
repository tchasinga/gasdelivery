import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import 'create_address_screen.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  static const _brand = Color(0xFF014F5B);
  List<Map<String, dynamic>> _addresses = [];
  int? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    final res = await ApiService.getCustomerAddresses(token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _addresses = (res['addresses'] as List).cast<Map<String, dynamic>>();
        final defaultAddress = _addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => <String, dynamic>{},
        );
        _selectedId = _asInt(defaultAddress['id']);
      }
    });
  }

  Future<void> _addNew() async {
    final payload = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CreateAddressScreen()),
    );
    if (payload == null) return;
    final token = await AuthService.getToken();
    if (token == null) return;
    final res = await ApiService.createCustomerAddress(
      token: token,
      name: payload['name'].toString(),
      details: payload['details']?.toString(),
      lat: payload['lat'] as double?,
      lng: payload['lng'] as double?,
      isDefault: _addresses.isEmpty,
    );
    if (res['success'] == true) {
      await _load();
    }
  }

  Future<void> _confirmAddress() async {
    if (_selectedId == null) return;
    final token = await AuthService.getToken();
    if (token == null) return;
    final res = await ApiService.setDefaultAddress(
      token: token,
      addressId: _selectedId!,
    );
    Map<String, dynamic> selected;
    if (res['success'] == true && res['address'] is Map) {
      selected = Map<String, dynamic>.from(res['address'] as Map);
    } else {
      selected = _addresses.firstWhere(
        (a) => _asInt(a['id']) == _selectedId,
        orElse: () => <String, dynamic>{},
      );
    }
    if (!mounted) return;
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('My address'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: _addNew,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('+ Add new address', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (_, i) {
                final a = _addresses[i];
                return Card(
                  child: RadioListTile<int>(
                    value: _asInt(a['id']) ?? 0,
                    groupValue: _selectedId,
                    onChanged: (v) => setState(() => _selectedId = v),
                    title: Text(a['account_customer_address_name']?.toString() ?? ''),
                    subtitle: Text(a['account_customer_address_details']?.toString() ?? ''),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _brand),
            onPressed: _confirmAddress,
            child: const Text('Confirm address'),
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

