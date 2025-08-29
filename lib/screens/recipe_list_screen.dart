import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/recipe_card.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'add_recipe_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewRecipe(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search only
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<MealPlanProvider>(
              builder: (context, provider, child) {
                final recipes = provider.recipes;
                final filteredRecipes = recipes.where((recipe) {
                  return recipe.name.toLowerCase().contains(_searchQuery) ||
                         recipe.description.toLowerCase().contains(_searchQuery);
                }).toList();

                // Group recipes by normalized category
                final Map<String, List<Recipe>> grouped = <String, List<Recipe>>{};
                for (var recipe in filteredRecipes) {
                  final cat = recipe.category.trim();
                  final normalizedCat = cat.isNotEmpty ? cat[0].toUpperCase() + cat.substring(1).toLowerCase() : 'Other';
                  grouped.putIfAbsent(normalizedCat, () => []).add(recipe);
                }

                if (grouped.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No recipes found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (var entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(entry.key, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      ...entry.value.map((recipe) => RecipeCard(
                        recipe: recipe,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(recipe: recipe),
                          ),
                        ),
                      )),
                    ]
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addNewRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
    builder: (context) => const AddRecipeScreen(),
      ),
    ).then((_) {
      // Reload recipes after adding new one
      context.read<MealPlanProvider>().loadRecipes();
    });
  }
}