import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/auth_gatekeeper.dart';
import 'mini_warehouse_list_screen.dart';
import 'my_addresses_screen.dart';

class MyCartScreen extends StatefulWidget {
  const MyCartScreen({super.key});

  @override
  State<MyCartScreen> createState() => _MyCartScreenState();
}

class _MyCartScreenState extends State<MyCartScreen> {
  static const _brand = Color(0xFF014F5B);

  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedWarehouse;
  bool _loadingWarehouse = false;
  bool _placingOrder = false;
  bool _warehouseManuallySelected = false;
  double? _deviceLat;
  double? _deviceLng;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddressAndWarehouse();
  }

  Future<void> _loadDefaultAddressAndWarehouse() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    final addrRes = await ApiService.getCustomerAddresses(token);
    if (addrRes['success'] == true) {
      final addresses =
          (addrRes['addresses'] as List).cast<Map<String, dynamic>>();
      final fallback = addresses.firstWhere(
        (a) => a['is_default'] == true,
        orElse:
            () => addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );
      if (fallback.isNotEmpty) {
        _selectedAddress = fallback;
      }
    }
    await _loadNearbyWarehouses();
    if (mounted) setState(() {});
  }

  Future<void> _loadNearbyWarehouses() async {
    final token = await AuthService.getToken();
    if (token == null || _selectedAddress == null) return;
    final (lat, lng) = _resolveAddressOrDeviceCoords();
    if (lat == null || lng == null) return;

    setState(() => _loadingWarehouse = true);
    final res = await ApiService.getNearbyMiniWarehouses(
      token: token,
      lat: lat,
      lng: lng,
      radiusKm: 5,
    );
    if (!mounted) return;
    setState(() {
      _loadingWarehouse = false;
      if (res['success'] != true) return;

      final list =
          (res['mini_warehouses'] as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) return;

      _selectedWarehouse = list.first;
      _warehouseManuallySelected = false;
    });
  }

  /// Loads address/warehouse only when missing. Never overwrites a manual shop pick.
  Future<void> _ensureCheckoutReady() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      final addrRes = await ApiService.getCustomerAddresses(token);
      if (addrRes['success'] == true) {
        final addresses =
            (addrRes['addresses'] as List).cast<Map<String, dynamic>>();
        final fallback = addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse:
              () =>
                  addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
        );
        if (fallback.isNotEmpty) {
          _selectedAddress = fallback;
        }
      }
    }

    if (_selectedWarehouse == null) {
      await _loadNearbyWarehouses();
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickAddress() async {
    if (!await AuthGatekeeper.requireAuth(context) || !mounted) return;
    await _ensureCheckoutReady();
    if (!mounted) return;

    final selected = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
    );
    if (selected == null) return;
    setState(() {
      _selectedAddress = selected;
      _selectedWarehouse = null;
      _warehouseManuallySelected = false;
    });
    await _loadNearbyWarehouses();
  }

  Future<void> _pickWarehouse() async {
    if (!await AuthGatekeeper.requireAuth(context) || !mounted) return;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a delivery address first.')),
      );
      return;
    }
    final token = await AuthService.getToken();
    if (token == null) return;
    final (lat, lng) = _resolveAddressOrDeviceCoords();
    if (lat == null || lng == null) return;
    final res = await ApiService.getNearbyMiniWarehouses(
      token: token,
      lat: lat,
      lng: lng,
      radiusKm: 5,
    );
    if (res['success'] != true) return;
    final warehouses =
        (res['mini_warehouses'] as List).cast<Map<String, dynamic>>();
    final selected = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder:
            (_) => MiniWarehouseListScreen(
              warehouses: warehouses,
              currentLat: lat,
              currentLng: lng,
            ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedWarehouse = selected;
        _warehouseManuallySelected = true;
      });
    }
  }

  (double?, double?) _resolveAddressOrDeviceCoords() {
    final coords = _selectedAddress?['account_customer_longitude_latitude'];
    if (coords is Map) {
      final lat = _toDouble(coords['lat'] ?? coords['x']);
      final lng = _toDouble(coords['lng'] ?? coords['y']);
      if (lat != null && lng != null) {
        return (lat, lng);
      }
    }
    return (_deviceLat, _deviceLng);
  }

  Future<void> _useCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required to find nearby warehouses.',
          ),
        ),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() {
      _deviceLat = pos.latitude;
      _deviceLng = pos.longitude;
      _warehouseManuallySelected = false;
    });
    await _loadNearbyWarehouses();
  }

  String _formatDeliveryAddress(Map<String, dynamic> address) {
    final name =
        address['account_customer_address_name']?.toString().trim() ?? '';
    final details =
        address['account_customer_address_details']?.toString().trim() ?? '';
    if (name.isEmpty) return details;
    if (details.isEmpty) return name;
    return '$name — $details';
  }

  Future<void> _onPlaceOrderPressed(CartProvider cart) async {
    if (cart.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!await AuthGatekeeper.requireAuth(context) || !mounted) return;

    await _ensureCheckoutReady();
    if (!mounted) return;

    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a delivery address before placing your order.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a mini warehouse before placing your order.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => _PlaceOrderConfirmSheet(
            itemCount: cart.itemCount,
            itemTotal: cart.itemTotal,
            addressLabel:
                _selectedAddress!['account_customer_address_name']
                    ?.toString() ??
                'Delivery address',
            warehouseName:
                _selectedWarehouse!['name']?.toString() ?? 'Mini warehouse',
          ),
    );

    if (confirmed == true && mounted) {
      await _placeOrder(cart);
    }
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (cart.lines.isEmpty || _selectedWarehouse == null) return;
    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a delivery address before placing your order.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final token = await AuthService.getToken();
    if (token == null) return;
    setState(() => _placingOrder = true);
    final lineItems =
        cart.lines
            .map(
              (line) => {
                'product_id': line.product.productId,
                'product_name': line.product.productName,
                'product_category': line.product.productCategory,
                'product_variant': line.product.displayVariant,
                'product_group_type': line.product.productGroupType,
                'quantity': line.quantity,
                'unit_price': line.product.productPrices,
              },
            )
            .toList();
    final (lat, lng) = _resolveAddressOrDeviceCoords();
    final addressHolderId = _toInt(_selectedAddress!['id']);
    final res = await ApiService.placeCustomerDeliveryOrder(
      token: token,
      miniWarehouseId: _toInt(_selectedWarehouse!['id']),
      lineItems: lineItems,
      notes: 'Cart checkout with ${cart.itemCount} item(s)',
      customerAccountAddressHolderId:
          addressHolderId > 0 ? addressHolderId : null,
      deliveryAddress: _formatDeliveryAddress(_selectedAddress!),
      deliveryLat: lat,
      deliveryLng: lng,
    );
    if (!mounted) return;
    setState(() => _placingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? 'Order processed'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (res['success'] == true) {
      cart.clear();
      Navigator.pop(context);
    }
  }

  int _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  double? _toDouble(dynamic raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  Future<void> _refreshPage() async {
    _warehouseManuallySelected = false;
    await _loadDefaultAddressAndWarehouse();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = !context.watch<AuthProvider>().isAuthenticated;

    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            title: const Text('My cart'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isGuest ? null : _refreshPage,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isGuest)
                Card(
                  color: const Color(0xFFE8F4F6),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: _brand),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Browsing as guest. Sign in when you place your order to set delivery details.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isGuest) const SizedBox(height: 12),
              const Text(
                'Items in cart',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (cart.lines.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No items in cart'),
                  ),
                )
              else
                ...cart.lines.map((line) {
                  final key = cart.keyOf(line);
                  return Card(
                    child: ListTile(
                      leading:
                          line.product.productImage?.isNotEmpty == true
                              ? Image.network(
                                line.product.productImage!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              )
                              : const Icon(Icons.propane_tank_outlined),
                      title: Text(line.product.productName),
                      subtitle: Text(
                        '${line.product.displayVariant} • KES ${line.product.productPrices.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => cart.decrement(key),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${line.quantity}'),
                          IconButton(
                            onPressed: () => cart.increment(key),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    _selectedAddress?['account_customer_address_name']
                            ?.toString() ??
                        (isGuest ? 'Delivery address' : 'Select address'),
                  ),
                  subtitle: Text(
                    isGuest
                        ? 'Sign in to choose a saved address'
                        : (_selectedAddress?['account_customer_address_details']
                                    ?.toString()
                                    .isNotEmpty ==
                                true
                            ? _selectedAddress!['account_customer_address_details']
                                .toString()
                            : 'Tap to choose saved address'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickAddress,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station),
                  title: Text(
                    _selectedWarehouse?['name']?.toString() ??
                        (isGuest ? 'Mini warehouse' : 'Select mini warehouse'),
                  ),
                  subtitle: Text(
                    isGuest
                        ? 'Sign in to find nearby shops'
                        : (_loadingWarehouse
                            ? 'Searching warehouses in 5km radius...'
                            : (_selectedWarehouse?['distance_km'] != null
                                ? '${_selectedWarehouse!['distance_km']} km away'
                                : 'Tap to choose from nearby list')),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickWarehouse,
                ),
              ),
              if (!isGuest) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my current location'),
                ),
              ],
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _brand,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _line('Item total', cart.itemTotal, bold: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed:
                    (_placingOrder || cart.lines.isEmpty)
                        ? null
                        : () => _onPlaceOrderPressed(cart),
                child:
                    _placingOrder
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          isGuest ? 'Sign in to place order' : 'Place order',
                        ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _line(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text('KES ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _PlaceOrderConfirmSheet extends StatelessWidget {
  const _PlaceOrderConfirmSheet({
    required this.itemCount,
    required this.itemTotal,
    required this.addressLabel,
    required this.warehouseName,
  });

  static const _brand = Color(0xFF014F5B);

  final int itemCount;
  final double itemTotal;
  final String addressLabel;
  final String warehouseName;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirm your order',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _brand,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Do you want to place this order?',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _summaryRow(
            Icons.shopping_bag_outlined,
            '$itemCount item${itemCount == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 10),
          _summaryRow(Icons.location_on_outlined, addressLabel),
          const SizedBox(height: 10),
          _summaryRow(Icons.local_gas_station, warehouseName),
          const SizedBox(height: 10),
          _summaryRow(
            Icons.payments_outlined,
            'KES ${itemTotal.toStringAsFixed(2)} item total',
            emphasized: true,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8C96A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded, size: 22, color: Color(0xFFB45309)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important notice',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'By confirming this order, you acknowledge that you have an empty cylinder available for exchange at the time of delivery.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brand,
                    side: const BorderSide(color: _brand),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, place order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text, {bool emphasized = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _brand),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              color: emphasized ? _brand : const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
