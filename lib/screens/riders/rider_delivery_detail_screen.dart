import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/format_api_label.dart';

class RiderDeliveryDetailScreen extends StatefulWidget {
  final int orderId;
  const RiderDeliveryDetailScreen({super.key, required this.orderId});

  @override
  State<RiderDeliveryDetailScreen> createState() => _RiderDeliveryDetailScreenState();
}

class _RiderDeliveryDetailScreenState extends State<RiderDeliveryDetailScreen> {
  static const _brand = Color(0xFF014F5B);

  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _busy = false;
  final _otpController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) return;
    final res = await ApiService.getRiderDeliveryOrder(token, widget.orderId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _order = Map<String, dynamic>.from(res['order']);
        _loading = false;
      });
    } else if (!silent) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deliverNow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deliver now?'),
        content: const Text('An M-Pesa STK push will be sent to the customer. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final token = await AuthService.getToken();
    final res = await ApiService.riderDeliverNow(token!, widget.orderId);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? ''),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
    _load();
  }

  Future<void> _verifyOtp() async {
    setState(() => _busy = true);
    final token = await AuthService.getToken();
    final res = await ApiService.riderVerifyDeliveryOtp(
      token: token!,
      orderId: widget.orderId,
      otp: _otpController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? ''),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (res['success'] == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery'), backgroundColor: _brand, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: _brand)),
      );
    }
    final o = _order ?? {};
    final customer = o['customer'] as Map<String, dynamic>?;
    final status = o['status']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(o['order_number']?.toString() ?? 'Delivery'),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(customer?['name']?.toString() ?? '—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(customer?['phone']?.toString() ?? ''),
                  Text(customer?['address']?.toString() ?? ''),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Status: ${formatApiLabelForUi(status)}'),
                  Text('Qty: ${o['quantity_fulfilled'] ?? o['quantity_requested']}'),
                  if (o['total_amount'] != null) Text('Amount: KES ${o['total_amount']}'),
                  Text('Delivery: ${o['delivery_address'] ?? '—'}'),
                ],
              ),
            ),
          ),
          if (status == 'assigned_to_rider' || status == 'in_transit')
            FilledButton(
              onPressed: _busy ? null : _deliverNow,
              style: FilledButton.styleFrom(backgroundColor: _brand, minimumSize: const Size.fromHeight(48)),
              child: _busy
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Deliver now'),
            ),
          if (status == 'awaiting_payment')
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Waiting for customer M-Pesa payment…', textAlign: TextAlign.center),
            ),
          if (status == 'awaiting_delivery_otp') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Customer OTP (6 digits)',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            FilledButton(
              onPressed: _busy ? null : _verifyOtp,
              style: FilledButton.styleFrom(backgroundColor: _brand, minimumSize: const Size.fromHeight(48)),
              child: const Text('Confirm delivery'),
            ),
          ],
        ],
      ),
    );
  }
}
