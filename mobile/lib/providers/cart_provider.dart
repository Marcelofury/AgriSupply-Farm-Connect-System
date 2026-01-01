import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../models/cart_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  String? _selectedPaymentMethod;
  String? _deliveryAddress;
  String? _deliveryNotes;
  double _deliveryFee = 5000; // Default delivery fee in UGX

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get deliveryAddress => _deliveryAddress;
  String? get deliveryNotes => _deliveryNotes;
  double get deliveryFee => _deliveryFee;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get total {
    return subtotal + _deliveryFee;
  }

  // Group items by farmer
  Map<String, List<CartItemModel>> get itemsByFarmer {
    final Map<String, List<CartItemModel>> grouped = {};
    
    for (final item in _items) {
      final farmerId = item.product.farmerId;
      if (grouped.containsKey(farmerId)) {
        grouped[farmerId]!.add(item);
      } else {
        grouped[farmerId] = [item];
      }
    }
    
    return grouped;
  }

  void addItem(ProductModel product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Update existing item quantity
      final existingItem = _items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      
      if (newQuantity <= product.availableQuantity) {
        _items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      }
    } else {
      // Add new item
      if (quantity <= product.availableQuantity) {
        _items.add(CartItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
        ));
      }
    }
    
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    
    if (index >= 0) {
      final item = _items[index];
      
      if (quantity <= 0) {
        _items.removeAt(index);
      } else if (quantity <= item.product.availableQuantity) {
        _items[index] = item.copyWith(quantity: quantity);
      }
      
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity < item.product.availableQuantity) {
        _items[index] = item.copyWith(quantity: item.quantity + 1);
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity > 1) {
        _items[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItemModel(
        id: '',
        product: ProductModel.empty(),
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setDeliveryNotes(String notes) {
    _deliveryNotes = notes;
    notifyListeners();
  }

  void setDeliveryFee(double fee) {
    _deliveryFee = fee;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _selectedPaymentMethod = null;
    _deliveryAddress = null;
    _deliveryNotes = null;
    _deliveryFee = 5000;
    notifyListeners();
  }

  // Calculate delivery fee based on region
  double calculateDeliveryFee(String region) {
    switch (region.toLowerCase()) {
      case 'central':
        _deliveryFee = 5000;
        break;
      case 'eastern':
        _deliveryFee = 8000;
        break;
      case 'western':
        _deliveryFee = 10000;
        break;
      case 'northern':
        _deliveryFee = 12000;
        break;
      default:
        _deliveryFee = 5000;
    }
    notifyListeners();
    return _deliveryFee;
  }

  // Convert cart to order items for submission
  List<Map<String, dynamic>> toOrderItems() {
    return _items.map((item) => {
      'product_id': item.product.id,
      'quantity': item.quantity,
      'price': item.product.price,
      'total': item.totalPrice,
      'farmer_id': item.product.farmerId,
    }).toList();
  }

  // Save cart to local storage
  Map<String, dynamic> toJson() {
    return {
      'items': _items.map((item) => item.toJson()).toList(),
      'payment_method': _selectedPaymentMethod,
      'delivery_address': _deliveryAddress,
      'delivery_notes': _deliveryNotes,
      'delivery_fee': _deliveryFee,
    };
  }

  // Load cart from local storage
  void fromJson(Map<String, dynamic> json) {
    _items.clear();
    
    if (json['items'] != null) {
      for (final itemJson in json['items']) {
        _items.add(CartItemModel.fromJson(itemJson));
      }
    }
    
    _selectedPaymentMethod = json['payment_method'];
    _deliveryAddress = json['delivery_address'];
    _deliveryNotes = json['delivery_notes'];
    _deliveryFee = (json['delivery_fee'] ?? 5000).toDouble();
    
    notifyListeners();
  }
}
