import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_item.dart';
import '../../providers/cart_provider.dart';
import 'widgets/cart_icon_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.products,
    required this.initialProduct,
  });

  final List<ProductItem> products;
  final ProductItem initialProduct;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const _brand = Color(0xFF014F5B);
  late ProductItem _selected;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialProduct;
  }

  List<String> _sliderImagesForSelectedProduct() {
    final urls = <String>{};
    for (final url in _selected.productImages) {
      final cleaned = url.trim();
      if (cleaned.isNotEmpty) {
        urls.add(cleaned);
      }
    }
    final primary = _selected.productImage?.trim() ?? '';
    if (primary.isNotEmpty) {
      urls.add(primary);
    }

    return urls.toList();
  }

  String _descriptionFor(ProductItem product) {
    final raw = product.productDescription;
    if (raw == null || raw.trim().isEmpty) {
      return 'Quality Taifa Gas product.';
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map && parsed[product.productVariant] is String) {
        return parsed[product.productVariant] as String;
      }
    } catch (_) {}
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final similar =
        widget.products
            .where((p) => p.productName == _selected.productName)
            .toList();
    final sliderImages = _sliderImagesForSelectedProduct();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('Product details'),
        actions: const [CartIconButton()],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey)),
                    Text(
                      'KES ${_selected.productPrices.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _brand,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  minimumSize: const Size(150, 50),
                ),
                onPressed: () {
                  context.read<CartProvider>().add(_selected);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_selected.displayVariant} added to cart',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Add to cart'),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 230,
              child: sliderImages.isEmpty
                  ? _imageFallback()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          key: ValueKey(_selected.productName),
                          itemCount: sliderImages.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (_, index) {
                            return Image.network(
                              sliderImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imageFallback(),
                            );
                          },
                        ),
                        if (sliderImages.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(sliderImages.length, (i) {
                                final active = i == _currentImageIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  height: 7,
                                  width: active ? 18 : 7,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (similar.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final item = similar[i];
                  final selected = item.productId == _selected.productId;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(item.displayVariant),
                    onSelected: (_) => setState(() {
                      _selected = item;
                      _currentImageIndex = 0;
                    }),
                    selectedColor: const Color(0xFFE0F2F1),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: similar.length,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _selected.productName,
            style: const TextStyle(
              color: _brand,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(_descriptionFor(_selected), style: const TextStyle(height: 1.4)),
          const SizedBox(height: 18),
          const Text(
            'Cost split',
            style: TextStyle(
              color: _brand,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    _selected.isAccessory
                        ? 'Category: Accessories'
                        : 'Cylinder size: LPG ${_selected.productVariant}',
                  ),
                  const Spacer(),
                  Text('KES ${_selected.productPrices.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 230,
      color: const Color(0xFFE8F4F6),
      child: const Center(
        child: Icon(Icons.propane_tank_outlined, size: 72, color: _brand),
      ),
    );
  }
}
