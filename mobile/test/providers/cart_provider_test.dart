/// Unit Tests for Cart Provider
/// Tests for shopping cart state management
library;

import 'package:flutter_test/flutter_test.dart';

// Mock models for testing
class Product {

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.stock,
  });
  final String id;
  final String name;
  final double price;
  final String unit;
  final int stock;
}

class CartItem {

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    required this.quantity,
  });

  factory CartItem.fromProduct(Product product, int quantity) {
    return CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      unit: product.unit,
      quantity: quantity,
    );
  }
  final String productId;
  final String name;
  final double price;
  final String unit;
  int quantity;

  double get total => price * quantity;
}

// Cart Provider implementation for testing
class CartProvider {
  final List<CartItem> _items = [];
  final bool _isLoading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (final sum, final item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0, (final sum, final item) => sum + (item.price * item.quantity));

  double get deliveryFee => subtotal > 100000 ? 0 : 5000;

  double get total => subtotal + deliveryFee;

  bool get isEmpty => _items.isEmpty;

  void addToCart(final Product product, final int quantity) {
    if (quantity <= 0) {
      _error = 'Quantity must be greater than 0';
      return;
    }

    if (quantity > product.stock) {
      _error = 'Not enough stock available';
      return;
    }

    final existingIndex =
        _items.indexWhere((final item) => item.productId == product.id);

    if (existingIndex >= 0) {
      final newQuantity = _items[existingIndex].quantity + quantity;
      if (newQuantity > product.stock) {
        _error = 'Not enough stock available';
        return;
      }
      _items[existingIndex].quantity = newQuantity;
    } else {
      _items.add(CartItem.fromProduct(product, quantity));
    }
    _error = null;
  }

  void removeFromCart(final String productId) {
    _items.removeWhere((final item) => item.productId == productId);
  }

  void updateQuantity(final String productId, final int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((final item) => item.productId == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
    }
  }

  void incrementQuantity(final String productId, final int maxStock) {
    final index = _items.indexWhere((final item) => item.productId == productId);
    if (index >= 0 && _items[index].quantity < maxStock) {
      _items[index].quantity++;
    }
  }

  void decrementQuantity(final String productId) {
    final index = _items.indexWhere((final item) => item.productId == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        removeFromCart(productId);
      }
    }
  }

  void clearCart() {
    _items.clear();
  }

  bool isInCart(final String productId) {
    return _items.any((final item) => item.productId == productId);
  }

  int getQuantity(final String productId) {
    final item = _items.firstWhere(
      (final item) => item.productId == productId,
      orElse: () => CartItem(
          productId: '', name: '', price: 0, unit: '', quantity: 0),
    );
    return item.quantity;
  }
}

