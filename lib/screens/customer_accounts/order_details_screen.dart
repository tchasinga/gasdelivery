import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/format_api_label.dart';
import '../../utils/phone_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final Map<String, dynamic> order;

  static const brand = Color(0xFF014F5B);
  static const brandLight = Color(0xFF02788D);
  static const brandSoft = Color(0xFFE8F4F6);
  static const ink = Color(0xFF122126);
  static const muted = Color(0xFF6B7A80);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const _brand = OrderDetailsScreen.brand;
  static const _brandLight = OrderDetailsScreen.brandLight;
  static const _brandSoft = OrderDetailsScreen.brandSoft;
  static const _ink = OrderDetailsScreen.ink;
  static const _muted = OrderDetailsScreen.muted;

  late Map<String, dynamic> _order;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
  }

  bool get _isCompleted => _order['status']?.toString() == 'completed';
  bool get _isCancelled => _order['status']?.toString() == 'cancelled';

  String get _paymentOption =>
      _order['payment_option']?.toString() ?? 'pay_on_delivery';

  String get _paymentOptionLabel => _paymentOption == 'pay_immediately'
      ? 'Pay immediately'
      : 'Pay on delivery';

  bool get _canCancel {
    final status = _order['status']?.toString() ?? '';
    return status == 'pending' || status == 'processing';
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text(
          'Cancel order ${_order['order_number'] ?? ''}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _cancelOrder();
  }

  Future<void> _cancelOrder() async {
    final id = _order['id'];
    final orderId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not cancel this order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _cancelling = true);
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to cancel this order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await ApiService.cancelCustomerDeliveryOrder(token, orderId);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (result['success'] == true) {
      final updated = result['order'];
      setState(() {
        if (updated is Map<String, dynamic>) {
          _order = Map<String, dynamic>.from(updated);
        } else {
          _order = {..._order, 'status': 'cancelled'};
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Order cancelled successfully'),
          backgroundColor: _brand,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to cancel order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final status = formatApiLabelForUi(order['status']?.toString());
    final warehouse = order['mini_warehouse'] as Map<String, dynamic>?;
    final rider = order['rider'] as Map<String, dynamic>?;
    final lineItems = _lineItems();
    final orderNumber = order['order_number']?.toString() ?? 'Order';
    final address = (order['delivery_address'] ??
            (order['customer'] is Map
                ? (order['customer'] as Map)['address']
                : null))
        ?.toString()
        .trim();
    final notes = order['notes']?.toString().trim();
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F8),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, topPad + 4, 16, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_brand, _brandLight],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Order details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isCancelled
                              ? 'Cancelled · this order will not be delivered'
                              : _isCompleted
                                  ? 'Completed · thanks for ordering with Gas express'
                                  : 'In progress · track every step of your delivery',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        if (order['total_amount'] != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.payments_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Order total',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'KES ${order['total_amount']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(
                  icon: Icons.timeline_rounded,
                  title: 'Delivery timeline',
                ),
                _SurfaceCard(
                  child: Column(
                    children: [
                      _TimelineStep(
                        label: 'Placed',
                        value: _formatDate(order['placed_at']),
                        icon: Icons.receipt_long_rounded,
                        done: order['placed_at'] != null,
                        isFirst: true,
                      ),
                      _TimelineStep(
                        label: 'Assigned to rider',
                        value: _formatDate(order['assigned_at']),
                        icon: Icons.person_pin_circle_rounded,
                        done: order['assigned_at'] != null,
                      ),
                      _TimelineStep(
                        label: 'Exchange completed',
                        value: _formatDate(order['exchange_completed_at']),
                        icon: Icons.swap_horiz_rounded,
                        done: order['exchange_completed_at'] != null,
                      ),
                      _TimelineStep(
                        label: 'Delivered',
                        value: _formatDate(order['delivered_at']),
                        icon: Icons.check_circle_rounded,
                        done: order['delivered_at'] != null,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  icon: Icons.inventory_2_outlined,
                  title: 'Items in this order',
                ),
                _SurfaceCard(
                  child: lineItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No item details available for this order.',
                            style: TextStyle(color: _muted),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < lineItems.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 24,
                                  color: _brand.withValues(alpha: 0.08),
                                ),
                              _ItemRow(item: lineItems[i]),
                            ],
                          ],
                        ),
                ),
                if (_qtyRequested != null || _qtyFulfilled != null) ...[
                  const SizedBox(height: 18),
                  _SectionHeader(
                    icon: Icons.numbers_rounded,
                    title: 'Quantities',
                  ),
                  Row(
                    children: [
                      if (_qtyRequested != null)
                        Expanded(
                          child: _MetricTile(
                            label: 'Requested',
                            value: '$_qtyRequested',
                          ),
                        ),
                      if (_qtyRequested != null && _qtyFulfilled != null)
                        const SizedBox(width: 10),
                      if (_qtyFulfilled != null)
                        Expanded(
                          child: _MetricTile(
                            label: 'Fulfilled',
                            value: '$_qtyFulfilled',
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _SectionHeader(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery',
                ),
                _SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address != null && address.isNotEmpty
                            ? address
                            : 'No delivery address on this order',
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.45,
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (warehouse != null) ...[
                        const SizedBox(height: 12),
                        Divider(color: _brand.withValues(alpha: 0.08)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 18,
                              color: _brand,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                warehouse['name']?.toString() ?? 'Warehouse',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (warehouse['address'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            warehouse['address'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: _muted,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (rider != null) ...[
                  const SizedBox(height: 18),
                  _SectionHeader(
                    icon: Icons.two_wheeler_rounded,
                    title: 'Assigned rider',
                  ),
                  _SurfaceCard(
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_brand, _brandLight],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rider['name']?.toString() ?? 'Rider',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatApiLabelForUi(
                                  rider['vehicle_type']?.toString(),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _muted,
                                ),
                              ),
                              if (rider['phone'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  rider['phone'].toString(),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: _brand,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (rider['phone'] != null)
                          Material(
                            color: _brandSoft,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  launchPhoneCall(rider['phone'].toString()),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.phone_rounded,
                                  color: _brand,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _SectionHeader(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment method',
                ),
                _SurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _brandSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _paymentOption == 'pay_immediately'
                              ? Icons.flash_on_rounded
                              : Icons.local_shipping_outlined,
                          color: _brand,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _paymentOptionLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _paymentOption == 'pay_immediately'
                                  ? 'M-Pesa STK is sent when you place the order.'
                                  : 'You will pay when the rider delivers your order.',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _SectionHeader(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'Notes',
                  ),
                  _SurfaceCard(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
                if (_canCancel) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cancelling ? null : _confirmCancel,
                      icon: _cancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(
                        _cancelling ? 'Cancelling…' : 'Cancel order',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can cancel while the shop has not assigned a rider yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  int? get _qtyRequested {
    final v = _order['quantity_requested'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  int? get _qtyFulfilled {
    final v = _order['quantity_fulfilled'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  List<Map<String, dynamic>> _lineItems() {
    final raw = _order['order_line_items'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final sizes = _order['cylinder_sizes'];
    final outrights = _order['cylinders_outright'];
    if (sizes is! List || sizes.isEmpty) return const [];

    final outrightList = outrights is List ? outrights : const [];
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < sizes.length; i++) {
      final size = sizes[i]?.toString() ?? '';
      if (size.isEmpty) continue;
      final isOutright = i < outrightList.length && outrightList[i] == 1;
      items.add({
        'product_name': '$size LPG',
        'product_variant': size,
        'product_group_type': isOutright ? 'outright' : 'refill',
        'product_category': 'lpg',
        'quantity': 1,
      });
    }
    return items;
  }

  static String _formatDate(dynamic raw) {
    if (raw == null) return 'Pending';
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: OrderDetailsScreen.brand),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: OrderDetailsScreen.brand,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OrderDetailsScreen.brand.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: OrderDetailsScreen.brand.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: OrderDetailsScreen.brand.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: OrderDetailsScreen.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: OrderDetailsScreen.brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.value,
    required this.icon,
    required this.done,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool done;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final activeColor = done
        ? OrderDetailsScreen.brand
        : const Color(0xFFB7C4C8);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: done
                        ? OrderDetailsScreen.brand.withValues(alpha: 0.35)
                        : const Color(0xFFD5DEE1),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done
                        ? OrderDetailsScreen.brandSoft
                        : const Color(0xFFF0F3F4),
                    shape: BoxShape.circle,
                    border: Border.all(color: activeColor, width: 1.6),
                  ),
                  child: Icon(icon, size: 15, color: activeColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done
                          ? OrderDetailsScreen.brand.withValues(alpha: 0.35)
                          : const Color(0xFFD5DEE1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: isLast ? 0 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: done
                          ? OrderDetailsScreen.ink
                          : OrderDetailsScreen.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: done
                          ? OrderDetailsScreen.brand
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = item['product_name']?.toString() ?? 'Item';
    final variant = item['product_variant']?.toString() ?? '';
    final category = item['product_category']?.toString() ?? '';
    final group = formatApiLabelForUi(item['product_group_type']?.toString());
    final qty = item['quantity']?.toString() ?? '1';
    final unit = item['unit_price'];
    final subtitleParts = <String>[
      if (variant.isNotEmpty && variant != category) variant,
      if (group != '—') group,
      if (category.isNotEmpty) formatApiLabelForUi(category),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: OrderDetailsScreen.brandSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            category == 'accessories'
                ? Icons.handyman_outlined
                : Icons.propane_tank_outlined,
            color: OrderDetailsScreen.brand,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: OrderDetailsScreen.ink,
                ),
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitleParts.join(' · '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: OrderDetailsScreen.muted,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: OrderDetailsScreen.brandSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Qty $qty',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: OrderDetailsScreen.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (unit != null)
          Text(
            'KES $unit',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: OrderDetailsScreen.brand,
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}
