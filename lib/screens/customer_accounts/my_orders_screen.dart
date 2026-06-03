import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/format_api_label.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  static const _brand = Color(0xFF014F5B);

  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    List<dynamic> orders = [];
    if (token != null) {
      final res = await ApiService.getCustomerDeliveryOrders(token);
      if (res['success'] == true) {
        orders = res['orders'] as List<dynamic>? ?? [];
      }
    }

    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        elevation: 0,
        title: const Text('My orders', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'My orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _brand,
                  ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: _brand)),
              )
            else if (_orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No orders yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._orders.map((o) {
                final m = o as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(m['order_number']?.toString() ?? 'Order'),
                    subtitle: Text(
                      '${m['mini_warehouse']?['name'] ?? 'Warehouse'} · ${formatApiLabelForUi(m['status']?.toString())}',
                    ),
                    trailing: m['total_amount'] != null
                        ? Text('KES ${m['total_amount']}')
                        : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
