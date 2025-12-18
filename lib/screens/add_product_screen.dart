import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialController = TextEditingController();
  final _widthController = TextEditingController();
  final _imageController = TextEditingController();
  final _tagsController = TextEditingController();
  final _lowStockThresholdController = TextEditingController(text: '10');
  
  String _selectedCategory = 'Voilage';
  bool _isFeatured = false;
  
  final List<String> _categories = [
    'Voilage',
    'Occultant',
    'Semi-Occultant',
    'Thermique',
    'Décoratif',
    'Lin',
    'Velours',
    'Autre'
  ];
  
  final List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    // Add one default variant
    _addVariant();
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'name': TextEditingController(),
        'colorName': TextEditingController(),
        'color': TextEditingController(text: '#9333ea'),
        'stockQuantity': TextEditingController(text: '0'),
      });
    });
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() {
        _variants[index]['name'].dispose();
        _variants[index]['colorName'].dispose();
        _variants[index]['color'].dispose();
        _variants[index]['stockQuantity'].dispose();
        _variants.removeAt(index);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate variants
    for (var variant in _variants) {
      if (variant['name'].text.isEmpty || variant['colorName'].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all variant fields')),
        );
        return;
      }
    }

    final productData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'material': _materialController.text,
      'width': double.parse(_widthController.text),
      'mainImage': _imageController.text.isEmpty ? 'https://via.placeholder.com/400x300' : _imageController.text,
      'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'isFeatured': _isFeatured,
      'lowStockThreshold': int.parse(_lowStockThresholdController.text),
      'variants': _variants.map((v) => {
        'name': v['name'].text,
        'colorName': v['colorName'].text,
        'color': v['color'].text,
        'stockQuantity': int.parse(v['stockQuantity'].text),
      }).toList(),
    };

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final success = await provider.createProduct(productData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to create product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF9333EA),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _materialController,
                            decoration: const InputDecoration(
                              labelText: 'Material',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.texture),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _widthController,
                      decoration: const InputDecoration(
                        labelText: 'Width (ft)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter width';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter image URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                        hintText: 'e.g., premium, outdoor, waterproof',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lowStockThresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Threshold',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning_amber),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter threshold';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Featured Product'),
                      subtitle: const Text('Show this product in featured section'),
                      value: _isFeatured,
                      activeColor: const Color(0xFF9333EA),
                      onChanged: (value) {
                        setState(() => _isFeatured = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Variants Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Variants',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addVariant,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._variants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final variant = entry.value;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Variant ${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (_variants.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeVariant(index),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: variant['name'],
                                decoration: const InputDecoration(
                                  labelText: 'Variant Name',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: variant['colorName'],
                                      decoration: const InputDecoration(
                                        labelText: 'Color Name',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: variant['color'],
                                      decoration: const InputDecoration(
                                        labelText: 'Color Code',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: variant['stockQuantity'],
                                decoration: const InputDecoration(
                                  labelText: 'Initial Stock Quantity',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Create Product',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _materialController.dispose();
    _widthController.dispose();
    _imageController.dispose();
    _tagsController.dispose();
    _lowStockThresholdController.dispose();
    
    for (var variant in _variants) {
      variant['name'].dispose();
      variant['colorName'].dispose();
      variant['color'].dispose();
      variant['stockQuantity'].dispose();
    }
    
    super.dispose();
  }
}
