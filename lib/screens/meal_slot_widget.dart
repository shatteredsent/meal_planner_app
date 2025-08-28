import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'build_meal_dialog.dart';

/// Widget for displaying a meal slot and assigning recipes.
class MealSlotWidget extends StatelessWidget {
  final String title;
  final Recipe? recipe;
  final List<Recipe> recipes;
  final String mealType;
  final Future<void> Function(String, Recipe) onAssign;

  const MealSlotWidget({
    super.key,
    required this.title,
    required this.recipe,
    required this.recipes,
    required this.mealType,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(title),
        subtitle: recipe != null ? Text(recipe!.name) : const Text('No recipe assigned'),
        trailing: PopupMenuButton<int>(
          icon: const Icon(Icons.edit),
          itemBuilder: (context) {
            return [
              const PopupMenuItem<int>(
                value: -1,
                child: Text('Build a Meal'),
              ),
              ...recipes.asMap().entries.map((entry) => PopupMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value.name),
                  ))
            ];
          },
          onSelected: (selectedIndex) {
            if (selectedIndex == -1) {
              showDialog(
                context: context,
                builder: (context) => BuildMealDialog(
                  mealType: mealType,
                  onAssign: onAssign,
                ),
              );
            } else {
              onAssign(mealType, recipes[selectedIndex]);
            }
          },
        ),
      ),
    );
  }
}
