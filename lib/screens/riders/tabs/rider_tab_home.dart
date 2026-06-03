import 'package:flutter/material.dart';
import '../../../services/api_services.dart';
import '../../../services/auth_service.dart';
import '../../../utils/format_api_label.dart';

class RiderTabHome extends StatefulWidget {
  const RiderTabHome({super.key});

  @override
  State<RiderTabHome> createState() => _RiderTabHomeState();
}

class _RiderTabHomeState extends State<RiderTabHome> {
  static const _brand = Color(0xFF014F5B);
  List<dynamic> _active = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) return;
    final res = await ApiService.getRiderDeliveryOrders(token);
    if (!mounted) return;
    final all = res['orders'] as List<dynamic>? ?? [];
    setState(() {
      _active = all.where((o) {
        final s = (o as Map)['status']?.toString();
        return s != 'completed' && s != 'cancelled';
      }).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('My deliveries'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _active.isEmpty
              ? const Center(child: Text('No active orders assigned to you'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _active.length,
                    itemBuilder: (context, i) {
                      final o = _active[i] as Map<String, dynamic>;
                      final customer = o['customer'] as Map<String, dynamic>?;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping, color: _brand),
                          title: Text(o['order_number']?.toString() ?? 'Order'),
                          subtitle: Text(
                            '${customer?['name'] ?? 'Customer'} · ${formatApiLabelForUi(o['status']?.toString())}',
                          ),
                          trailing: o['total_amount'] != null ? Text('KES ${o['total_amount']}') : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
