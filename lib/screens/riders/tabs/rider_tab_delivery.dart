import 'package:flutter/material.dart';
import '../../../services/api_services.dart';
import '../../../services/auth_service.dart';
import '../../../utils/format_api_label.dart';
import '../rider_delivery_detail_screen.dart';

class RiderTabDelivery extends StatefulWidget {
  const RiderTabDelivery({super.key});

  @override
  State<RiderTabDelivery> createState() => _RiderTabDeliveryState();
}

class _RiderTabDeliveryState extends State<RiderTabDelivery> {
  static const _brand = Color(0xFF014F5B);
  List<dynamic> _orders = [];
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
    setState(() {
      _orders = res['orders'] as List<dynamic>? ?? [];
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
        title: const Text('Deliveries'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _orders.isEmpty
              ? const Center(child: Text('No deliveries yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) {
                      final o = _orders[i] as Map<String, dynamic>;
                      final customer = o['customer'] as Map<String, dynamic>?;
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
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.two_wheeler, color: _brand),
                          title: Text(o['order_number']?.toString() ?? 'Order'),
                          subtitle: Text(subtitleText),
                          isThreeLine: subtitleLines.length > 1,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RiderDeliveryDetailScreen(orderId: o['id'] as int),
                              ),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
