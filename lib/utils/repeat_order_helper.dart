import '../models/product_item.dart';
import '../providers/cart_provider.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';

class RepeatOrderResult {
  const RepeatOrderResult({
    required this.success,
    this.message,
    this.orderNumber,
  });

  final bool success;
  final String? message;
  final String? orderNumber;
}

/// Loads the most recent completed order into the cart for checkout.
class RepeatOrderHelper {
  static Future<RepeatOrderResult> loadMostRecentCompletedOrder(
    CartProvider cart,
  ) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const RepeatOrderResult(
        success: false,
        message: 'Please sign in to repeat an order.',
      );
    }

    final res = await ApiService.getCustomerDeliveryOrders(token);
    if (res['success'] != true) {
      return RepeatOrderResult(
        success: false,
        message: res['message']?.toString() ?? 'Could not load your orders.',
      );
    }

    final orders = (res['orders'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((o) => o['status']?.toString() == 'completed')
        .toList();

    if (orders.isEmpty) {
      return const RepeatOrderResult(
        success: false,
        message: 'No completed orders to repeat yet.',
      );
    }

    orders.sort((a, b) {
      final da = _parseDate(a['delivered_at'] ?? a['placed_at']);
      final db = _parseDate(b['delivered_at'] ?? b['placed_at']);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    final order = orders.first;
    final loaded = _populateCartFromOrder(cart, order);
    if (!loaded) {
      return const RepeatOrderResult(
        success: false,
        message: 'This order cannot be repeated automatically. Try placing a new order.',
      );
    }

    return RepeatOrderResult(
      success: true,
      orderNumber: order['order_number']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static bool _populateCartFromOrder(
    CartProvider cart,
    Map<String, dynamic> order,
  ) {
    cart.clear();

    final lines = order['order_line_items'];
    if (lines is List && lines.isNotEmpty) {
      var added = false;
      for (final raw in lines) {
        if (raw is! Map) continue;
        final line = Map<String, dynamic>.from(raw);
        final qty = (line['quantity'] is int)
            ? line['quantity'] as int
            : int.tryParse(line['quantity']?.toString() ?? '') ?? 1;
        if (qty < 1) continue;

        final category = line['product_category']?.toString() ?? 'lpg';
        final variant = line['product_variant']?.toString() ?? '';
        final groupType = line['product_group_type']?.toString() ??
            (category == 'accessories' ? 'accessories' : 'refill');

        final product = ProductItem(
          productId: _asInt(line['product_id']) ?? 0,
          productName: line['product_name']?.toString() ?? 'Product',
          productVariant: category == 'accessories' ? 'accessories' : variant,
          productGroupType: groupType,
          productCategory: category,
          productPrices: _asDouble(line['unit_price']),
        );
        cart.add(product, qty: qty);
        added = true;
      }
      return added;
    }

    final sizes = order['cylinder_sizes'];
    final outrights = order['cylinders_outright'];
    if (sizes is! List || sizes.isEmpty) return false;

    final outrightList = outrights is List ? outrights : const [];
    var added = false;

    for (var i = 0; i < sizes.length; i++) {
      final size = sizes[i]?.toString() ?? '';
      if (size.isEmpty || size.toLowerCase() == 'accessories') continue;
      final isOutright = i < outrightList.length && outrightList[i] == 1;
      final product = ProductItem(
        productId: 0,
        productName: '$size LPG',
        productVariant: size,
        productGroupType: isOutright ? 'outright' : 'refill',
        productCategory: 'lpg',
        productPrices: 0,
      );
      cart.add(product);
      added = true;
    }

    return added;
  }

  static int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static double _asDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0;
  }
}
