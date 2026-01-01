import '../models/order_model.dart';
import 'api_service.dart';

enum PaymentProvider {
  mtnMobile,
  airtelMoney,
  card,
  cashOnDelivery,
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorCode;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.errorCode,
  });
}

class PaymentService {
  final ApiService _apiService = ApiService();

  // Initialize payment
  Future<PaymentResult> initiatePayment({
    required String orderId,
    required double amount,
    required PaymentProvider provider,
    required String phoneNumber,
  }) async {
    try {
      switch (provider) {
        case PaymentProvider.mtnMobile:
          return await _initiateMTNPayment(orderId, amount, phoneNumber);
        case PaymentProvider.airtelMoney:
          return await _initiateAirtelPayment(orderId, amount, phoneNumber);
        case PaymentProvider.card:
          return await _initiateCardPayment(orderId, amount);
        case PaymentProvider.cashOnDelivery:
          return await _initiateCOD(orderId, amount);
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment initialization failed: $e',
      );
    }
  }

  // MTN Mobile Money payment
  Future<PaymentResult> _initiateMTNPayment(
    String orderId,
    double amount,
    String phoneNumber,
  ) async {
    try {
      final response = await _apiService.post('/payments/mtn', body: {
        'order_id': orderId,
        'amount': amount,
        'phone_number': phoneNumber,
        'currency': 'UGX',
        'payer_message': 'Payment for AgriSupply order #$orderId',
        'payee_note': 'AgriSupply order payment',
      });

      if (response['status'] == 'pending' || response['status'] == 'success') {
        // Record payment initiation
        await _recordPayment(
          orderId: orderId,
          amount: amount,
          provider: 'mtn_mobile',
          transactionId: response['transaction_id'],
          status: 'pending',
        );

        return PaymentResult(
          success: true,
          transactionId: response['transaction_id'],
          message: 'Please confirm payment on your phone',
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Payment failed',
          errorCode: response['error_code'],
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'MTN payment failed: $e',
      );
    }
  }

  // Airtel Money payment
  Future<PaymentResult> _initiateAirtelPayment(
    String orderId,
    double amount,
    String phoneNumber,
  ) async {
    try {
      final response = await _apiService.post('/payments/airtel', body: {
        'order_id': orderId,
        'amount': amount,
        'phone_number': phoneNumber,
        'currency': 'UGX',
        'reference': 'AGR-$orderId',
      });

      if (response['status'] == 'pending' || response['status'] == 'success') {
        await _recordPayment(
          orderId: orderId,
          amount: amount,
          provider: 'airtel_money',
          transactionId: response['transaction_id'],
          status: 'pending',
        );

        return PaymentResult(
          success: true,
          transactionId: response['transaction_id'],
          message: 'Please confirm payment on your phone',
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Payment failed',
          errorCode: response['error_code'],
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Airtel payment failed: $e',
      );
    }
  }

  // Card payment (Flutterwave/Paystack)
  Future<PaymentResult> _initiateCardPayment(
    String orderId,
    double amount,
  ) async {
    try {
      final response = await _apiService.post('/payments/card', body: {
        'order_id': orderId,
        'amount': amount,
        'currency': 'UGX',
        'redirect_url': 'agrisupply://payment/callback',
      });

      if (response['payment_url'] != null) {
        await _recordPayment(
          orderId: orderId,
          amount: amount,
          provider: 'card',
          transactionId: response['reference'],
          status: 'pending',
        );

        return PaymentResult(
          success: true,
          transactionId: response['reference'],
          message: response['payment_url'], // Return URL for webview
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Card payment initialization failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Card payment failed: $e',
      );
    }
  }

  // Cash on Delivery
  Future<PaymentResult> _initiateCOD(
    String orderId,
    double amount,
  ) async {
    try {
      await _recordPayment(
        orderId: orderId,
        amount: amount,
        provider: 'cash_on_delivery',
        status: 'pending',
      );

      // Update order payment status
      await _apiService.update('orders', orderId, {
        'payment_status': 'pending',
        'payment_method': 'cash_on_delivery',
        'updated_at': DateTime.now().toIso8601String(),
      });

      return PaymentResult(
        success: true,
        message: 'Cash on delivery selected. Pay when you receive your order.',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Failed to set COD: $e',
      );
    }
  }

  // Check payment status
  Future<PaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      final response = await _apiService.get('/payments/$transactionId/status');
      
      switch (response['status']) {
        case 'completed':
        case 'successful':
          return PaymentStatus.completed;
        case 'pending':
          return PaymentStatus.pending;
        case 'processing':
          return PaymentStatus.processing;
        case 'failed':
          return PaymentStatus.failed;
        default:
          return PaymentStatus.pending;
      }
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  // Verify payment callback
  Future<bool> verifyPayment(String transactionId) async {
    try {
      final response = await _apiService.post('/payments/$transactionId/verify');
      
      if (response['verified'] == true) {
        // Update payment record
        await _updatePaymentStatus(transactionId, 'completed');
        
        // Update order payment status
        final payment = await _getPaymentByTransactionId(transactionId);
        if (payment != null) {
          await _apiService.update('orders', payment['order_id'], {
            'payment_status': 'completed',
            'paid_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Process refund
  Future<PaymentResult> processRefund({
    required String orderId,
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await _apiService.post('/payments/refund', body: {
        'transaction_id': transactionId,
        'amount': amount,
        'reason': reason,
      });

      if (response['status'] == 'success') {
        // Update order status
        await _apiService.update('orders', orderId, {
          'status': 'refunded',
          'payment_status': 'refunded',
          'refunded_at': DateTime.now().toIso8601String(),
          'refund_amount': amount,
          'updated_at': DateTime.now().toIso8601String(),
        });

        return PaymentResult(
          success: true,
          transactionId: response['refund_transaction_id'],
          message: 'Refund processed successfully',
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Refund failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Refund processing failed: $e',
      );
    }
  }

  // Get payment history for order
  Future<List<Map<String, dynamic>>> getPaymentHistory(String orderId) async {
    try {
      final payments = await _apiService.query(
        'payments',
        filters: {'order_id': orderId},
        orderBy: 'created_at',
        ascending: false,
      );
      return payments;
    } catch (e) {
      throw Exception('Failed to fetch payment history: $e');
    }
  }

  // Record payment in database
  Future<void> _recordPayment({
    required String orderId,
    required double amount,
    required String provider,
    String? transactionId,
    required String status,
  }) async {
    await _apiService.insert('payments', {
      'order_id': orderId,
      'amount': amount,
      'provider': provider,
      'transaction_id': transactionId,
      'status': status,
      'currency': 'UGX',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Update payment status
  Future<void> _updatePaymentStatus(String transactionId, String status) async {
    try {
      final payments = await _apiService.query(
        'payments',
        filters: {'transaction_id': transactionId},
        limit: 1,
      );

      if (payments.isNotEmpty) {
        await _apiService.update('payments', payments[0]['id'], {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Get payment by transaction ID
  Future<Map<String, dynamic>?> _getPaymentByTransactionId(
    String transactionId,
  ) async {
    try {
      final payments = await _apiService.query(
        'payments',
        filters: {'transaction_id': transactionId},
        limit: 1,
      );

      return payments.isNotEmpty ? payments.first : null;
    } catch (e) {
      return null;
    }
  }

  // Validate phone number for mobile money
  bool validatePhoneNumber(String phone, PaymentProvider provider) {
    // Remove spaces and dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Check Uganda phone format
    if (!cleanPhone.startsWith('+256') && !cleanPhone.startsWith('0')) {
      return false;
    }

    final phoneDigits = cleanPhone.startsWith('+256')
        ? cleanPhone.substring(4)
        : cleanPhone.substring(1);

    if (phoneDigits.length != 9) return false;

    // MTN Uganda prefixes: 77, 78, 76
    if (provider == PaymentProvider.mtnMobile) {
      return phoneDigits.startsWith('77') ||
          phoneDigits.startsWith('78') ||
          phoneDigits.startsWith('76');
    }

    // Airtel Uganda prefixes: 70, 75, 74
    if (provider == PaymentProvider.airtelMoney) {
      return phoneDigits.startsWith('70') ||
          phoneDigits.startsWith('75') ||
          phoneDigits.startsWith('74');
    }

    return true;
  }

  // Format amount for display
  String formatAmount(double amount) {
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
