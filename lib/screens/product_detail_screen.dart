import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../main.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  Set<String> _expandedVariants = {};

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

  void _toggleVariantExpansion(String variantId) {
    setState(() {
      if (_expandedVariants.contains(variantId)) {
        _expandedVariants.remove(variantId);
      } else {
        _expandedVariants.add(variantId);
      }
    });
  }

  void _showProductMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ModatexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ModatexColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ModatexColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_outlined, color: ModatexColors.primary),
                ),
                title: const Text(
                  'Modifier le produit',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Changer le nom ou l\'image',
                  style: TextStyle(color: ModatexColors.accent, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditProductDialog();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ModatexColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline, color: ModatexColors.error),
                ),
                title: Text(
                  'Supprimer le produit',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ModatexColors.error,
                  ),
                ),
                subtitle: Text(
                  'Cette action est irréversible',
                  style: TextStyle(color: ModatexColors.accent, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteProduct();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProductDialog() {
    final nameController = TextEditingController(text: _product!.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModatexColors.surface,
        title: const Text(
          'Modifier le produit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom du produit',
                prefixIcon: Icon(Icons.edit_outlined, color: ModatexColors.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: ModatexColors.accent)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Le nom ne peut pas être vide'),
                    backgroundColor: ModatexColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final provider = Provider.of<ProductProvider>(context, listen: false);
              final success = await provider.updateProduct(
                widget.productId,
                {'name': nameController.text},
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Produit modifié avec succès'),
                    backgroundColor: ModatexColors.success,
                  ),
                );
                _loadProduct();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Échec de la modification'),
                    backgroundColor: ModatexColors.error,
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModatexColors.surface,
        title: const Text(
          'Supprimer le produit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${_product!.name}" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: ModatexColors.accent)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<ProductProvider>(context, listen: false);
              final success = await provider.deleteProduct(widget.productId);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Produit supprimé avec succès'),
                    backgroundColor: ModatexColors.success,
                  ),
                );
                Navigator.pop(context); // Go back to products list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Échec de la suppression'),
                    backgroundColor: ModatexColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModatexColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAddRollDialog(Variant variant) {
    final lengthController = TextEditingController();
    String location = 'warehouse';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: ModatexColors.surface,
          title: Text(
            'Ajouter un rouleau',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ModatexColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _parseColor(variant.color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      variant.colorName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: location,
                decoration: InputDecoration(
                  labelText: 'Emplacement',
                  prefixIcon: Icon(Icons.location_on_outlined, color: ModatexColors.accent),
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
                decoration: InputDecoration(
                  labelText: 'Longueur (mètres)',
                  prefixIcon: Icon(Icons.straighten, color: ModatexColors.accent),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: ModatexColors.accent)),
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
                final provider = Provider.of<ProductProvider>(
                  context,
                  listen: false,
                );
                final success = await provider.addRoll(
                  productId: widget.productId,
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
                  _loadProduct();
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

  void _showAddVariantDialog() {
    final colorNameController = TextEditingController();
    Color selectedColor = const Color(0xFF1A1A1A);
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ModatexColors.surface,
          title: const Text(
            'Ajouter une couleur',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: colorNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la couleur',
                    prefixIcon: Icon(Icons.label_outline, color: ModatexColors.accent),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: ModatexColors.surface,
                        title: const Text('Choisir une couleur'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: selectedColor,
                            onColorChanged: (color) {
                              setDialogState(() => selectedColor = color);
                            },
                            pickerAreaHeightPercent: 0.8,
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Valider'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ModatexColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ModatexColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ModatexColors.divider),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Couleur sélectionnée',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ModatexColors.accent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.color_lens_outlined, color: ModatexColors.accent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: referenceController,
                  decoration: InputDecoration(
                    labelText: 'Référence',
                    prefixIcon: Icon(Icons.tag, color: ModatexColors.accent),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: ModatexColors.accent)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (colorNameController.text.isEmpty ||
                    referenceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Veuillez remplir tous les champs'),
                      backgroundColor: ModatexColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                final colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';
                final provider = Provider.of<ProductProvider>(
                  context,
                  listen: false,
                );
                final success = await provider.addVariant(widget.productId, {
                  'colorName': colorNameController.text,
                  'color': colorHex,
                  'reference': referenceController.text,
                });

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Couleur ajoutée avec succès'),
                      backgroundColor: ModatexColors.success,
                    ),
                  );
                  _loadProduct();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Échec de l\'ajout de la couleur'),
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

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: ModatexColors.background,
        appBar: AppBar(title: const Text('Détails du produit')),
        body: Center(
          child: CircularProgressIndicator(color: ModatexColors.primary),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: ModatexColors.background,
        appBar: AppBar(title: const Text('Détails du produit')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: ModatexColors.accent),
              const SizedBox(height: 16),
              Text(
                'Produit non trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: ModatexColors.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ModatexColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: ModatexColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _product!.mainImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: ModatexColors.secondary,
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: ModatexColors.accent,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert, size: 20),
                ),
                onPressed: _showProductMenu,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header
                  Text(
                    _product!.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: ModatexColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ModatexColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.inventory_2_outlined,
                            label: 'Stock Total',
                            value: '${_product!.totalStock} m',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: ModatexColors.divider,
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.palette_outlined,
                            label: 'Couleurs',
                            value: '${_product!.variants.length}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Variants Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COULEURS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ModatexColors.accent,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_product!.variants.length} variante(s)',
                            style: TextStyle(
                              fontSize: 14,
                              color: ModatexColors.accent,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showAddVariantDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: ModatexColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Ajouter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Variants List
                  if (_product!.variants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: ModatexColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 48,
                              color: ModatexColors.accent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune couleur disponible',
                              style: TextStyle(color: ModatexColors.accent),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._product!.variants.map((variant) {
                      final isExpanded = _expandedVariants.contains(variant.id);
                      return _VariantCard(
                        variant: variant,
                        isExpanded: isExpanded,
                        onToggleExpand: () =>
                            _toggleVariantExpansion(variant.id),
                        onAddRoll: () => _showAddRollDialog(variant),
                        onDeleteRoll: (rollId) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: ModatexColors.surface,
                              title: const Text(
                                'Supprimer le rouleau',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              content: const Text(
                                'Êtes-vous sûr de vouloir supprimer ce rouleau ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                            final provider = Provider.of<ProductProvider>(
                              context,
                              listen: false,
                            );
                            final success = await provider.deleteRoll(
                              productId: widget.productId,
                              variantId: variant.id,
                              rollId: rollId,
                            );
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Rouleau supprimé'),
                                  backgroundColor: ModatexColors.success,
                                ),
                              );
                              _loadProduct();
                            }
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: ModatexColors.surface,
                              title: const Text(
                                'Supprimer la couleur',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              content: Text(
                                'Êtes-vous sûr de vouloir supprimer ${variant.colorName} ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                            final provider = Provider.of<ProductProvider>(
                              context,
                              listen: false,
                            );
                            final success = await provider.deleteVariant(
                              widget.productId,
                              variant.id,
                            );
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Couleur supprimée'),
                                  backgroundColor: ModatexColors.success,
                                ),
                              );
                              _loadProduct();
                            }
                          }
                        },
                      );
                    }).toList(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ModatexColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: ModatexColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ModatexColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: ModatexColors.accent),
        ),
      ],
    );
  }
}

