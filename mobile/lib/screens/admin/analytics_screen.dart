import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/theme.dart';
import '../../widgets/loading_overlay.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = false;
  String _selectedPeriod = 'This Month';
  int _touchedIndex = -1;

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  @override
  Widget build(final BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                underline: const SizedBox.shrink(),
                items: _periods.map((final period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (final value) {
                  if (value != null) setState(() => _selectedPeriod = value);
                },
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _isLoading = true);
            await Future.delayed(const Duration(seconds: 1));
            setState(() => _isLoading = false);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Revenue Overview
              _buildSectionHeader('Revenue Overview'),
              const SizedBox(height: 12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Revenue',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          currencyFormat.format(45600000),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.trending_up,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '+15.3%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRevenueMetric('Orders', '1,234'),
                        _buildRevenueMetric('Avg. Order', 'UGX 37K'),
                        _buildRevenueMetric('Commission', 'UGX 2.3M'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Revenue Chart
              _buildSectionHeader('Revenue Trend'),
              const SizedBox(height: 12),
              Container(
                height: 250,
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
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 10,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.grey900,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItem: (final group, final groupIndex, final rod, final rodIndex) {
                          return BarTooltipItem(
                            '${_getMonthName(group.x)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: 'UGX ${(rod.toY * 5).toInt()}M',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (final value, final meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getMonthName(value.toInt()),
                                style: const TextStyle(
                                  color: AppColors.grey600,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (final value, final meta) {
                            return Text(
                              '${(value * 5).toInt()}M',
                              style: const TextStyle(
                                color: AppColors.grey500,
                                fontSize: 10,
                              ),
                            );
                          },
                          reservedSize: 32,
                        ),
                      ),
                      topTitles:
                          const AxisTitles(),
                      rightTitles:
                          const AxisTitles(),
                    ),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (final value) => const FlLine(
                        color: AppColors.grey200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _makeBarGroup(0, 6),
                      _makeBarGroup(1, 7),
                      _makeBarGroup(2, 5),
                      _makeBarGroup(3, 8),
                      _makeBarGroup(4, 7.5),
                      _makeBarGroup(5, 9),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User Analytics
              _buildSectionHeader('User Growth'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'New Farmers',
                      value: '156',
                      change: '+12%',
                      icon: Icons.agriculture,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'New Buyers',
                      value: '423',
                      change: '+18%',
                      icon: Icons.shopping_cart,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Premium Users',
                      value: '89',
                      change: '+25%',
                      icon: Icons.star,
                      color: AppColors.secondaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Active Users',
                      value: '1.2K',
                      change: '+8%',
                      icon: Icons.people,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Distribution
              _buildSectionHeader('Sales by Category'),
              const SizedBox(height: 12),
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
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (final event, final pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildPieSections(),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Vegetables', AppColors.primaryGreen, '35%'),
                        _buildLegendItem('Fruits', AppColors.secondaryOrange, '25%'),
                        _buildLegendItem('Grains', AppColors.info, '20%'),
                        _buildLegendItem('Dairy', AppColors.warning, '12%'),
                        _buildLegendItem('Others', AppColors.grey500, '8%'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top Products
              _buildSectionHeader('Top Products'),
              const SizedBox(height: 12),
              ..._buildTopProducts(currencyFormat),
              const SizedBox(height: 24),

              // Regional Distribution
              _buildSectionHeader('Orders by Region'),
              const SizedBox(height: 12),
              Container(
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
                  children: [
                    _buildRegionBar('Central', 0.45, 456),
                    const SizedBox(height: 12),
                    _buildRegionBar('Eastern', 0.25, 253),
                    const SizedBox(height: 12),
                    _buildRegionBar('Western', 0.18, 182),
                    const SizedBox(height: 12),
                    _buildRegionBar('Northern', 0.12, 121),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(final String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildRevenueMetric(final String label, final String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required final String title,
    required final String value,
    required final String change,
    required final IconData icon,
    required final Color color,
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
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

  BarChartGroupData _makeBarGroup(final int x, final double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primaryGreen,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  String _getMonthName(final int index) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return months[index];
  }

  List<PieChartSectionData> _buildPieSections() {
    final data = [
      (35.0, AppColors.primaryGreen),
      (25.0, AppColors.secondaryOrange),
      (20.0, AppColors.info),
      (12.0, AppColors.warning),
      (8.0, AppColors.grey500),
    ];

    return data.asMap().entries.map((final entry) {
      final isTouched = entry.key == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;

      return PieChartSectionData(
        color: entry.value.$2,
        value: entry.value.$1,
        title: '',
        radius: radius,
      );
    }).toList();
  }

  Widget _buildLegendItem(final String label, final Color color, final String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopProducts(final NumberFormat currencyFormat) {
    final products = [
      ('Fresh Tomatoes', '🍅', 234, 1560000),
      ('Matooke', '🍌', 189, 1250000),
      ('Fresh Milk', '🥛', 156, 980000),
      ('Sweet Potatoes', '🍠', 143, 720000),
      ('Beans', '🫘', 128, 640000),
    ];

    return products.asMap().entries.map((final entry) {
      final index = entry.key;
      final product = entry.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  product.$2,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.$1,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${product.$3} orders',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(product.$4),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRegionBar(final String region, final double percentage, final int orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              region,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$orders orders',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
