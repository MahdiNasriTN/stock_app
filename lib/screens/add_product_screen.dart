import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/product_provider.dart';
import '../main.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _mainImage;
  bool _isSubmitting = false;

  // Each variant has: colorName, color, reference, image, and a list of rolls
  final List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    _addVariant();
  }

  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _mainImage = File(image.path);
      });
    }
  }

  Future<void> _pickVariantImage(int variantIndex) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _variants[variantIndex]['imageFile'] = File(image.path);
      });
    }
  }

  void _showColorPicker(int variantIndex) {
    Color currentColor = _variants[variantIndex]['color'] as Color;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModatexColors.surface,
        title: const Text(
          'Choisir une couleur',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              currentColor = color;
            },
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
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
            onPressed: () {
              setState(() {
                _variants[variantIndex]['color'] = currentColor;
              });
              Navigator.pop(context);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'colorName': TextEditingController(),
        'color': const Color(0xFF1A1A1A),
        'reference': TextEditingController(),
        'imageFile': null,
        'rolls': <Map<String, dynamic>>[],
      });
    });
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() {
        _variants[index]['colorName'].dispose();
        _variants[index]['reference'].dispose();
        _variants.removeAt(index);
      });
    }
  }

  void _addRoll(int variantIndex) {
    setState(() {
      _variants[variantIndex]['rolls'].add({
        'location': 'warehouse',
        'length': TextEditingController(text: '0'),
      });
    });
  }

  void _removeRoll(int variantIndex, int rollIndex) {
    setState(() {
      _variants[variantIndex]['rolls'][rollIndex]['length'].dispose();
      _variants[variantIndex]['rolls'].removeAt(rollIndex);
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate variants
    for (var variant in _variants) {
      if (variant['colorName'].text.isEmpty ||
          variant['reference'].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Veuillez remplir tous les champs des variantes'),
            backgroundColor: ModatexColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    // TODO: Upload images to server and get URLs
    // For now, using placeholder URLs
    final productData = {
      'name': _nameController.text,
      'mainImage': _mainImage != null
          ? 'https://via.placeholder.com/400x300'
          : 'https://via.placeholder.com/400x300',
      'variants': _variants
          .map(
            (v) => {
              'colorName': v['colorName'].text,
              'color': _colorToHex(v['color'] as Color),
              'reference': v['reference'].text,
              'image': v['imageFile'] != null ? 'https://via.placeholder.com/400x300' : null,
              'rolls': (v['rolls'] as List)
                  .map(
                    (r) => {
                      'location': r['location'],
                      'length': double.tryParse(r['length'].text) ?? 0,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final success = await provider.createProduct(productData);

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produit créé avec succès'),
          backgroundColor: ModatexColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Échec de la création du produit'),
          backgroundColor: ModatexColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModatexColors.background,
      appBar: AppBar(
        title: const Text('Nouveau Produit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'CRÉER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Main Image Section
            _buildSectionTitle('Image principale'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickMainImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: ModatexColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ModatexColors.divider,
                    width: 2,
                  ),
                ),
                child: _mainImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _mainImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: ModatexColors.accent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ajouter une image',
                            style: TextStyle(
                              color: ModatexColors.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Appuyez pour sélectionner',
                            style: TextStyle(
                              color: ModatexColors.accent.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Product Info Section
            _buildSectionTitle('Informations'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ModatexColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit',
                      hintText: 'Ex: Rideau Élégance',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le nom du produit';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Variants Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Couleurs / Variantes'),
                TextButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                  style: TextButton.styleFrom(
                    foregroundColor: ModatexColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ..._variants.asMap().entries.map((entry) {
              final variantIndex = entry.key;
              final variant = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ModatexColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Variant Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ModatexColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showColorPicker(variantIndex),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: variant['color'] as Color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ModatexColors.divider),
                              ),
                              child: const Icon(
                                Icons.colorize,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Couleur ${variantIndex + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Appuyez sur la couleur pour modifier',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ModatexColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_variants.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeVariant(variantIndex),
                              color: ModatexColors.error,
                              iconSize: 22,
                            ),
                        ],
                      ),
                    ),

                    // Variant Fields
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: variant['colorName'],
                                  decoration: const InputDecoration(
                                    labelText: 'Nom couleur',
                                    hintText: 'Ex: Noir',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: variant['reference'],
                                  decoration: const InputDecoration(
                                    labelText: 'Référence',
                                    hintText: 'Ex: REF-001',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Variant Image
                          GestureDetector(
                            onTap: () => _pickVariantImage(variantIndex),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: ModatexColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ModatexColors.divider),
                              ),
                              child: variant['imageFile'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.file(
                                        variant['imageFile'] as File,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: ModatexColors.accent,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Image variante (optionnel)',
                                          style: TextStyle(
                                            color: ModatexColors.accent,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Rolls section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ModatexColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.rotate_90_degrees_ccw,
                                          size: 18,
                                          color: ModatexColors.accent,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Rouleaux',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _addRoll(variantIndex),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: ModatexColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((variant['rolls'] as List).isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Aucun rouleau ajouté',
                                      style: TextStyle(
                                        color: ModatexColors.accent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ...(variant['rolls'] as List).asMap().entries.map((
                                  rollEntry,
                                ) {
                                  final rollIndex = rollEntry.key;
                                  final roll = rollEntry.value;

                                  return Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: ModatexColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: roll['location'],
                                            decoration: const InputDecoration(
                                              labelText: 'Emplacement',
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'warehouse',
                                                child: Text('Entrepôt'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'magasin',
                                                child: Text('Magasin'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                roll['location'] = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: roll['length'],
                                            decoration: const InputDecoration(
                                              labelText: 'Longueur (m)',
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: ModatexColors.error,
                                            size: 20,
                                          ),
                                          onPressed: () => _removeRoll(
                                            variantIndex,
                                            rollIndex,
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
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'CRÉER LE PRODUIT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ModatexColors.accent,
        letterSpacing: 1.5,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();

    for (var variant in _variants) {
      variant['colorName'].dispose();
      variant['reference'].dispose();
      for (var roll in variant['rolls']) {
        roll['length'].dispose();
      }
    }

    super.dispose();
  }
}
