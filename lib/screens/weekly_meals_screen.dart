import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_plan_provider.dart';

class WeeklyMealsScreen extends StatelessWidget {
  final List<String> daysOfWeek = const [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);
    final weeklyMeals = mealPlanProvider.getMealsByDay(); // Implement this method if needed

    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Meals'),
      ),
      body: ListView.builder(
        itemCount: daysOfWeek.length,
        itemBuilder: (context, index) {
          final day = daysOfWeek[index];
          final meals = weeklyMeals[day] ?? {};
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day, style: Theme.of(context).textTheme.titleLarge),
                  Divider(),
                  ...['breakfast', 'lunch', 'dinner'].map((mealType) {
                    final recipe = meals[mealType];
                    if (recipe != null) {
                      return ListTile(
                        title: Text(recipe.name),
                        subtitle: Text(mealType[0].toUpperCase() + mealType.substring(1)),
                      );
                    }
                    return SizedBox.shrink();
                  }).toList(),
                  if (meals.values.every((v) => v == null))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No meals planned', style: TextStyle(color: Colors.grey)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
