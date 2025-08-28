import 'package:flutter/material.dart';
import '../models/recipe.dart';

/// Dialog for building a custom meal.
class BuildMealDialog extends StatefulWidget {
  final String mealType;
  final Future<void> Function(String, Recipe) onAssign;

  const BuildMealDialog({
    super.key,
    required this.mealType,
    required this.onAssign,
  });

  @override
  State<BuildMealDialog> createState() => _BuildMealDialogState();
}

class _BuildMealDialogState extends State<BuildMealDialog> {
  String? selectedMeat;
  List<String> selectedVegetables = [];

  final List<String> meats = [
    'Beef', 'Chicken', 'Ham', 'Pork Kabobs', 'Pork Chops', 'Pork Loin', 'Ribs', 'Boston Butt',
  ];
  final List<String> vegetables = [
    'Asparagus', 'Beans', 'Broccoli', 'Brussel Sprouts', 'Cabbage (Coleslaw)', 'Carrots', 'Cauliflower',
    'Corn', 'Green Beans', 'Greens', 'Mushrooms', 'Okra', 'Potatoes (Sweet)', 'Salad', 'Spinach', 'Squash', 'Zucchini',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Build a Meal'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose 1 Meat:'),
            ...meats.map((meat) => RadioListTile<String>(
                  title: Text(meat),
                  value: meat,
                  groupValue: selectedMeat,
                  onChanged: (value) {
                    setState(() {
                      selectedMeat = value;
                    });
                  },
                )),
            const SizedBox(height: 16),
            const Text('Choose 2 Vegetables:'),
            ...vegetables.map((veg) => CheckboxListTile(
                  title: Text(veg),
                  value: selectedVegetables.contains(veg),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true && selectedVegetables.length < 2) {
                        selectedVegetables.add(veg);
                      } else if (checked == false) {
                        selectedVegetables.remove(veg);
                      }
                    });
                  },
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedMeat != null && selectedVegetables.length == 2
              ? () async {
                  final builtRecipe = Recipe(
                    name: '$selectedMeat with ${selectedVegetables[0]} & ${selectedVegetables[1]}',
                    description: 'Custom meal built by user',
                    ingredients: [selectedMeat!, selectedVegetables[0], selectedVegetables[1]],
                    instructions: [],
                    prepTime: 0,
                    cookTime: 0,
                    servings: 1,
                    imageUrl: null,
                    category: 'Custom Meal',
                  );
                  await widget.onAssign(widget.mealType, builtRecipe);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Create Meal'),
        ),
      ],
    );
  }
}
