import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_plan_provider.dart';
import '../models/meal_plan.dart';

class WeeklyMealsScreen extends StatelessWidget {
	const WeeklyMealsScreen({super.key});

	// Helper to get start of week (Sunday)
	DateTime _getStartOfWeek() {
		final now = DateTime.now();
		return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Weekly Meals')),
			body: Consumer<MealPlanProvider>(
				builder: (context, provider, _) {
					final startOfWeek = _getStartOfWeek();
					final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
					// Build list of dates for the week
					final weekDates = List.generate(7, (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: i)));
					// Map each date to its meal plan
					final weekPlans = weekDates.map((date) {
						return provider.mealPlans.firstWhere(
							(plan) => date.year == plan.date.year && date.month == plan.date.month && date.day == plan.date.day,
							orElse: () => MealPlan(id: '', date: date),
						);
					}).toList();

					return ListView.builder(
						itemCount: 7,
						itemBuilder: (context, i) {
							final plan = weekPlans[i];
							return Card(
								margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
								child: Padding(
									padding: const EdgeInsets.all(16.0),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(days[i], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
											const SizedBox(height: 8),
											_buildMealRow('Breakfast', plan.breakfast),
											_buildMealRow('Lunch', plan.lunch),
											_buildMealRow('Dinner', plan.dinner),
										],
									),
								),
							);
						},
					);
				},
			),
		);
	}

	Widget _buildMealRow(String label, dynamic recipe) {
		if (recipe == null) {
			return Text('$label: Not assigned', style: const TextStyle(color: Colors.grey));
		}
		return Text('$label: ${recipe.name}', style: const TextStyle(fontWeight: FontWeight.w500));
	}
}
