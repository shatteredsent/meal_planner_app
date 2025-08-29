import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_firestore_service.dart';

class AddRecipeScreen extends StatefulWidget { 
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Dinner';
  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
  final List<TextEditingController> _instructionControllers = [TextEditingController()];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _imageUrlController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _addInstruction() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructionControllers[index].dispose();
      _instructionControllers.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    print('Save button pressed');
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    final ingredients = _ingredientControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final instructions = _instructionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final prepTime = int.tryParse(_prepTimeController.text);
    final cookTime = int.tryParse(_cookTimeController.text);
    final servings = int.tryParse(_servingsController.text);
    print('Parsed values: prepTime=$prepTime, cookTime=$cookTime, servings=$servings');
    if (prepTime == null || cookTime == null || servings == null) {
      print('Invalid number input');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers for prep time, cook time, and servings.')),
      );
      return;
    }
    final recipe = Recipe(
      name: _nameController.text,
      description: _descriptionController.text,
      ingredients: ingredients,
      instructions: instructions,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: servings,
      imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      category: _selectedCategory,
    );
    print('Recipe object created:');
    print(recipe.toJson());
    try {
      await RecipeFirestoreService().addRecipe(recipe);
      print('addRecipe completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe saved to cloud!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Recipe'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveRecipe,
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
            _buildSectionTitle('Basic Information'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter recipe name';
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
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
                    controller: _cookTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Ingredients'),
            ..._ingredientControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Ingredient ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (index == 0 && (value == null || value.isEmpty)) {
                            return 'At least one ingredient required';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: _ingredientControllers.length > 1
                          ? () => _removeIngredient(index)
                          : null,
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Instructions'),
            ..._instructionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Instruction ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (index == 0 && (value == null || value.isEmpty)) {
                            return 'At least one instruction required';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: _instructionControllers.length > 1
                          ? () => _removeInstruction(index)
                          : null,
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addInstruction,
              icon: const Icon(Icons.add),
              label: const Text('Add Instruction'),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saveRecipe,
              icon: const Icon(Icons.save),
              label: const Text('Save Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
