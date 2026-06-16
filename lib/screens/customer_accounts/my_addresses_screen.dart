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

  bool get _hasAddresses => _addresses.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final res = await ApiService.getCustomerAddresses(token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _addresses = (res['addresses'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final defaultAddress = _addresses.cast<Map<String, dynamic>?>().firstWhere(
          (a) => a?['is_default'] == true,
          orElse: () => null,
        );
        _selectedId = defaultAddress != null
            ? _asInt(defaultAddress['id'])
            : (_addresses.isNotEmpty ? _asInt(_addresses.first['id']) : null);
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
    if (!mounted) return;
    if (res['success'] == true) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Could not save address'),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('My address'),
        actions: [
          if (_hasAddresses)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _addNew,
                icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
                label: const Text(
                  'Add new',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _hasAddresses
              ? _buildAddressList()
              : _buildEmptyState(),
      bottomNavigationBar: _hasAddresses
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _selectedId == null ? null : _confirmAddress,
                  child: const Text(
                    'Confirm address',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButton: _hasAddresses
          ? FloatingActionButton.extended(
              onPressed: _addNew,
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add new address'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _brand.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 56,
                color: _brand,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No address yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _brand,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add your delivery address so we know where to bring your gas cylinder.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addNew,
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_location_alt_outlined, size: 24),
                label: const Text(
                  'Add new address',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        _AddAddressCard(onTap: _addNew),
        const SizedBox(height: 16),
        ..._addresses.map((a) {
          final id = _asInt(a['id']) ?? 0;
          final isDefault = a['is_default'] == true;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _selectedId == id
                    ? _brand.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
                width: _selectedId == id ? 2 : 1,
              ),
            ),
            child: RadioListTile<int>(
              value: id,
              groupValue: _selectedId,
              activeColor: _brand,
              onChanged: id == 0 ? null : (v) => setState(() => _selectedId = v),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      a['account_customer_address_name']?.toString() ?? 'Address',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _brand,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  a['account_customer_address_details']?.toString() ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}

class _AddAddressCard extends StatelessWidget {
  const _AddAddressCard({required this.onTap});

  final VoidCallback onTap;

  static const _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _brand.withValues(alpha: 0.35),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: [
                _brand.withValues(alpha: 0.06),
                _brand.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_location_alt_outlined,
                  color: _brand,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add new address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _brand,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Save another delivery location',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _brand),
            ],
          ),
        ),
      ),
    );
  }
}
