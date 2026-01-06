import '../models/order_model.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  // Get orders by buyer
  Future<List<OrderModel>> getOrdersByBuyer(String buyerId) async {
    try {
      final data = await _apiService.query(
        'orders',
        select: '*, order_items(*, products(*))',
        filters: {'buyer_id': buyerId},
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch buyer orders: $e');
    }
  }

  // Get orders by farmer
  Future<List<OrderModel>> getOrdersByFarmer(String farmerId) async {
    try {
      final data = await _apiService.query(
        'orders',
        select: '*, order_items!inner(*, products(*)), users!orders_buyer_id_fkey(full_name, phone, photo_url)',
        filters: {'order_items.farmer_id': farmerId},
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch farmer orders: $e');
    }
  }

  // Get all orders (admin)
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final data = await _apiService.query(
        'orders',
        select: '*, order_items(*, products(*)), users!orders_buyer_id_fkey(full_name, phone)',
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all orders: $e');
    }
  }

  // Get order by ID
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final data = await _apiService.getById('orders', orderId);
      if (data == null) {
        throw Exception('Order not found');
      }
      return OrderModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  // Create new order
  Future<OrderModel> createOrder({
    required String buyerId,
    required String deliveryAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    String? notes,
  }) async {
    try {
      // Generate order number
      final orderNumber = _generateOrderNumber();

      // Create order
      final orderData = await _apiService.insert('orders', {
        'order_number': orderNumber,
        'buyer_id': buyerId,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'notes': notes,
        'status': 'pending',
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final orderId = orderData['id'];

      // Create order items
      for (final item in items) {
        await _apiService.insert('order_items', {
          'order_id': orderId,
          'product_id': item['product_id'],
          'farmer_id': item['farmer_id'],
          'quantity': item['quantity'],
          'price': item['price'],
          'total': item['total'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Add initial status history
      await _apiService.insert('order_status_history', {
        'order_id': orderId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification to farmers
      await _notifyFarmers(items);

      return OrderModel.fromJson(orderData);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _apiService.update('orders', orderId, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Add to status history
      await _apiService.insert('order_status_history', {
        'order_id': orderId,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification to buyer
      await _notifyBuyerStatusChange(orderId, status);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Ship order
  Future<void> shipOrder(String orderId, {String? trackingNumber}) async {
    try {
      final updates = <String, dynamic>{
        'status': 'shipped',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (trackingNumber != null) {
        updates['tracking_number'] = trackingNumber;
      }

      await _apiService.update('orders', orderId, updates);

      // Add to status history
      await _apiService.insert('order_status_history', {
        'order_id': orderId,
        'status': 'shipped',
        'notes': trackingNumber != null ? 'Tracking: $trackingNumber' : null,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _notifyBuyerStatusChange(orderId, OrderStatus.shipped);
    } catch (e) {
      throw Exception('Failed to ship order: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _apiService.update('orders', orderId, {
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Add to status history
      await _apiService.insert('order_status_history', {
        'order_id': orderId,
        'status': 'cancelled',
        'notes': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Restore product quantities
      await _restoreProductQuantities(orderId);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Request refund
  Future<void> requestRefund(String orderId, {required String reason}) async {
    try {
      await _apiService.update('orders', orderId, {
        'refund_requested': true,
        'refund_reason': reason,
        'refund_requested_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Notify admin
      await _notifyAdminRefundRequest(orderId, reason);
    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }

  // Process refund (admin)
  Future<void> processRefund(String orderId, {bool approved = true}) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (approved) {
        updates['status'] = 'refunded';
        updates['payment_status'] = 'refunded';
        updates['refunded_at'] = DateTime.now().toIso8601String();
      } else {
        updates['refund_requested'] = false;
        updates['refund_denied_at'] = DateTime.now().toIso8601String();
      }

      await _apiService.update('orders', orderId, updates);

      if (approved) {
        await _apiService.insert('order_status_history', {
          'order_id': orderId,
          'status': 'refunded',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  // Add rating and review
  Future<void> addRating(String orderId, double rating, {String? review}) async {
    try {
      await _apiService.update('orders', orderId, {
        'rating': rating,
        'review': review,
        'rated_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(
    String orderId,
    String status, {
    String? transactionId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'payment_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updates['transaction_id'] = transactionId;
      }

      if (status == PaymentStatus.paid) {
        updates['paid_at'] = DateTime.now().toIso8601String();
      }

      await _apiService.update('orders', orderId, updates);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get order status history
  Future<List<Map<String, dynamic>>> getStatusHistory(String orderId) async {
    try {
      final data = await _apiService.query(
        'order_status_history',
        filters: {'order_id': orderId},
        orderBy: 'created_at',
        ascending: true,
      );

      return data.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch status history: $e');
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStats({
    String? farmerId,
    String? buyerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{};
      
      if (farmerId != null) params['farmer_id'] = farmerId;
      if (buyerId != null) params['buyer_id'] = buyerId;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get('/orders/stats', queryParams: params);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch order stats: $e');
    }
  }

  // Helper methods
  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'AGR-$timestamp';
  }

  Future<void> _notifyFarmers(List<Map<String, dynamic>> items) async {
    // Group items by farmer
    final Map<String, List<Map<String, dynamic>>> farmerItems = {};
    
    for (final item in items) {
      final farmerId = item['farmer_id'] as String;
      if (farmerItems.containsKey(farmerId)) {
        farmerItems[farmerId]!.add(item);
      } else {
        farmerItems[farmerId] = [item];
      }
    }

    // Send notification to each farmer
    for (final farmerId in farmerItems.keys) {
      await _apiService.insert('notifications', {
        'user_id': farmerId,
        'type': 'new_order',
        'title': 'New Order Received',
        'body': 'You have received a new order with ${farmerItems[farmerId]!.length} item(s)',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _notifyBuyerStatusChange(String orderId, String status) async {
    try {
      final order = await getOrderById(orderId);
      
      String title;
      String body;

      if (status == OrderStatus.confirmed) {
        title = 'Order Confirmed';
        body = 'Your order #${order.orderNumber} has been confirmed by the farmer';
      } else if (status == OrderStatus.processing) {
        title = 'Order Processing';
        body = 'Your order #${order.orderNumber} is being prepared';
      } else if (status == OrderStatus.shipped) {
        title = 'Order Shipped';
        body = 'Your order #${order.orderNumber} has been shipped';
      } else if (status == OrderStatus.inTransit) {
        title = 'Order In Transit';
        body = 'Your order #${order.orderNumber} is on the way';
      } else if (status == OrderStatus.delivered) {
        title = 'Order Delivered';
        body = 'Your order #${order.orderNumber} has been delivered';
      } else if (status == OrderStatus.cancelled) {
        title = 'Order Cancelled';
        body = 'Your order #${order.orderNumber} has been cancelled';
      } else {
        return;
      }

      await _apiService.insert('notifications', {
        'user_id': order.buyerId,
        'type': 'order_update',
        'title': title,
        'body': body,
        'data': {'order_id': orderId},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail for notifications
    }
  }

  Future<void> _notifyAdminRefundRequest(String orderId, String reason) async {
    try {
      // Get admin users
      final admins = await _apiService.query(
        'users',
        filters: {'role': 'admin'},
      );

      for (final admin in admins) {
        await _apiService.insert('notifications', {
          'user_id': admin['id'],
          'type': 'refund_request',
          'title': 'Refund Request',
          'body': 'A refund has been requested for order #$orderId: $reason',
          'data': {'order_id': orderId},
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _restoreProductQuantities(String orderId) async {
    try {
      final items = await _apiService.query(
        'order_items',
        filters: {'order_id': orderId},
      );

      for (final item in items) {
        final product = await _apiService.getById('products', item['product_id']);
        if (product != null) {
          await _apiService.update('products', product['id'], {
            'available_quantity': product['available_quantity'] + item['quantity'],
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }
}
