import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

enum OrdersStatus {
  initial,
  loading,
  loaded,
  error,
}

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  OrdersStatus _status = OrdersStatus.initial;
  List<OrderModel> _buyerOrders = [];
  List<OrderModel> _farmerOrders = [];
  List<OrderModel> _allOrders = []; // For admin
  OrderModel? _selectedOrder;
  String? _errorMessage;
  bool _isSubmitting = false;

  // Statistics
  int _pendingCount = 0;
  int _processingCount = 0;
  int _deliveredCount = 0;
  double _totalRevenue = 0;

  // Getters
  OrdersStatus get status => _status;
  List<OrderModel> get orders => [..._buyerOrders, ..._farmerOrders, ..._allOrders];
  List<OrderModel> get buyerOrders => _buyerOrders;
  List<OrderModel> get farmerOrders => _farmerOrders;
  List<OrderModel> get allOrders => _allOrders;
  OrderModel? get selectedOrder => _selectedOrder;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == OrdersStatus.loading;
  bool get isSubmitting => _isSubmitting;
  int get pendingCount => _pendingCount;
  int get processingCount => _processingCount;
  int get deliveredCount => _deliveredCount;
  double get totalRevenue => _totalRevenue;

  // Fetch buyer orders
  Future<void> fetchBuyerOrders(String buyerId) async {
    _status = OrdersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _buyerOrders = await _orderService.getOrdersByBuyer(buyerId);
      _status = OrdersStatus.loaded;
      _calculateBuyerStats();
    } catch (e) {
      _status = OrdersStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch farmer orders
  Future<void> fetchFarmerOrders(String farmerId) async {
    _status = OrdersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _farmerOrders = await _orderService.getOrdersByFarmer(farmerId);
      _status = OrdersStatus.loaded;
      _calculateFarmerStats();
    } catch (e) {
      _status = OrdersStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch all orders (for admin)
  Future<void> fetchAllOrders() async {
    _status = OrdersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allOrders = await _orderService.getAllOrders();
      _status = OrdersStatus.loaded;
      _calculateAdminStats();
    } catch (e) {
      _status = OrdersStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch single order by ID
  Future<void> fetchOrderById(String orderId) async {
    _status = OrdersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderService.getOrderById(orderId);
      _status = OrdersStatus.loaded;
    } catch (e) {
      _status = OrdersStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Get order by ID from local lists or fetch from service
  Future<OrderModel?> getOrderById(String orderId) async {
    // First check local lists
    OrderModel? order = _buyerOrders.where((o) => o.id == orderId).firstOrNull;
    order ??= _farmerOrders.where((o) => o.id == orderId).firstOrNull;
    order ??= _allOrders.where((o) => o.id == orderId).firstOrNull;
    
    if (order != null) return order;
    
    // If not found locally, fetch from service
    try {
      return await _orderService.getOrderById(orderId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // Load farmer orders (alias for fetchFarmerOrders)
  Future<void> loadFarmerOrders(String farmerId) async {
    await fetchFarmerOrders(farmerId);
  }

  // Create new order
  Future<OrderModel?> createOrder({
    required String buyerId,
    required String deliveryAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        buyerId: buyerId,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        notes: notes,
      );

      _buyerOrders.insert(0, order);
      _isSubmitting = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  // Update order status (for farmer)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    _errorMessage = null;

    try {
      await _orderService.updateOrderStatus(orderId, newStatus);

      // Update locally
      _updateOrderInList(_farmerOrders, orderId, (order) {
        return order.copyWith(
          status: newStatus,
        );
      });

      _updateOrderInList(_allOrders, orderId, (order) {
        return order.copyWith(status: newStatus);
      });

      if (_selectedOrder?.id == orderId) {
        _selectedOrder = _selectedOrder!.copyWith(status: newStatus);
      }

      _calculateFarmerStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Confirm order (farmer)
  Future<bool> confirmOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.confirmed);
  }

  // Start processing order (farmer)
  Future<bool> processOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.processing);
  }

  // Ship order (farmer)
  Future<bool> shipOrder(String orderId, {String? trackingNumber}) async {
    _errorMessage = null;

    try {
      await _orderService.shipOrder(orderId, trackingNumber: trackingNumber);

      _updateOrderInList(_farmerOrders, orderId, (order) {
        return order.copyWith(
          status: OrderStatus.shipped,
        );
      });

      _calculateFarmerStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark as delivered
  Future<bool> markAsDelivered(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.delivered);
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    _errorMessage = null;

    try {
      await _orderService.cancelOrder(orderId, reason: reason);

      _updateOrderInList(_buyerOrders, orderId, (order) {
        return order.copyWith(
          status: OrderStatus.cancelled,
        );
      });

      _updateOrderInList(_farmerOrders, orderId, (order) {
        return order.copyWith(
          status: OrderStatus.cancelled,
        );
      });

      if (_selectedOrder?.id == orderId) {
        _selectedOrder = _selectedOrder!.copyWith(
          status: OrderStatus.cancelled,
        );
      }

      _calculateFarmerStats();
      _calculateBuyerStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Request refund
  Future<bool> requestRefund(String orderId, {required String reason}) async {
    _errorMessage = null;

    try {
      await _orderService.requestRefund(orderId, reason: reason);

      _updateOrderInList(_buyerOrders, orderId, (order) {
        return order.copyWith(refundRequested: true);
      });

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add rating to order
  Future<bool> addRating(String orderId, double rating, {String? review}) async {
    _errorMessage = null;

    try {
      await _orderService.addRating(orderId, rating, review: review);

      // Rating is stored in the backend; just refresh local data if needed
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Filter orders by status
  List<OrderModel> getOrdersByStatus(
    List<OrderModel> orders,
    String status,
  ) {
    return orders.where((order) => order.status == status).toList();
  }

  // Get pending orders
  List<OrderModel> get pendingBuyerOrders =>
      getOrdersByStatus(_buyerOrders, OrderStatus.pending);
  
  List<OrderModel> get pendingFarmerOrders =>
      getOrdersByStatus(_farmerOrders, OrderStatus.pending);

  // Get active orders (not completed or cancelled)
  List<OrderModel> get activeBuyerOrders => _buyerOrders.where((order) =>
      order.status != OrderStatus.delivered &&
      order.status != OrderStatus.cancelled &&
      order.status != 'refunded').toList();

  List<OrderModel> get activeFarmerOrders => _farmerOrders.where((order) =>
      order.status != OrderStatus.delivered &&
      order.status != OrderStatus.cancelled &&
      order.status != 'refunded').toList();

  // Calculate statistics
  void _calculateBuyerStats() {
    _pendingCount = _buyerOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    _processingCount = _buyerOrders
        .where((o) =>
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.processing ||
            o.status == OrderStatus.shipped ||
            o.status == OrderStatus.inTransit)
        .length;
    _deliveredCount = _buyerOrders
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    _totalRevenue = _buyerOrders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  void _calculateFarmerStats() {
    _pendingCount = _farmerOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    _processingCount = _farmerOrders
        .where((o) =>
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.processing)
        .length;
    _deliveredCount = _farmerOrders
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    _totalRevenue = _farmerOrders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  void _calculateAdminStats() {
    _pendingCount = _allOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    _processingCount = _allOrders
        .where((o) =>
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.processing ||
            o.status == OrderStatus.shipped)
        .length;
    _deliveredCount = _allOrders
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    _totalRevenue = _allOrders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  void _updateOrderInList(
    List<OrderModel> orders,
    String orderId,
    OrderModel Function(OrderModel) updater,
  ) {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      orders[index] = updater(orders[index]);
    }
  }

  void setSelectedOrder(OrderModel? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
