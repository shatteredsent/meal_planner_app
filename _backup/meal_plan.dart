import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe.dart';

class MealPlan {
	final String id;
	final DateTime date;
	final Recipe? breakfast;
	final Recipe? lunch;
	final Recipe? dinner;

	MealPlan({
		required this.id,
		required this.date,
		this.breakfast,
		this.lunch,
		this.dinner,
	});

	factory MealPlan.fromJson(Map<String, dynamic> json, String id) {
		return MealPlan(
			id: id,
			date: (json['date'] as Timestamp).toDate(),
			breakfast: json['breakfast'] != null ? Recipe.fromJson(json['breakfast']) : null,
			lunch: json['lunch'] != null ? Recipe.fromJson(json['lunch']) : null,
			dinner: json['dinner'] != null ? Recipe.fromJson(json['dinner']) : null,
		);
	}

	Map<String, dynamic> toJson() {
		final normalizedDate = DateTime(date.year, date.month, date.day);
		return {
			'date': Timestamp.fromDate(normalizedDate),
			'breakfast': breakfast?.toJson(),
			'lunch': lunch?.toJson(),
			'dinner': dinner?.toJson(),
		};
	}
}
...existing code...
