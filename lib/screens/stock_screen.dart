import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filterType = 'all'; // all, low, out
  String? _selectedCategory;

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
      provider.fetchProducts(),
      provider.fetchCategories(),
    ]);
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;
    
    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Filter by stock level
    if (_filterType == 'low') {
      filtered = filtered.where((p) => p.totalStock > 0 && p.totalStock <= p.lowStockThreshold).toList();
    } else if (_filterType == 'out') {
      filtered = filtered.where((p) => p.totalStock == 0).toList();
    }
    
    return filtered;
  }

  void _showQuickUpdateDialog(Product product, Variant variant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick Update: ${variant.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${variant.stockQuantity}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateStock(product.id, variant.id, 'add', 10);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('+10'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (variant.stockQuantity >= 10) {
                      await _updateStock(product.id, variant.id, 'remove', 10);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient stock')),
                      );
                    }
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text('-10'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCustomUpdateDialog(product, variant);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)),
            child: const Text('Custom'),
          ),
        ],
      ),
    );
  }

  void _showCustomUpdateDialog(Product product, Variant variant) {
    final quantityController = TextEditingController();
    String operation = 'add';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Custom Update: ${variant.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: operation,
                decoration: const InputDecoration(
                  labelText: 'Operation',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'add', child: Text('Add Stock')),
                  DropdownMenuItem(value: 'remove', child: Text('Remove Stock')),
                  DropdownMenuItem(value: 'set', child: Text('Set Stock')),
                ],
                onChanged: (value) {
                  setState(() => operation = value!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid quantity')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _updateStock(product.id, variant.id, operation, quantity);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStock(String productId, String variantId, String operation, int quantity) async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final success = await provider.updateStock(
      productId: productId,
      variantId: variantId,
      operation: operation,
      quantity: quantity,
      reason: 'Quick stock update',
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update stock')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Stock Management', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF9333EA),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: const Color(0xFF9333EA),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Stock Level Filters
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: 'All Stock',
                        isSelected: _filterType == 'all',
                        onTap: () => setState(() => _filterType = 'all'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'Low Stock',
                        isSelected: _filterType == 'low',
                        onTap: () => setState(() => _filterType = 'low'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'Out of Stock',
                        isSelected: _filterType == 'out',
                        onTap: () => setState(() => _filterType = 'out'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category Filter
                Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Filter by Category',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...provider.categories.map((cat) {
                          final categoryName = (cat['_id'] ?? cat['category'] ?? '').toString();
                          return DropdownMenuItem(
                            value: categoryName,
                            child: Text(categoryName),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.loading && provider.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredProducts = _getFilteredProducts(provider.products);

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _StockProductCard(
                        product: product,
                        onQuickUpdate: (variant) => _showQuickUpdateDialog(product, variant),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF9333EA) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StockProductCard extends StatelessWidget {
  final Product product;
  final Function(Variant) onQuickUpdate;

  const _StockProductCard({
    Key? key,
    required this.product,
    required this.onQuickUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.totalStock <= product.lowStockThreshold;
    final isOutOfStock = product.totalStock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Product Header
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.mainImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(product.category),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total: ${product.totalStock}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isOutOfStock ? Colors.red : (isLowStock ? Colors.orange : Colors.green),
                  ),
                ),
                if (isLowStock || isOutOfStock)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock ? Colors.red[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out' : 'Low',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Variants
          if (product.variants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Variants:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...product.variants.map((variant) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(variant.color.replaceFirst('#', '0xff')),
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variant.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  variant.colorName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${variant.stockQuantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: variant.stockQuantity == 0 
                                  ? Colors.red 
                                  : (variant.stockQuantity <= 5 ? Colors.orange : Colors.green),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => onQuickUpdate(variant),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Update', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
