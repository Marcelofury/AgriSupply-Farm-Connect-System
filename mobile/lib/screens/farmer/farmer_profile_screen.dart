import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmDescriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRegion = '';
  String _selectedDistrict = '';
  File? _profileImage;
  bool _isLoading = false;
  bool _isEditing = false;

  UserModel? _user;

  final List<String> _regions = ['Central', 'Eastern', 'Northern', 'Western'];
  final Map<String, List<String>> _districts = {
    'Central': ['Kampala', 'Wakiso', 'Mukono', 'Mpigi', 'Luwero', 'Masaka'],
    'Eastern': ['Jinja', 'Mbale', 'Soroti', 'Tororo', 'Iganga', 'Busia'],
    'Northern': ['Gulu', 'Lira', 'Arua', 'Kitgum', 'Moroto', 'Pader'],
    'Western': ['Mbarara', 'Fort Portal', 'Kabale', 'Kasese', 'Hoima', 'Masindi'],
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.currentUser;

    if (_user != null) {
      _nameController.text = _user!.fullName;
      _emailController.text = _user!.email;
      _phoneController.text = _user!.phone ?? '';
      _farmNameController.text = _user!.farmName ?? '';
      _farmDescriptionController.text = _user!.farmDescription ?? '';
      _addressController.text = _user!.address ?? '';
      _selectedRegion = _user!.region ?? '';
      _selectedDistrict = _user!.district ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _farmDescriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final profileData = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'farm_name': _farmNameController.text.trim(),
        'farm_description': _farmDescriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'region': _selectedRegion,
        'district': _selectedDistrict,
      };

      final success = await authProvider.updateProfile(
        profileData,
        profileImage: _profileImage,
      );

      if (!mounted) return;

      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          actions: [
            if (!_isEditing)
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
              )
            else
              TextButton(
                onPressed: () {
                  _loadUserData();
                  setState(() => _isEditing = false);
                },
                child: const Text('Cancel'),
              ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            _user = authProvider.currentUser;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Photo
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.grey200,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_user?.photoUrl != null
                                  ? NetworkImage(_user!.photoUrl!)
                                  : null) as ImageProvider?,
                          child: _profileImage == null &&
                                  _user?.photoUrl == null
                              ? Text(
                                  _user?.fullName.isNotEmpty == true
                                      ? _user!.fullName[0].toUpperCase()
                                      : 'F',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grey600,
                                  ),
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _user?.fullName ?? 'Farmer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _user?.isPremium == true
                            ? AppColors.secondaryOrange.withOpacity(0.1)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_user?.isPremium == true)
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.secondaryOrange,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            _user?.isPremium == true
                                ? 'Premium Farmer'
                                : 'Basic Farmer',
                            style: TextStyle(
                              fontSize: 12,
                              color: _user?.isPremium == true
                                  ? AppColors.secondaryOrange
                                  : AppColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Personal Information
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    prefixIcon: Icons.person,
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email,
                    enabled: false, // Email cannot be changed
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    prefixIcon: Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Farm Information
                  _buildSectionHeader('Farm Information'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _farmNameController,
                    label: 'Farm Name',
                    prefixIcon: Icons.agriculture,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _farmDescriptionController,
                    label: 'Farm Description',
                    prefixIcon: Icons.description,
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Location
                  _buildSectionHeader('Location'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Region',
                          value: _selectedRegion.isEmpty ? null : _selectedRegion,
                          items: _regions,
                          enabled: _isEditing,
                          onChanged: (value) {
                            setState(() {
                              _selectedRegion = value ?? '';
                              _selectedDistrict = '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          label: 'District',
                          value: _selectedDistrict.isEmpty
                              ? null
                              : _selectedDistrict,
                          items: _districts[_selectedRegion] ?? [],
                          enabled: _isEditing && _selectedRegion.isNotEmpty,
                          onChanged: (value) {
                            setState(() => _selectedDistrict = value ?? '');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                    prefixIcon: Icons.location_on,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  if (_isEditing)
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                    ),

                  if (!_isEditing) ...[
                    // Menu Items
                    _buildMenuItem(
                      icon: Icons.workspace_premium,
                      title: 'Upgrade to Premium',
                      subtitle: 'Get more features and priority listing',
                      onTap: () => Navigator.pushNamed(context, '/premium'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      icon: Icons.smart_toy,
                      title: 'AI Assistant',
                      subtitle: 'Get farming advice and market insights',
                      onTap: () => Navigator.pushNamed(context, '/ai-assistant'),
                    ),
                    _buildMenuItem(
                      icon: Icons.analytics,
                      title: 'Analytics',
                      subtitle: 'View your sales and performance data',
                      onTap: () => Navigator.pushNamed(context, '/farmer-analytics'),
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Manage your notification preferences',
                      onTap: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    _buildMenuItem(
                      icon: Icons.help,
                      title: 'Help & Support',
                      subtitle: 'Get help with using the app',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.info,
                      title: 'About',
                      subtitle: 'Learn more about AgriSupply',
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      isDestructive: true,
                      onTap: () => _showLogoutDialog(),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<AuthProvider>(
      builder: (context, provider, child) {
        final user = provider.currentUser;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Products', user?.totalProducts?.toString() ?? '0'),
              Container(height: 40, width: 1, color: AppColors.grey300),
              _buildStatItem('Orders', user?.totalOrders?.toString() ?? '0'),
              Container(height: 40, width: 1, color: AppColors.grey300),
              _buildStatItem(
                'Rating',
                user?.rating?.toStringAsFixed(1) ?? '0.0',
                suffix: '⭐',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, {String? suffix}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 4),
              Text(suffix, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required void Function(String?) onChanged,
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
            color: enabled ? AppColors.grey100 : AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text('Select $label'),
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withOpacity(0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.grey700,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.grey600,
            ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: isDestructive ? AppColors.error : AppColors.grey500,
          ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
