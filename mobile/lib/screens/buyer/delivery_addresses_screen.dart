import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class DeliveryAddress {
  DeliveryAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.region,
    required this.district,
    this.phone,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String fullAddress;
  final String region;
  final String district;
  final String? phone;
  final bool isDefault;
}

class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  final List<DeliveryAddress> _addresses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    // Load user's saved addresses
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null && user.address != null) {
      // Add user's primary address
      _addresses.add(
        DeliveryAddress(
          id: '1',
          label: 'Home',
          fullAddress: user.address!,
          region: user.region ?? 'Central',
          district: user.district ?? 'Kampala',
          phone: user.phone,
          isDefault: true,
        ),
      );
    }

    // TODO: Load additional saved addresses from backend
    setState(() {});
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (final context, final index) {
                final address = _addresses[index];
                return _buildAddressCard(address);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressDialog(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Delivery Addresses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a delivery address to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAddressDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(final DeliveryAddress address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (final value) {
                    if (value == 'edit') {
                      _showEditAddressDialog(address);
                    } else if (value == 'delete') {
                      _deleteAddress(address);
                    } else if (value == 'default') {
                      _setAsDefault(address);
                    }
                  },
                  itemBuilder: (final context) => [
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as Default'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address.fullAddress,
                    style: const TextStyle(color: AppColors.grey700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${address.district}, ${address.region}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
            if (address.phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.grey600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    address.phone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRegion = 'Central';
    String selectedDistrict = 'Kampala';

    final regions = ['Central', 'Eastern', 'Northern', 'Western'];
    final districts = {
      'Central': ['Kampala', 'Wakiso', 'Mukono', 'Mpigi', 'Luwero'],
      'Eastern': ['Jinja', 'Mbale', 'Soroti', 'Tororo', 'Iganga'],
      'Northern': ['Gulu', 'Lira', 'Arua', 'Kitgum', 'Apac'],
      'Western': ['Mbarara', 'Kabale', 'Fort Portal', 'Masindi', 'Hoima'],
    };

    showDialog(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setState) => AlertDialog(
          title: const Text('Add Delivery Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: labelController,
                  label: 'Label',
                  hint: 'e.g., Home, Office',
                  prefixIcon: Icons.label_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: addressController,
                  label: 'Full Address',
                  hint: 'Street, Building, Landmark',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(),
                  ),
                  items: regions.map((final region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (final value) {
                    if (value != null) {
                      setState(() {
                        selectedRegion = value;
                        selectedDistrict = districts[value]!.first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                  ),
                  items: districts[selectedRegion]!.map((final district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (final value) {
                    if (value != null) {
                      setState(() => selectedDistrict = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  hint: '+256 XXX XXX XXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelController.text.isNotEmpty &&
                    addressController.text.isNotEmpty) {
                  final newAddress = DeliveryAddress(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    label: labelController.text,
                    fullAddress: addressController.text,
                    region: selectedRegion,
                    district: selectedDistrict,
                    phone: phoneController.text.isNotEmpty
                        ? phoneController.text
                        : null,
                    isDefault: _addresses.isEmpty,
                  );

                  this.setState(() => _addresses.add(newAddress));
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address added successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAddressDialog(final DeliveryAddress address) {
    // Similar to add, but with existing values
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit address functionality'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _deleteAddress(final DeliveryAddress address) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _addresses.remove(address));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address deleted'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(final DeliveryAddress address) {
    setState(() {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = DeliveryAddress(
          id: _addresses[i].id,
          label: _addresses[i].label,
          fullAddress: _addresses[i].fullAddress,
          region: _addresses[i].region,
          district: _addresses[i].district,
          phone: _addresses[i].phone,
          isDefault: _addresses[i].id == address.id,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
