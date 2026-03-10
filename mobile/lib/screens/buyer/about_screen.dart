import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About AgriSupply'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.agriculture,
                  size: 80,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Name & Version
            Center(
              child: Column(
                children: [
                  Text(
                    'AgriSupply',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Farm Connect System',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Mission Section
            _buildSection(
              context,
              icon: Icons.rocket_launch,
              title: 'Our Mission',
              content:
                  'Connecting farmers directly with buyers across Uganda to create a more efficient, transparent, and profitable agricultural marketplace.',
            ),
            const SizedBox(height: 24),

            // Features Section
            _buildSection(
              context,
              icon: Icons.stars,
              title: 'What We Offer',
              child: Column(
                children: [
                  _buildFeatureItem(
                    Icons.shopping_cart,
                    'Direct Marketplace',
                    'Buy fresh produce directly from farmers',
                  ),
                  _buildFeatureItem(
                    Icons.phone_android,
                    'Mobile Money Integration',
                    'Secure payments via MTN & Airtel Money',
                  ),
                  _buildFeatureItem(
                    Icons.local_shipping,
                    'Fast Delivery',
                    'Get your orders delivered to your doorstep',
                  ),
                  _buildFeatureItem(
                    Icons.eco,
                    'Organic Options',
                    'Access to organic and pesticide-free produce',
                  ),
                  _buildFeatureItem(
                    Icons.smart_toy,
                    'AI Assistant',
                    'Get farming advice powered by AI',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Section
            _buildSection(
              context,
              icon: Icons.contact_mail,
              title: 'Contact Us',
              child: Column(
                children: [
                  _buildContactItem(
                    Icons.email,
                    'Email',
                    'support@agrisupply.ug',
                    () => _launchUrl('mailto:support@agrisupply.ug'),
                  ),
                  _buildContactItem(
                    Icons.phone,
                    'Phone',
                    '+256 700 000 000',
                    () => _launchUrl('tel:+256700000000'),
                  ),
                  _buildContactItem(
                    Icons.language,
                    'Website',
                    'www.agrisupply.ug',
                    () => _launchUrl('https://www.agrisupply.ug'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Social Media
            _buildSection(
              context,
              icon: Icons.share,
              title: 'Follow Us',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialButton(
                    Icons.facebook,
                    'facebook',
                    () => _launchUrl('https://facebook.com/agrisupply'),
                  ),
                  _buildSocialButton(
                    Icons.camera_alt,
                    'instagram',
                    () => _launchUrl('https://instagram.com/agrisupply'),
                  ),
                  _buildSocialButton(
                    Icons.tag,
                    'twitter',
                    () => _launchUrl('https://twitter.com/agrisupply'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Legal Links
            Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => _showTerms(context),
                    child: const Text('Terms & Conditions'),
                  ),
                  TextButton(
                    onPressed: () => _showPrivacy(context),
                    child: const Text('Privacy Policy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Copyright
            Center(
              child: Text(
                '© ${DateTime.now().year} AgriSupply. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? content,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: AppColors.grey700,
                  ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String platform, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 28),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By using AgriSupply, you agree to our terms and conditions...\n\n'
            '1. Account Responsibility\n'
            '2. Product Listings\n'
            '3. Transactions\n'
            '4. Dispute Resolution\n'
            '5. Privacy\n\n'
            'For full terms, visit www.agrisupply.ug/terms',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We respect your privacy and protect your personal data...\n\n'
            '1. Data Collection\n'
            '2. Data Usage\n'
            '3. Data Protection\n'
            '4. Third-Party Services\n'
            '5. Your Rights\n\n'
            'For full policy, visit www.agrisupply.ug/privacy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
