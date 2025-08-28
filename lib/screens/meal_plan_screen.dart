import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/shopping_list_provider.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMealPlanForDay(_selectedDay!);
  }

  void _loadMealPlanForDay(DateTime date) {
    Provider.of<MealPlanProvider>(context, listen: false)
        .loadMealPlanForDate(date);
  }

  void _assignMeal(String mealType, Recipe recipe) async {
    final provider = Provider.of<MealPlanProvider>(context, listen: false);
    final shoppingProvider = Provider.of<ShoppingListProvider>(context, listen: false);
    final current = provider.mealPlanForSelectedDate;
    final newPlan = MealPlan(
      id: current?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDay!,
      breakfast: mealType == 'breakfast' ? recipe : current?.breakfast,
      lunch: mealType == 'lunch' ? recipe : current?.lunch,
      dinner: mealType == 'dinner' ? recipe : current?.dinner,
    );
    await provider.addOrUpdateMealPlan(newPlan);
    await provider.loadMealPlanForDate(_selectedDay!);
    // Update shopping list for the week
    await shoppingProvider.generateShoppingListFromMealPlans(provider.mealPlans);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MealPlanProvider>(context);
    final mealPlan = provider.mealPlanForSelectedDate;
    final recipes = provider.recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                final selected = _selectedDay?.weekday == ((index + 1) % 7 == 0 ? 7 : (index + 1));
                final dateForDay = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7)).add(Duration(days: index));
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected ? Colors.green : Colors.grey[300],
                    foregroundColor: selected ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDay = dateForDay;
                    });
                    _loadMealPlanForDay(dateForDay);
                  },
                  child: Text(days[index]),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildMealSlot('Breakfast', mealPlan?.breakfast, recipes, 'breakfast'),
                _buildMealSlot('Lunch', mealPlan?.lunch, recipes, 'lunch'),
                _buildMealSlot('Dinner', mealPlan?.dinner, recipes, 'dinner'),
                if (mealPlan != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await provider.deleteMealPlan(mealPlan.id);
                        await provider.loadMealPlanForDate(_selectedDay!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Meal plan deleted!')),
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Meal Plan for this day'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlot(String title, Recipe? recipe, List<Recipe> recipes, String mealType) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(title),
        subtitle: recipe != null ? Text(recipe.name) : const Text('No recipe assigned'),
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
              _showBuildMealDialog(context, mealType);
            } else {
              _assignMeal(mealType, recipes[selectedIndex]);
            }
          },
        ),
      ),
    );
  }

  void _showBuildMealDialog(BuildContext context, String mealType) {
    // Static hardcoded lists
    final meats = [
      'Beef',
      'Chicken',
      'Ham',
      'Pork Kabobs',
      'Pork Chops',
      'Pork Loin',
      'Ribs',
      'Boston Butt',
    ];
    final vegetables = [
      'Asparagus',
      'Beans',
      'Broccoli',
      'Brussel Sprouts',
      'Cabbage (Coleslaw)',
      'Carrots',
      'Cauliflower',
      'Corn',
      'Green Beans',
      'Greens',
      'Mushrooms',
      'Okra',
      'Potatoes (Sweet)',
      'Salad',
      'Spinach',
      'Squash',
      'Zucchini',
    ];
    String? selectedMeat;
    List<String> selectedVegetables = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      ? () {
                          // Create a Recipe object for the built meal
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
                          _assignMeal(mealType, builtRecipe);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Create Meal'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}