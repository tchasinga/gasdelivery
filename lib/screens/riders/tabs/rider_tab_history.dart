import 'package:flutter/material.dart';
import '../../../services/api_services.dart';
import '../../../services/auth_service.dart';

class RiderTabHistory extends StatefulWidget {
  const RiderTabHistory({super.key});

  @override
  State<RiderTabHistory> createState() => _RiderTabHistoryState();
}

class _RiderTabHistoryState extends State<RiderTabHistory> {
  static const _brand = Color(0xFF014F5B);
  List<dynamic> _history = [];
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
      _history = all.where((o) => (o as Map)['status'] == 'completed').toList();
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
        title: const Text('History'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _history.isEmpty
              ? const Center(child: Text('No completed deliveries yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _history.length,
                    itemBuilder: (context, i) {
                      final o = _history[i] as Map<String, dynamic>;
                      final customer = o['customer'] as Map<String, dynamic>?;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(o['order_number']?.toString() ?? ''),
                          subtitle: Text('${customer?['name'] ?? ''} · ${o['delivered_at'] ?? ''}'),
                          trailing: o['total_amount'] != null ? Text('KES ${o['total_amount']}') : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
