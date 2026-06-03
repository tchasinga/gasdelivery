import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import 'my_orders_screen.dart';
import 'product_details_screen.dart';
import 'widgets/cart_icon_button.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF014F5B);
  late final TabController _tabController;

  bool _loading = true;
  List<ProductItem> _lpg = [];
  List<ProductItem> _accessories = [];

  static const List<String> _lpgGroupOrder = ['refill', 'outright'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    setState(() => _loading = true);

    final lpgRes = await ApiService.getCustomerProducts(
      token: token,
      category: 'lpg',
    );
    final accRes = await ApiService.getCustomerProducts(
      token: token,
      category: 'accessories',
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _lpg =
          (lpgRes['products'] as List? ?? [])
              .map(
                (e) =>
                    ProductItem.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
      _accessories =
          (accRes['products'] as List? ?? [])
              .map(
                (e) =>
                    ProductItem.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        elevation: 0,
        title: const Text(
          'Order Products',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProducts,
          ),
          const CartIconButton(iconColor: Colors.white),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(child: Text('LPG', style: TextStyle(color: Colors.white))),
            Tab(
              child: Text('Accessories', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: _brand),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Navigation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator(color: _brand))
                : TabBarView(
                  controller: _tabController,
                  children: [
                    _LpgGroupGrid(groupedProducts: _groupedLpgProducts),
                    _ProductGrid(products: _accessories),
                  ],
                ),
      ),
    );
  }

  Map<String, List<ProductItem>> get _groupedLpgProducts {
    final grouped = <String, List<ProductItem>>{'refill': [], 'outright': []};
    for (final item in _lpg) {
      final key = item.productGroupType.toLowerCase();
      if (grouped.containsKey(key)) {
        grouped[key]!.add(item);
      }
    }
    for (final key in _lpgGroupOrder) {
      grouped[key]!.sort((a, b) => a.productPrices.compareTo(b.productPrices));
    }
    return grouped;
  }
}

class _LpgGroupGrid extends StatelessWidget {
  const _LpgGroupGrid({required this.groupedProducts});

  final Map<String, List<ProductItem>> groupedProducts;
  static const _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.58,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, index) {
        final groupType = index == 0 ? 'refill' : 'outright';
        final title =
            groupType == 'refill'
                ? 'LPG Cylinder Refills'
                : 'New Cylinder Outright Purchase';
        final subtitle =
            groupType == 'refill'
                ? 'LPG Refill Products'
                : 'LPG Outright Products';
        final products = groupedProducts[groupType] ?? const <ProductItem>[];
        final image = products
            .map((e) => e.productImage)
            .whereType<String>()
            .firstWhere((url) => url.trim().isNotEmpty, orElse: () => '');
        final minPrice =
            products.isEmpty
                ? 0.0
                : products
                    .map((e) => e.productPrices)
                    .reduce(
                      (value, element) => value < element ? value : element,
                    );

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (products.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No products configured for $title'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => _LpgGroupProductsScreen(
                      title: subtitle,
                      products: products,
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    child:
                        image.isNotEmpty
                            ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              height: double.infinity,
                              errorBuilder:
                                  (_, __, ___) => _groupImageFallback(),
                            )
                            : _groupImageFallback(),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _brand,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Available in: 6kg, 13kg, 45kg',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Starting at: KES ${minPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _brand,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Text(
                              'View products',
                              style: TextStyle(
                                color: _brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: _brand,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _groupImageFallback() => Container(
    color: const Color(0xFFE8F4F6),
    child: const Center(
      child: Icon(Icons.propane_tank_outlined, color: _brand, size: 44),
    ),
  );
}

class _LpgGroupProductsScreen extends StatelessWidget {
  const _LpgGroupProductsScreen({required this.title, required this.products});

  final String title;
  final List<ProductItem> products;
  static const _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: Text(title),
        actions: const [CartIconButton(iconColor: Colors.white)],
      ),
      body: _ProductGrid(products: products),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<ProductItem> products;
  static const _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No products available.')),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (_, i) {
        final p = products[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => ProductDetailsScreen(
                      products: products,
                      initialProduct: p,
                    ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'product_${p.productId}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            p.productImage?.isNotEmpty == true
                                ? Image.network(
                                  p.productImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                )
                                : _placeholder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _brand,
                    ),
                  ),
                  Text(
                    p.productVariant,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    'KES ${p.productPrices.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.add_circle, color: _brand),
                      onPressed:
                          () => context.read<CartProvider>().add(p, qty: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFE8F4F6),
    child: const Center(
      child: Icon(Icons.propane_tank_outlined, color: _brand, size: 36),
    ),
  );
}
