  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';

  import '../models/meal_plan.dart';
  import '../models/recipe.dart';
  import '../providers/meal_plan_provider.dart';
  import '../providers/shopping_list_provider.dart';
  import 'meal_slot_widget.dart';

  /// MealPlanScreen displays the weekly meal planner UI and handles meal assignment.
  ///
  /// Features:
  /// - Weekly planner with day selection
  /// - Assign meals to breakfast, lunch, dinner
  /// - Build custom meals
  /// - Generates shopping list from meal plans
  /// - Error handling and user feedback

  class MealPlanScreen extends StatefulWidget {
    const MealPlanScreen({super.key});

    @override
    State<MealPlanScreen> createState() => _MealPlanScreenState();
  }

  class _MealPlanScreenState extends State<MealPlanScreen> {
    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<MealPlanProvider>(context, listen: false);
        final dateForDay = _getDateForDay(provider.selectedDayIndex);
        provider.loadMealPlanForDate(dateForDay);
      });
    }

    DateTime _getDateForDay(int index) {
      final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
      return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: index));
    }

    /// Assigns a recipe to a meal slot and updates the shopping list.
    Future<void> _assignMeal(String mealType, Recipe recipe) async {
      try {
        final provider = Provider.of<MealPlanProvider>(context, listen: false);
        final shoppingProvider = Provider.of<ShoppingListProvider>(context, listen: false);
        final current = provider.mealPlanForSelectedDate;
        final selectedDayIndex = provider.selectedDayIndex;
        final normalizedDate = _getDateForDay(selectedDayIndex);
        final newPlan = MealPlan(
          id: current?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          date: normalizedDate,
          breakfast: mealType == 'breakfast' ? recipe : current?.breakfast,
          lunch: mealType == 'lunch' ? recipe : current?.lunch,
          dinner: mealType == 'dinner' ? recipe : current?.dinner,
        );
        await provider.addOrUpdateMealPlan(newPlan);
        await provider.loadMealPlans();
        await provider.loadMealPlanForDate(normalizedDate);
        // Aggregate week meal plans for shopping list
        final today = DateTime.now();
        final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
        final weekDates = List.generate(7, (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: i)));
        final weekMealPlans = provider.mealPlans.where((plan) {
          final d = DateTime(plan.date.year, plan.date.month, plan.date.day);
          return weekDates.any((wd) => wd.year == d.year && wd.month == d.month && wd.day == d.day);
        }).toList();
        await shoppingProvider.generateShoppingListFromMealPlans(weekMealPlans);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning meal: $e')),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      final provider = Provider.of<MealPlanProvider>(context);
      final mealPlan = provider.mealPlanForSelectedDate;
      final recipes = provider.recipes;
      final selectedDayIndex = provider.selectedDayIndex;

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
                  final dateForDay = _getDateForDay(index);
                  final selected = selectedDayIndex == index;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected ? Colors.green : Colors.grey[300],
                      foregroundColor: selected ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      provider.setSelectedDayIndex(index);
                      provider.loadMealPlanForDate(dateForDay);
                    },
                    child: Text(days[index]),
                  );
                }),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  MealSlotWidget(
                    title: 'Breakfast',
                    recipe: mealPlan?.breakfast,
                    recipes: recipes,
                    mealType: 'breakfast',
                    onAssign: _assignMeal,
                  ),
                  MealSlotWidget(
                    title: 'Lunch',
                    recipe: mealPlan?.lunch,
                    recipes: recipes,
                    mealType: 'lunch',
                    onAssign: _assignMeal,
                  ),
                  MealSlotWidget(
                    title: 'Dinner',
                    recipe: mealPlan?.dinner,
                    recipes: recipes,
                    mealType: 'dinner',
                    onAssign: _assignMeal,
                  ),
                  if (mealPlan != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await provider.deleteMealPlan(mealPlan.id);
                          await provider.loadMealPlanForDate(_getDateForDay(selectedDayIndex));
                          // Regenerate shopping list for the week
                          final today = DateTime.now();
                          final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
                          final weekDates = List.generate(7, (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: i)));
                          final weekMealPlans = provider.mealPlans.where((plan) {
                            final d = DateTime(plan.date.year, plan.date.month, plan.date.day);
                            return weekDates.any((wd) => wd.year == d.year && wd.month == d.month && wd.day == d.day);
                          }).toList();
                          final shoppingProvider = Provider.of<ShoppingListProvider>(context, listen: false);
                          await shoppingProvider.generateShoppingListFromMealPlans(weekMealPlans);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Meal plan deleted!')),
                          );
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
  }