import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan.dart';

class MealPlanFirestoreService {
  final CollectionReference mealPlansCollection =
      FirebaseFirestore.instance.collection('meal_plans');

  Future<void> addOrUpdateMealPlan(MealPlan mealPlan) async {
    await mealPlansCollection.doc(mealPlan.id).set(mealPlan.toJson());
  }

  Future<MealPlan?> getMealPlanForDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final query = await mealPlansCollection
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return MealPlan.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<List<MealPlan>> getAllMealPlans() async {
    final snapshot = await mealPlansCollection.get();
    return snapshot.docs
        .map((doc) => MealPlan.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> deleteMealPlan(String id) async {
    await mealPlansCollection.doc(id).delete();
  }
}
