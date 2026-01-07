import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedRegion = 'Central';
  String _selectedDistrict = 'Kampala';
  String _selectedPaymentMethod = PaymentMethod.mobileMoney;
  bool _isLoading = false;

  final List<String> _regions = [
    'Central',
    'Eastern',
    'Northern',
    'Western',
  ];

  final Map<String, List<String>> _districts = {
    'Central': ['Kampala', 'Wakiso', 'Mukono', 'Mpigi', 'Luwero'],
    'Eastern': ['Jinja', 'Mbale', 'Soroti', 'Tororo', 'Iganga'],
    'Northern': ['Gulu', 'Lira', 'Arua', 'Kitgum', 'Apac'],
    'Western': ['Mbarara', 'Kabale', 'Fort Portal', 'Masindi', 'Hoima'],
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      if (user.region != null) _selectedRegion = user.region!;
      if (user.district != null) _selectedDistrict = user.district!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final deliveryFee = _calculateDeliveryFee();
      final order = await orderProvider.createOrder(
        buyerId: authProvider.currentUser!.id,
        deliveryAddress: '${_addressController.text.trim()}, $_selectedDistrict, $_selectedRegion',
        paymentMethod: _selectedPaymentMethod,
        items: cartProvider.toOrderItems(),
        subtotal: cartProvider.subtotal,
        deliveryFee: deliveryFee,
        total: cartProvider.subtotal + deliveryFee,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (!mounted) return;

      if (order != null) {
        cartProvider.clearCart();
        
        if (_selectedPaymentMethod == PaymentMethod.mobileMoney) {
          // Navigate to payment screen
          _showPaymentDialog(order.id);
        } else {
          // Cash on delivery - go to success
          _showSuccessDialog(order.id);
        }
      } else {
        _showError(orderProvider.errorMessage ?? 'Failed to place order');
      }
    } catch (e) {
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateDeliveryFee() {
    // Simple delivery fee calculation based on region
    switch (_selectedRegion) {
      case 'Central':
        return 5000;
      case 'Eastern':
      case 'Western':
        return 10000;
      case 'Northern':
        return 15000;
      default:
        return 5000;
    }
  }

  void _showPaymentDialog(final String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('Mobile Money Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.phone_android,
              size: 64,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'A payment request has been sent to your phone.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _phoneController.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please enter your PIN to complete the payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog(orderId);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(final String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: $orderId',
              style: const TextStyle(color: AppColors.grey600),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will receive a confirmation notification shortly.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.buyerHome,
                (final route) => false,
              );
            },
            child: const Text('Continue Shopping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.orderTracking,
                arguments: orderId,
              );
            },
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
  }

  void _showError(final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final deliveryFee = _calculateDeliveryFee();
    final total = cartProvider.subtotal + deliveryFee;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Delivery Address Section
              _buildSectionHeader('Delivery Address'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _addressController,
                label: 'Street Address',
                hint: 'Enter your delivery address',
                prefixIcon: Icons.location_on_outlined,
                validator: (final value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Region',
                      value: _selectedRegion,
                      items: _regions,
                      onChanged: (final value) {
                        setState(() {
                          _selectedRegion = value!;
                          _selectedDistrict = _districts[value]!.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'District',
                      value: _selectedDistrict,
                      items: _districts[_selectedRegion]!,
                      onChanged: (final value) {
                        setState(() => _selectedDistrict = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+256 700 123 456',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (final value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'Delivery Notes (Optional)',
                hint: 'Any special instructions for delivery',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Payment Method Section
              _buildSectionHeader('Payment Method'),
              const SizedBox(height: 12),
              _buildPaymentOption(
                PaymentMethod.mobileMoney,
                'Mobile Money',
                'MTN, Airtel Money',
                Icons.phone_android,
              ),
              _buildPaymentOption(
                PaymentMethod.cashOnDelivery,
                'Cash on Delivery',
                'Pay when you receive',
                Icons.payments_outlined,
              ),
              const SizedBox(height: 24),

              // Order Summary Section
              _buildSectionHeader('Order Summary'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Subtotal (${cartProvider.itemCount} items)',
                      'UGX ${cartProvider.subtotal.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Delivery Fee',
                      'UGX ${deliveryFee.toStringAsFixed(0)}',
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Total',
                      'UGX ${total.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomSheet: _buildBottomBar(total),
      ),
    );
  }

  Widget _buildSectionHeader(final String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _buildDropdown({
    required final String label,
    required final String value,
    required final List<String> items,
    required final void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: items.map((final item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    final String value,
    final String title,
    final String subtitle,
    final IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withOpacity(0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.grey600,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primaryGreen : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (final value) => setState(() => _selectedPaymentMethod = value!),
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(final String label, final String value, {final bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(final double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'UGX ${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: CustomButton(
                text: 'Place Order',
                onPressed: _placeOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
