import 'product_model.dart';

class CartModel {
  final List<CartItem> items;

  CartModel({required this.items});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.length;
  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity.toInt());

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  List<String> get farmerIds {
    return items.map((item) => item.farmerId).toSet().toList();
  }

  List<CartItem> getItemsByFarmer(String farmerId) {
    return items.where((item) => item.farmerId == farmerId).toList();
  }
}

class CartItem {
  final String productId;
  final String productName;
  final String? productImage;
  final String farmerId;
  final String farmerName;
  final double price;
  final String unit;
  final double quantity;
  final double availableQuantity;

  CartItem({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.farmerId,
    required this.farmerName,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.availableQuantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      farmerId: json['farmer_id'] as String,
      farmerName: json['farmer_name'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      availableQuantity: (json['available_quantity'] as num).toDouble(),
    );
  }

  factory CartItem.fromProduct(ProductModel product, double quantity) {
    return CartItem(
      productId: product.id,
      productName: product.name,
      productImage: product.primaryImage,
      farmerId: product.farmerId,
      farmerName: product.farmerName,
      price: product.price,
      unit: product.unit,
      quantity: quantity,
      availableQuantity: product.availableQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'available_quantity': availableQuantity,
    };
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    String? productImage,
    String? farmerId,
    String? farmerName,
    double? price,
    String? unit,
    double? quantity,
    double? availableQuantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  double get totalPrice => price * quantity;
  String get displayPrice => 'UGX ${price.toStringAsFixed(0)}/$unit';
  String get displayTotal => 'UGX ${totalPrice.toStringAsFixed(0)}';
  bool get isAvailable => quantity <= availableQuantity;
}
