import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/recipe_card.dart';

class RecipeSelectionScreen extends StatelessWidget {
  final String mealType;

  const RecipeSelectionScreen({super.key, required this.mealType});

  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select a $mealType Recipe'),
      ),
      body: mealPlanProvider.recipes.isEmpty
          ? const Center(
              child: Text(
                'No recipes available. Add some from the Recipes tab!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: mealPlanProvider.recipes.length,
              itemBuilder: (context, index) {
                final recipe = mealPlanProvider.recipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.pop(context, recipe);
                  },
                );
              },
            ),
    );
  }
}