void main() {
  group('CartProvider', () {
    late CartProvider cart;
    late Product testProduct;
    late Product anotherProduct;

    setUp(() {
      cart = CartProvider();
      testProduct = Product(
        id: 'product-1',
        name: 'Fresh Matooke',
        price: 35000,
        unit: 'bunch',
        stock: 10,
      );
      anotherProduct = Product(
        id: 'product-2',
        name: 'Organic Tomatoes',
        price: 15000,
        unit: 'kg',
        stock: 20,
      );
    });

    group('Initial State', () {
      test('starts with empty cart', () {
        expect(cart.items, isEmpty);
        expect(cart.itemCount, 0);
        expect(cart.totalQuantity, 0);
        expect(cart.subtotal, 0);
        expect(cart.isEmpty, isTrue);
      });

      test('starts with no error', () {
        expect(cart.error, isNull);
      });

      test('starts not loading', () {
        expect(cart.isLoading, isFalse);
      });
    });

    group('Adding Items', () {
      test('adds item to empty cart', () {
        cart.addToCart(testProduct, 2);

        expect(cart.itemCount, 1);
        expect(cart.totalQuantity, 2);
        expect(cart.items.first.name, 'Fresh Matooke');
        expect(cart.isEmpty, isFalse);
      });

      test('increases quantity when adding existing item', () {
        cart.addToCart(testProduct, 2);
        cart.addToCart(testProduct, 3);

        expect(cart.itemCount, 1);
        expect(cart.totalQuantity, 5);
        expect(cart.items.first.quantity, 5);
      });

      test('adds multiple different items', () {
        cart.addToCart(testProduct, 2);
        cart.addToCart(anotherProduct, 3);

        expect(cart.itemCount, 2);
        expect(cart.totalQuantity, 5);
      });

      test('rejects quantity of 0 or less', () {
        cart.addToCart(testProduct, 0);

        expect(cart.items, isEmpty);
        expect(cart.error, isNotNull);
      });

      test('rejects quantity exceeding stock', () {
        cart.addToCart(testProduct, 15);

        expect(cart.items, isEmpty);
        expect(cart.error, contains('stock'));
      });

      test('rejects if total quantity exceeds stock', () {
        cart.addToCart(testProduct, 8);
        cart.addToCart(testProduct, 5);

        expect(cart.totalQuantity, 8);
        expect(cart.error, contains('stock'));
      });
    });

    group('Removing Items', () {
      test('removes item from cart', () {
        cart.addToCart(testProduct, 2);
        cart.addToCart(anotherProduct, 3);
        cart.removeFromCart('product-1');

        expect(cart.itemCount, 1);
        expect(cart.items.first.productId, 'product-2');
      });

      test('handles removing non-existent item', () {
        cart.addToCart(testProduct, 2);
        cart.removeFromCart('non-existent');

        expect(cart.itemCount, 1);
      });

      test('cart becomes empty after removing last item', () {
        cart.addToCart(testProduct, 2);
        cart.removeFromCart('product-1');

        expect(cart.isEmpty, isTrue);
      });
    });

    group('Updating Quantity', () {
      test('updates item quantity', () {
        cart.addToCart(testProduct, 2);
        cart.updateQuantity('product-1', 5);

        expect(cart.items.first.quantity, 5);
      });

      test('removes item when quantity set to 0', () {
        cart.addToCart(testProduct, 2);
        cart.updateQuantity('product-1', 0);

        expect(cart.isEmpty, isTrue);
      });

      test('removes item when quantity set to negative', () {
        cart.addToCart(testProduct, 2);
        cart.updateQuantity('product-1', -1);

        expect(cart.isEmpty, isTrue);
      });
    });

    group('Increment/Decrement Quantity', () {
      test('increments quantity by 1', () {
        cart.addToCart(testProduct, 2);
        cart.incrementQuantity('product-1', 10);

        expect(cart.items.first.quantity, 3);
      });

      test('does not increment beyond stock', () {
        cart.addToCart(testProduct, 10);
        cart.incrementQuantity('product-1', 10);

        expect(cart.items.first.quantity, 10);
      });

      test('decrements quantity by 1', () {
        cart.addToCart(testProduct, 3);
        cart.decrementQuantity('product-1');

        expect(cart.items.first.quantity, 2);
      });

      test('removes item when decrementing from 1', () {
        cart.addToCart(testProduct, 1);
        cart.decrementQuantity('product-1');

        expect(cart.isEmpty, isTrue);
      });
    });

    group('Clearing Cart', () {
      test('clears all items', () {
        cart.addToCart(testProduct, 2);
        cart.addToCart(anotherProduct, 3);
        cart.clearCart();

        expect(cart.isEmpty, isTrue);
        expect(cart.itemCount, 0);
        expect(cart.subtotal, 0);
      });
    });

    group('Cart Calculations', () {
      test('calculates subtotal correctly', () {
        cart.addToCart(testProduct, 2); // 35000 * 2 = 70000
        cart.addToCart(anotherProduct, 3); // 15000 * 3 = 45000

        expect(cart.subtotal, 115000);
      });

      test('calculates delivery fee for orders under 100000', () {
        cart.addToCart(anotherProduct, 2); // 15000 * 2 = 30000

        expect(cart.deliveryFee, 5000);
        expect(cart.total, 35000);
      });

      test('free delivery for orders over 100000', () {
        cart.addToCart(testProduct, 3); // 35000 * 3 = 105000

        expect(cart.deliveryFee, 0);
        expect(cart.total, 105000);
      });

      test('calculates total correctly', () {
        cart.addToCart(testProduct, 2); // 70000
        cart.addToCart(anotherProduct, 1); // 15000
        // Subtotal: 85000, Delivery: 5000

        expect(cart.subtotal, 85000);
        expect(cart.total, 90000);
      });
    });

    group('Cart Queries', () {
      test('checks if product is in cart', () {
        cart.addToCart(testProduct, 2);

        expect(cart.isInCart('product-1'), isTrue);
        expect(cart.isInCart('product-2'), isFalse);
      });

      test('gets quantity for product in cart', () {
        cart.addToCart(testProduct, 3);

        expect(cart.getQuantity('product-1'), 3);
        expect(cart.getQuantity('product-2'), 0);
      });
    });

    group('Edge Cases', () {
      test('handles large quantities', () {
        final bigStockProduct = Product(
          id: 'big',
          name: 'Big Stock',
          price: 1000,
          unit: 'piece',
          stock: 10000,
        );
        cart.addToCart(bigStockProduct, 5000);

        expect(cart.items.first.quantity, 5000);
        expect(cart.subtotal, 5000000);
      });

      test('handles decimal prices', () {
        // In UGX we typically don't have decimals, but test the logic
        final decimalProduct = Product(
          id: 'decimal',
          name: 'Decimal Price',
          price: 1500.50,
          unit: 'kg',
          stock: 10,
        );
        cart.addToCart(decimalProduct, 2);

        expect(cart.subtotal, 3001.0);
      });

      test('handles rapid add/remove operations', () {
        for (var i = 0; i < 100; i++) {
          cart.addToCart(testProduct, 1);
          if (i % 2 == 0) {
            cart.decrementQuantity('product-1');
          }
        }

        // After 100 adds and 50 decrements
        expect(cart.items.first.quantity, lessThanOrEqualTo(10));
      });
    });
  });
}
