import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  final bool _isLoading = false;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const _UsersTab(),
    const _OrdersTab(),
    const _SettingsTab(),
  ];

  @override
  Widget build(final BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (final index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.grey500,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(final BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.primaryGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back, Admin!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  context,
                  title: 'Total Users',
                  value: '2,456',
                  icon: Icons.people,
                  color: AppColors.info,
                  change: '+12%',
                  isPositive: true,
                ),
                _buildStatCard(
                  context,
                  title: 'Total Orders',
                  value: '1,234',
                  icon: Icons.receipt_long,
                  color: AppColors.primaryGreen,
                  change: '+8%',
                  isPositive: true,
                ),
                _buildStatCard(
                  context,
                  title: 'Revenue',
                  value: '45.6M',
                  icon: Icons.payments,
                  color: AppColors.secondaryOrange,
                  change: '+15%',
                  isPositive: true,
                ),
                _buildStatCard(
                  context,
                  title: 'Products',
                  value: '567',
                  icon: Icons.inventory_2,
                  color: AppColors.success,
                  change: '+5%',
                  isPositive: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue Chart
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles()),
                    rightTitles: const AxisTitles(sideTitles: SideTitles()),
                    topTitles: const AxisTitles(sideTitles: SideTitles()),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (final value, final meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.grey600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 4),
                        FlSpot(2, 3.5),
                        FlSpot(3, 5),
                        FlSpot(4, 4.5),
                        FlSpot(5, 6),
                      ],
                      isCurved: true,
                      color: AppColors.primaryGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryGreen.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.person_add,
                    label: 'Add User',
                    color: AppColors.info,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.category,
                    label: 'Categories',
                    color: AppColors.primaryGreen,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.analytics,
                    label: 'Reports',
                    color: AppColors.secondaryOrange,
                    onTap: () => Navigator.pushNamed(context, '/admin-analytics'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            _buildActivityItem(
              icon: Icons.person_add,
              title: 'New farmer registered',
              subtitle: 'John Mukasa from Kampala',
              time: '2 min ago',
              color: AppColors.info,
            ),
            _buildActivityItem(
              icon: Icons.shopping_cart,
              title: 'New order placed',
              subtitle: 'Order #12345 - UGX 150,000',
              time: '15 min ago',
              color: AppColors.primaryGreen,
            ),
            _buildActivityItem(
              icon: Icons.add_box,
              title: 'New product listed',
              subtitle: 'Fresh Tomatoes by Sarah Nakato',
              time: '1 hour ago',
              color: AppColors.secondaryOrange,
            ),
            _buildActivityItem(
              icon: Icons.star,
              title: 'New premium subscription',
              subtitle: 'Peter Ochieng upgraded to Premium',
              time: '2 hours ago',
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    final BuildContext context, {
    required final String title,
    required final String value,
    required final IconData icon,
    required final Color color,
    required final String change,
    required final bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    final BuildContext context, {
    required final IconData icon,
    required final String label,
    required final Color color,
    required final VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required final IconData icon,
    required final String title,
    required final String subtitle,
    required final String time,
    required final Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}

// Users Tab
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // User Types
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildUserTypeChip('All', true),
                const SizedBox(width: 8),
                _buildUserTypeChip('Farmers', false),
                const SizedBox(width: 8),
                _buildUserTypeChip('Buyers', false),
                const SizedBox(width: 8),
                _buildUserTypeChip('Admins', false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: _buildUserItem,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeChip(final String label, final bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryGreen : AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.grey700,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildUserItem(final BuildContext context, final int index) {
    final isEven = index % 2 == 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEven ? AppColors.primaryGreen : AppColors.info,
          child: Text(
            isEven ? 'F' : 'B',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('User ${index + 1}'),
        subtitle: Text(isEven ? 'Farmer • Kampala' : 'Buyer • Jinja'),
        trailing: PopupMenuButton<String>(
          onSelected: (final value) {},
          itemBuilder: (final context) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

// Orders Tab
class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.primaryGreen,
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Confirmed'),
                Tab(text: 'Delivered'),
                Tab(text: 'Cancelled'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: List.generate(5, (final index) => _buildOrdersList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (final context, final index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#ORD-${10000 + index}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Buyer: John Doe • Farmer: Jane Smith',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UGX 150,000',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    Text(
                      '2 hours ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Settings Tab
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context,
            title: 'General',
            items: [
              _buildSettingsItem(
                icon: Icons.category,
                title: 'Categories',
                onTap: () {},
              ),
              _buildSettingsItem(
                icon: Icons.location_on,
                title: 'Regions & Districts',
                onTap: () {},
              ),
              _buildSettingsItem(
                icon: Icons.payment,
                title: 'Payment Methods',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            title: 'App Settings',
            items: [
              _buildSettingsItem(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {},
              ),
              _buildSettingsItem(
                icon: Icons.security,
                title: 'Security',
                onTap: () {},
              ),
              _buildSettingsItem(
                icon: Icons.backup,
                title: 'Backup & Restore',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            title: 'Account',
            items: [
              _buildSettingsItem(
                icon: Icons.person,
                title: 'Admin Profile',
                onTap: () {},
              ),
              _buildSettingsItem(
                icon: Icons.logout,
                title: 'Logout',
                isDestructive: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (final context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final authProvider =
                                Provider.of<AuthProvider>(context, listen: false);
                            authProvider.signOut();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (final route) => false,
                            );
                          },
                          child: const Text('Logout',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    final BuildContext context, {
    required final String title,
    required final List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required final IconData icon,
    required final String title,
    required final VoidCallback onTap,
    final bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.grey700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? AppColors.error : AppColors.grey500,
      ),
      onTap: onTap,
    );
  }
}
