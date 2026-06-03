import 'package:flutter/foundation.dart';

import '../models/product_item.dart';

class CartLine {
  CartLine({
    required this.product,
    required this.quantity,
  });

  final ProductItem product;
  int quantity;

  double get lineTotal => quantity * product.productPrices;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();

  int get itemCount => _lines.values.fold(0, (sum, l) => sum + l.quantity);

  double get itemTotal => _lines.values.fold(0, (sum, l) => sum + l.lineTotal);

  double get deliveryFee => _lines.isEmpty ? 0 : 50;

  double get tax => itemTotal * 0.03;

  double get grandTotal => itemTotal + deliveryFee + tax;

  String _key(ProductItem product) =>
      '${product.productId}:${product.productVariant}:${product.productGroupType}';

  void add(ProductItem product, {int qty = 1}) {
    final key = _key(product);
    if (_lines.containsKey(key)) {
      _lines[key]!.quantity += qty;
    } else {
      _lines[key] = CartLine(product: product, quantity: qty);
    }
    notifyListeners();
  }

  void increment(String key) {
    final line = _lines[key];
    if (line == null) return;
    line.quantity += 1;
    notifyListeners();
  }

  void decrement(String key) {
    final line = _lines[key];
    if (line == null) return;
    line.quantity -= 1;
    if (line.quantity <= 0) {
      _lines.remove(key);
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  String keyOf(CartLine line) => _key(line.product);
}

