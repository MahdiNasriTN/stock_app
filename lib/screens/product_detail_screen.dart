import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final product = await provider.fetchProductById(widget.productId);
    setState(() {
      _product = product;
      _loading = false;
    });
  }

  void _showUpdateStockDialog(Variant variant) {
    final quantityController = TextEditingController();
    String operation = 'add';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Stock: ${variant.name}'),
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
                final provider = Provider.of<ProductProvider>(context, listen: false);
                final success = await provider.updateStock(
                  productId: widget.productId,
                  variantId: variant.id,
                  operation: operation,
                  quantity: quantity,
                  reason: 'Manual adjustment',
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock updated successfully')),
                  );
                  _loadProduct();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update stock')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVariantDialog() {
    final nameController = TextEditingController();
    final colorNameController = TextEditingController();
    final colorController = TextEditingController(text: '#9333ea');
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Variant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Variant Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: colorNameController,
                decoration: const InputDecoration(
                  labelText: 'Color Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Color Code (e.g., #9333ea)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Stock',
                  border: OutlineInputBorder(),
                ),
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
            onPressed: () async {
              if (nameController.text.isEmpty || colorNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final stock = int.tryParse(stockController.text) ?? 0;
              Navigator.pop(context);

              final provider = Provider.of<ProductProvider>(context, listen: false);
              final success = await provider.addVariant(
                widget.productId,
                {
                  'name': nameController.text,
                  'colorName': colorNameController.text,
                  'color': colorController.text,
                  'stockQuantity': stock,
                },
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Variant added successfully')),
                );
                _loadProduct();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to add variant')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          backgroundColor: const Color(0xFF9333EA),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          backgroundColor: const Color(0xFF9333EA),
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF9333EA),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                _product!.mainImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 100, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _product!.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_product!.isFeatured)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.star, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(_product!.category),
                        backgroundColor: const Color(0xFF9333EA).withOpacity(0.1),
                        labelStyle: const TextStyle(color: Color(0xFF9333EA)),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_product!.material),
                        backgroundColor: Colors.grey[200],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.straighten,
                          label: 'Width',
                          value: '${_product!.width}" ft',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.inventory,
                          label: 'Total Stock',
                          value: '${_product!.totalStock}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Variants Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Variants',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddVariantDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Variants List
                  if (_product!.variants.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No variants available')),
                      ),
                    )
                  else
                    ..._product!.variants.map((variant) {
                      return _VariantCard(
                        variant: variant,
                        onUpdateStock: () => _showUpdateStockDialog(variant),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Variant'),
                              content: Text('Are you sure you want to delete ${variant.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final provider = Provider.of<ProductProvider>(context, listen: false);
                            final success = await provider.deleteVariant(
                              widget.productId,
                              variant.id,
                            );
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Variant deleted')),
                              );
                              _loadProduct();
                            }
                          }
                        },
                      );
                    }).toList(),
                  
                  const SizedBox(height: 16),
                  
                  // Tags
                  if (_product!.tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _product!.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF9333EA)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final Variant variant;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;

  const _VariantCard({
    Key? key,
    required this.variant,
    required this.onUpdateStock,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(
                  int.parse(variant.color.replaceFirst('#', '0xff')),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    variant.colorName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stock: ${variant.stockQuantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: const Color(0xFF9333EA),
                      onPressed: onUpdateStock,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
