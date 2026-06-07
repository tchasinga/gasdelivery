class ProductItem {
  ProductItem({
    required this.productId,
    required this.productName,
    required this.productVariant,
    required this.productGroupType,
    required this.productCategory,
    required this.productPrices,
    this.productImage,
    this.productImages = const [],
    this.productDescription,
    this.cylinderSizeId,
  });

  final int productId;
  final String productName;
  final String productVariant;
  final String productGroupType;
  final String productCategory;
  final double productPrices;
  final String? productImage;
  final List<String> productImages;
  final String? productDescription;
  final int? cylinderSizeId;

  bool get isAccessory => productCategory == 'accessories';

  String get displayVariant =>
      isAccessory ? 'Accessories' : productVariant;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '0') ?? 0;
    }

    int? parseInt(dynamic raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '');
    }

    return ProductItem(
      productId: parseInt(json['product_id']) ?? 0,
      productName: json['product_name']?.toString() ?? '',
      productVariant: json['product_variant']?.toString() ?? '',
      productGroupType: json['product_group_type']?.toString() ?? 'refill',
      productCategory: json['product_category']?.toString() ?? 'lpg',
      productPrices: parsePrice(json['product_prices']),
      productImage: json['product_image']?.toString(),
      productImages: (json['product_images'] as List? ?? const [])
          .map((e) => e?.toString() ?? '')
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      productDescription: json['product_description']?.toString(),
      cylinderSizeId: parseInt(json['cylinder_size_id']),
    );
  }
}

