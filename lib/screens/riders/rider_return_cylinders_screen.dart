import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import 'rider_select_return_warehouse_screen.dart';
import 'widgets/rider_return_otp_sheet.dart';

class RiderReturnCylindersScreen extends StatefulWidget {
  const RiderReturnCylindersScreen({super.key});

  @override
  State<RiderReturnCylindersScreen> createState() =>
      _RiderReturnCylindersScreenState();
}

class _RiderReturnCylindersScreenState
    extends State<RiderReturnCylindersScreen> {
  static const _brand = Color(0xFF014F5B);

  List<Map<String, dynamic>> _cylinders = [];
  final Set<int> _selectedCylinderIds = {};
  Map<String, dynamic>? _selectedWarehouse;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

    final cylResult = await ApiService.getRiderReturnableCylinders(token);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (cylResult['success'] == true) {
        final cylList = cylResult['cylinders'];
        _cylinders = cylList is List
            ? cylList
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      } else {
        _error = cylResult['message'] as String? ?? 'Could not load cylinders';
      }
    });
  }

  int? get _selectedWarehouseId {
    final id = _selectedWarehouse?['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _openWarehousePicker() async {
    final selected = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const RiderSelectReturnWarehouseScreen(),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedWarehouse = selected);
  }

  Future<void> _startReturn() async {
    if (_selectedCylinderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one cylinder')),
      );
      return;
    }
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a mini warehouse')),
      );
      return;
    }

    setState(() => _submitting = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _submitting = false);
      return;
    }

    final result = await ApiService.riderInitiateReturn(
      token: token,
      miniWarehouseId: _selectedWarehouseId!,
      cylinderIds: _selectedCylinderIds.toList(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Could not start return'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final confirmationId =
        int.tryParse(result['order_confirmation_id']?.toString() ?? '');
    if (confirmationId == null) return;

    final warehouse = result['mini_warehouse'] as Map?;
    final warehouseName =
        warehouse?['name']?.toString() ?? 'the warehouse attendant';

    final confirmed = await RiderReturnOtpSheet.show(
      context,
      subtitle:
          'An OTP was sent via SMS to $warehouseName. Enter the code they share with you.',
      onConfirm: (otp) => ApiService.riderConfirmReturn(
        token: token,
        orderConfirmationId: confirmationId,
        otpCode: otp,
        miniWarehouseId: _selectedWarehouseId!,
        cylinderIds: _selectedCylinderIds.toList(),
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cylinder(s) returned to warehouse successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Cylinder'),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _submitting ||
                    _selectedCylinderIds.isEmpty ||
                    _selectedWarehouseId == null
                ? null
                : _startReturn,
            style: FilledButton.styleFrom(
              backgroundColor: _brand,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Return Cylinders'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brand));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Mini warehouse',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: _selectedWarehouse != null
                  ? _brand.withValues(alpha: 0.4)
                  : Colors.grey.shade300,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _brand.withValues(alpha: 0.12),
              child: const Icon(Icons.storefront_outlined, color: _brand),
            ),
            title: Text(
              _selectedWarehouse?['name']?.toString() ?? 'Select mini warehouse',
              style: TextStyle(
                fontWeight: _selectedWarehouse != null
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _selectedWarehouse != null ? null : Colors.grey.shade600,
              ),
            ),
            subtitle: _selectedWarehouse == null
                ? const Text('Tap to browse and search drop-off locations')
                : Text(
                    [
                      if ((_selectedWarehouse!['address']?.toString() ?? '')
                          .isNotEmpty)
                        _selectedWarehouse!['address'].toString(),
                      if ((_selectedWarehouse!['attendant_name']?.toString() ??
                              '')
                          .isNotEmpty)
                        'Attendant: ${_selectedWarehouse!['attendant_name']}',
                    ].join('\n'),
                  ),
            isThreeLine: _selectedWarehouse != null,
            trailing: const Icon(Icons.chevron_right),
            onTap: _openWarehousePicker,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Empty cylinders in your stock',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_cylinders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'You have no empty cylinders to return.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          )
        else
          ..._cylinders.map((cylinder) {
            final id = int.tryParse(cylinder['id']?.toString() ?? '') ?? 0;
            final serial = cylinder['serial_number']?.toString() ?? '—';
            final size = cylinder['size']?.toString() ?? '';
            final selected = _selectedCylinderIds.contains(id);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: CheckboxListTile(
                value: selected,
                activeColor: _brand,
                onChanged: id == 0
                    ? null
                    : (v) {
                        setState(() {
                          if (v == true) {
                            _selectedCylinderIds.add(id);
                          } else {
                            _selectedCylinderIds.remove(id);
                          }
                        });
                      },
                title: Text(
                  serial,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(size.isNotEmpty ? '$size · Empty' : 'Empty'),
                secondary:
                    const Icon(Icons.propane_tank_outlined, color: _brand),
              ),
            );
          }),
      ],
    );
  }
}
