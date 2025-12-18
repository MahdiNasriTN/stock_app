import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await Future.wait([
      provider.fetchStats(),
      provider.fetchProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF9333EA),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<ProductProvider>(
          builder: (context, provider, child) {
            if (provider.loading && provider.stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = provider.stats;
            final products = provider.products;
            final lowStockProducts = products
                .where((p) => p.totalStock <= p.lowStockThreshold)
                .toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Products',
                          value: '${stats?.totalProducts ?? 0}',
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Stock',
                          value: '${stats?.totalStock ?? 0}',
                          icon: Icons.warehouse,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StatCard(
                    title: 'Low Stock Alerts',
                    value: '${stats?.lowStockCount ?? 0}',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                    fullWidth: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          label: 'Add Product',
                          icon: Icons.add_box,
                          color: const Color(0xFF9333EA),
                          onTap: () {
                            Navigator.pushNamed(context, '/add-product');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickActionButton(
                          label: 'View Stock',
                          icon: Icons.inventory,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.pushNamed(context, '/stock');
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category Breakdown
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (stats?.categoryBreakdown != null && stats!.categoryBreakdown.isNotEmpty)
                    ...stats.categoryBreakdown.map((category) {
                      return _CategoryCard(
                        category: category.category,
                        count: category.count,
                      );
                    }).toList()
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No categories available'),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Low Stock Alerts
                  Text(
                    'Low Stock Alerts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (lowStockProducts.isNotEmpty)
                    ...lowStockProducts.map((product) {
                      return _LowStockCard(product: product);
                    }).toList()
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.check_circle, size: 48, color: Colors.green),
                              SizedBox(height: 8),
                              Text('All products are well stocked!'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final int count;

  const _CategoryCard({
    Key? key,
    required this.category,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF9333EA).withOpacity(0.1),
          child: const Icon(Icons.category, color: Color(0xFF9333EA)),
        ),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Chip(
          label: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF9333EA),
        ),
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final Product product;

  const _LowStockCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.mainImage,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.grey),
              );
            },
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Stock: ${product.totalStock}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              const Text(
                'Low',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          Navigator.pushNamed(context, '/product-detail', arguments: product.id);
        },
      ),
    );
  }
}