class _VariantCard extends StatelessWidget {
  final Variant variant;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddRoll;
  final Function(String) onDeleteRoll;
  final VoidCallback onDelete;

  const _VariantCard({
    Key? key,
    required this.variant,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onAddRoll,
    required this.onDeleteRoll,
    required this.onDelete,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ModatexColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(variant.color),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ModatexColors.divider),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.colorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: ModatexColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Réf: ${variant.reference}',
                          style: TextStyle(
                            fontSize: 13,
                            color: ModatexColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${variant.totalStock} m',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: ModatexColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: variant.rolls.isEmpty
                              ? ModatexColors.error.withOpacity(0.1)
                              : ModatexColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${variant.rolls.length} rouleau(x)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: variant.rolls.isEmpty
                                ? ModatexColors.error
                                : ModatexColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ModatexColors.accent,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: ModatexColors.divider),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ModatexColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ROULEAUX',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ModatexColors.accent,
                          letterSpacing: 1,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onAddRoll,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ModatexColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: ModatexColors.divider),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 16, color: ModatexColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ajouter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: ModatexColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ModatexColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: ModatexColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (variant.rolls.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      child: Text(
                        'Aucun rouleau',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ModatexColors.accent),
                      ),
                    )
                  else
                    ...variant.rolls.map((roll) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ModatexColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: roll.location == 'warehouse'
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                roll.location == 'warehouse'
                                    ? Icons.warehouse_outlined
                                    : Icons.storefront_outlined,
                                color: roll.location == 'warehouse'
                                    ? Colors.blue
                                    : Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roll.location == 'warehouse'
                                        ? 'Entrepôt'
                                        : 'Magasin',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: ModatexColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${roll.id.substring(0, 8)}...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ModatexColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${roll.length} m',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: ModatexColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => onDeleteRoll(roll.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: ModatexColors.error,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
