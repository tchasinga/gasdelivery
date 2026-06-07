import 'package:flutter/material.dart';

import '../../../services/api_services.dart';
import '../../../services/auth_service.dart';
import '../../../utils/format_api_label.dart';
import '../../../utils/phone_launcher.dart';
import '../rider_delivery_detail_screen.dart';

class RiderTabDelivery extends StatefulWidget {
  const RiderTabDelivery({super.key});

  @override
  State<RiderTabDelivery> createState() => _RiderTabDeliveryState();
}

class _RiderTabDeliveryState extends State<RiderTabDelivery> {
  static const _brand = Color(0xFF014F5B);

  static const _withRiderStatuses = <String>{
    'assigned_to_rider',
    'in_transit',
    'awaiting_payment',
    'awaiting_delivery_otp',
  };

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

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
    final res = await ApiService.getRiderDeliveryOrders(token);
    if (!mounted) return;
    final raw = res['orders'] as List<dynamic>? ?? [];
    setState(() {
      _orders = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _withRiderOrders => _orders
      .where((o) => _withRiderStatuses.contains(o['status']?.toString()))
      .toList();

  List<Map<String, dynamic>> get _completedOrders => _orders
      .where((o) => o['status']?.toString() == 'completed')
      .toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          title: const Text('Deliveries'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'With rider (${_withRiderOrders.length})'),
              Tab(text: 'Completed (${_completedOrders.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _brand))
            : TabBarView(
                children: [
                  _buildOrderList(
                    orders: _withRiderOrders,
                    emptyMessage: 'No active deliveries',
                  ),
                  _buildOrderList(
                    orders: _completedOrders,
                    emptyMessage: 'No completed deliveries yet',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderList({
    required List<Map<String, dynamic>> orders,
    required String emptyMessage,
  }) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: _brand,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(child: Text(emptyMessage)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _brand,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, i) => _orderTile(orders[i]),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> o) {
    final customer = o['customer'] is Map
        ? Map<String, dynamic>.from(o['customer'] as Map)
        : null;
    final statusUi = formatApiLabelForUi(o['status']?.toString());
    final subtitleLines = <String>[
      if ((customer?['name']?.toString() ?? '').trim().isNotEmpty)
        customer!['name'].toString(),
      if ((customer?['address']?.toString() ?? '').trim().isNotEmpty)
        customer!['address'].toString(),
      if (statusUi != '—') statusUi,
    ];
    final subtitleText =
        subtitleLines.isEmpty ? '—' : subtitleLines.join('\n');
    final customerPhone = (customer?['phone']?.toString() ?? '').trim();
    final orderId = int.tryParse(o['id']?.toString() ?? '');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.two_wheeler, color: _brand),
        title: Text(o['order_number']?.toString() ?? 'Order'),
        subtitle: Text(subtitleText),
        isThreeLine: subtitleLines.length > 1,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customerPhone.isNotEmpty)
              IconButton(
                onPressed: () => launchPhoneCall(
                  customerPhone,
                  context: context,
                ),
                icon: const Icon(
                  Icons.phone,
                  color: _brand,
                  size: 22,
                ),
                tooltip: 'Call customer',
                visualDensity: VisualDensity.compact,
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: orderId == null
            ? null
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RiderDeliveryDetailScreen(orderId: orderId),
                  ),
                );
                _load();
              },
      ),
    );
  }
}
