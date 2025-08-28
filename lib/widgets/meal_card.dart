import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/meal_plan_provider.dart';
import '../screens/recipe_selection_screen.dart';

class MealCard extends StatelessWidget {
  final String title;
  final String mealType;
  final Recipe? recipe;

  const MealCard({
    super.key,
    required this.title,
    required this.mealType,
    this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);

    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          recipe?.name ?? 'No meal selected',
          style: TextStyle(
            fontStyle: recipe == null ? FontStyle.italic : null,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          final selectedRecipe = await Navigator.push<Recipe?>(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeSelectionScreen(mealType: mealType),
            ),
          );

          if (selectedRecipe != null) {
            // Removed: addOrUpdateMealPlan
          }
        },
      ),
    );
  }
}