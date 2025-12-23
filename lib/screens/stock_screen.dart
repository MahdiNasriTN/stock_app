import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../main.dart';
import '../services/api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filterType = 'all'; // all, in, out
  String? _selectedCategory;
  Set<String> _expandedProducts = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (!provider.loadingMore && provider.hasMore) {
        provider.loadMoreProducts();
      }
    }
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


    // Filter by stock level
    if (_filterType == 'in') {
      filtered = filtered
          .where((p) => p.totalStock > 0)
          .toList();
    } else if (_filterType == 'out') {
      filtered = filtered.where((p) => p.totalStock == 0).toList();
    }

    return filtered;
  }

  void _toggleProductExpansion(String productId) {
    setState(() {
      if (_expandedProducts.contains(productId)) {
        _expandedProducts.remove(productId);
      } else {
        _expandedProducts.add(productId);
      }
    });
  }

  void _showAddRollDialog(Product product, Variant variant) {
    final lengthController = TextEditingController();
    String location = 'warehouse';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: ModatexColors.surface,
          title: Text(
            'Ajouter un rouleau',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                variant.colorName,
                style: TextStyle(
                  color: ModatexColors.accent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: location,
                decoration: const InputDecoration(
                  labelText: 'Emplacement',
                ),
                items: const [
                  DropdownMenuItem(value: 'warehouse', child: Text('Entrepôt')),
                  DropdownMenuItem(value: 'magasin', child: Text('Magasin')),
                ],
                onChanged: (value) {
                  setState(() => location = value!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Longueur (mètres)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: ModatexColors.accent),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final length = double.tryParse(lengthController.text);
                if (length == null || length <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Veuillez entrer une longueur valide'),
                      backgroundColor: ModatexColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                final provider =
                    Provider.of<ProductProvider>(context, listen: false);
                final success = await provider.addRoll(
                  productId: product.id,
                  variantId: variant.id,
                  location: location,
                  length: length,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Rouleau ajouté avec succès'),
                      backgroundColor: ModatexColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Échec de l\'ajout du rouleau'),
                      backgroundColor: ModatexColors.error,
                    ),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRoll(
      Product product, Variant variant, Roll roll) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModatexColors.surface,
        title: const Text(
          'Supprimer le rouleau',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Supprimer ce rouleau de ${roll.length}m (${roll.location == 'warehouse' ? 'Entrepôt' : 'Magasin'}) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: ModatexColors.accent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModatexColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final success = await provider.deleteRoll(
        productId: product.id,
        variantId: variant.id,
        rollId: roll.id,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rouleau supprimé'),
            backgroundColor: ModatexColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModatexColors.background,
      appBar: AppBar(
        title: const Text('Gestion du Stock'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: ModatexColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Stock Level Filters
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: 'Tout',
                        isSelected: _filterType == 'all',
                        onTap: () => setState(() => _filterType = 'all'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'In Stock',
                        isSelected: _filterType == 'in',
                        onTap: () => setState(() => _filterType = 'in'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'Épuisé',
                        isSelected: _filterType == 'out',
                        onTap: () => setState(() => _filterType = 'out'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: ModatexColors.primary,
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.loading && provider.products.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ModatexColors.primary,
                      ),
                    );
                  }

                  final filteredProducts =
                      _getFilteredProducts(provider.products);

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: ModatexColors.accent),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun produit trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: ModatexColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredProducts.length) {
                        // Loading indicator at the bottom
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              color: ModatexColors.primary,
                            ),
                          ),
                        );
                      }
                      final product = filteredProducts[index];
                      final isExpanded =
                          _expandedProducts.contains(product.id);
                      return _StockProductCard(
                        product: product,
                        isExpanded: isExpanded,
                        onToggleExpand: () =>
                            _toggleProductExpansion(product.id),
                        onAddRoll: (variant) =>
                            _showAddRollDialog(product, variant),
                        onDeleteRoll: (variant, roll) =>
                            _deleteRoll(product, variant, roll),
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
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }}

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? ModatexColors.primary : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StockProductCard extends StatelessWidget {
  final Product product;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final Function(Variant) onAddRoll;
  final Function(Variant, Roll) onDeleteRoll;

  const _StockProductCard({
    Key? key,
    required this.product,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onAddRoll,
    required this.onDeleteRoll,
  }) : super(key: key);

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.totalStock <= product.lowStockThreshold;
    final isOutOfStock = product.totalStock == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ModatexColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Product Header
          InkWell(
            onTap: onToggleExpand,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.getMainImageUrl(ApiService.baseUrl),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 56,
                          height: 56,
                          color: ModatexColors.background,
                          child: Icon(
                            Icons.image_outlined,
                            color: ModatexColors.accent,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: ModatexColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.variants.length} couleur${product.variants.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ModatexColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.totalStock} m',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: isOutOfStock
                              ? ModatexColors.error
                              : (isLowStock ? ModatexColors.warning : ModatexColors.success),
                        ),
                      ),
                      if (isLowStock || isOutOfStock)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? ModatexColors.error.withOpacity(0.1)
                                : ModatexColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOutOfStock ? 'ÉPUISÉ' : 'BAS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isOutOfStock
                                  ? ModatexColors.error
                                  : ModatexColors.warning,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: ModatexColors.accent,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Variants Section
          if (isExpanded) ...[
            Container(
              height: 1,
              color: ModatexColors.divider,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COULEURS & ROULEAUX',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: ModatexColors.accent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...product.variants.map((variant) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ModatexColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Variant Header
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _parseColor(variant.color),
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: ModatexColors.divider),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        variant.colorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: ModatexColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Réf: ${variant.reference}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ModatexColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${variant.totalStock} m',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: variant.totalStock == 0
                                        ? ModatexColors.error
                                        : ModatexColors.success,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => onAddRoll(variant),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: ModatexColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rolls List
                          if (variant.rolls.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: ModatexColors.surface,
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                              ),
                              child: Column(
                                children: variant.rolls.map((roll) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: ModatexColors.divider),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 44),
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: roll.location == 'warehouse'
                                                ? Colors.blue.withOpacity(0.1)
                                                : Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            roll.location == 'warehouse'
                                                ? Icons.warehouse_outlined
                                                : Icons.store_outlined,
                                            size: 14,
                                            color: roll.location == 'warehouse'
                                                ? Colors.blue
                                                : Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          roll.location == 'warehouse'
                                              ? 'Entrepôt'
                                              : 'Magasin',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: ModatexColors.textPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${roll.length} m',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: ModatexColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              onDeleteRoll(variant, roll),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: ModatexColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          if (variant.rolls.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Aucun rouleau',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ModatexColors.accent,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
