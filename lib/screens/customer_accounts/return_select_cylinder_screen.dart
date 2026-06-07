import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import 'widgets/customer_return_otp_sheet.dart';

class ReturnSelectCylinderScreen extends StatefulWidget {
  const ReturnSelectCylinderScreen({
    super.key,
    required this.rider,
  });

  final Map<String, dynamic> rider;

  @override
  State<ReturnSelectCylinderScreen> createState() =>
      _ReturnSelectCylinderScreenState();
}

class _ReturnSelectCylinderScreenState extends State<ReturnSelectCylinderScreen> {
  static const _brand = Color(0xFF014F5B);

  List<Map<String, dynamic>> _cylinders = [];
  final Set<int> _selectedIds = {};
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  int get _riderId => int.tryParse(widget.rider['id']?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _loadCylinders();
  }

  Future<void> _loadCylinders() async {
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

    final result = await ApiService.getCustomerReturnableCylinders(token);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final list = result['cylinders'];
        _cylinders = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      } else {
        _error = result['message'] as String? ?? 'Could not load cylinders';
      }
    });
  }

  Future<void> _startReturn() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one cylinder')),
      );
      return;
    }

    setState(() => _submitting = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _submitting = false);
      return;
    }

    final result = await ApiService.customerInitiateReturn(
      token: token,
      riderId: _riderId,
      cylinderIds: _selectedIds.toList(),
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

    final riderName =
        widget.rider['full_name']?.toString() ?? 'the rider';

    final confirmed = await CustomerReturnOtpSheet.show(
      context,
      title: 'Confirm return',
      subtitle:
          'An OTP was sent via SMS to $riderName. Enter the code they share with you.',
      onConfirm: (otp) => ApiService.customerConfirmReturn(
        token: token,
        orderConfirmationId: confirmationId,
        otpCode: otp,
        riderId: _riderId,
        cylinderIds: _selectedIds.toList(),
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cylinder(s) returned to rider successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderName = widget.rider['full_name']?.toString() ?? 'Rider';

    return Scaffold(
      appBar: AppBar(
        title: Text('Return to $riderName'),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _submitting || _selectedIds.isEmpty ? null : _startReturn,
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
                : const Text('Return'),
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
            FilledButton(onPressed: _loadCylinders, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_cylinders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You have no cylinders to return right now.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Select cylinder(s) to return. Each will be marked empty when handed to the rider.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        const SizedBox(height: 16),
        ..._cylinders.map((cylinder) {
          final id = int.tryParse(cylinder['id']?.toString() ?? '') ?? 0;
          final serial = cylinder['serial_number']?.toString() ?? '—';
          final size = cylinder['size']?.toString() ?? '';
          final selected = _selectedIds.contains(id);

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
                          _selectedIds.add(id);
                        } else {
                          _selectedIds.remove(id);
                        }
                      });
                    },
              title: Text(
                serial,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(size.isNotEmpty ? size : 'Cylinder'),
              secondary: const Icon(Icons.propane_tank_outlined, color: _brand),
            ),
          );
        }),
      ],
    );
  }
}
