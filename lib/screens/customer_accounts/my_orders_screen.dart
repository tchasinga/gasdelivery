import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/format_api_label.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, this.initialTab = 0});

  /// 0 = Ongoing, 1 = Completed
  final int initialTab;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF014F5B);

  late final TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    List<Map<String, dynamic>> orders = [];
    if (token != null) {
      final res = await ApiService.getCustomerDeliveryOrders(token);
      if (res['success'] == true) {
        orders = (res['orders'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  bool _isCompleted(Map<String, dynamic> order) =>
      order['status']?.toString() == 'completed';

  bool _isOngoing(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    return status != 'completed' && status != 'cancelled';
  }

  String _formatOrderDate(Map<String, dynamic> order) {
    final raw = order['placed_at'] ?? order['delivered_at'];
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min $ampm';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ongoing = _orders.where(_isOngoing).toList();
    final completed = _orders.where(_isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('My orders'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Ongoing Orders (${ongoing.length})'),
            Tab(text: 'Completed (${completed.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : TabBarView(
              controller: _tabController,
              children: [
                _OrderList(
                  orders: ongoing,
                  emptyMessage: 'No ongoing orders right now.',
                  onRefresh: _loadOrders,
                  formatDate: _formatOrderDate,
                ),
                _OrderList(
                  orders: completed,
                  emptyMessage: 'No completed orders yet.',
                  onRefresh: _loadOrders,
                  formatDate: _formatOrderDate,
                ),
              ],
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.onRefresh,
    required this.formatDate,
  });

  final List<Map<String, dynamic>> orders;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final String Function(Map<String, dynamic>) formatDate;

  static const _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: _brand,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _brand,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          final warehouse = order['mini_warehouse'] as Map<String, dynamic>?;
          final status = formatApiLabelForUi(order['status']?.toString());
          final dateLabel = formatDate(order);

          return Material(
            elevation: 2,
            shadowColor: _brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order['order_number']?.toString() ?? 'Order',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _brand,
                          ),
                        ),
                      ),
                      if (order['total_amount'] != null)
                        Text(
                          'KES ${order['total_amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _brand,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    warehouse?['name']?.toString() ?? 'Warehouse',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _brand,
                          ),
                        ),
                      ),
                      if (dateLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
