import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../services/recipe_firestore_service.dart';
import '../services/meal_plan_firestore_service.dart';

class MealPlanProvider with ChangeNotifier {
  final RecipeFirestoreService _recipeService = RecipeFirestoreService();
  final MealPlanFirestoreService _mealPlanService = MealPlanFirestoreService();

  List<Recipe> _recipes = [];
  List<MealPlan> _mealPlans = [];
  MealPlan? _mealPlanForSelectedDate;

  List<Recipe> get recipes => _recipes;
  List<MealPlan> get mealPlans => _mealPlans;
  MealPlan? get mealPlanForSelectedDate => _mealPlanForSelectedDate;

  Future<void> loadRecipes() async {
    _recipes = await _recipeService.getRecipes();
    notifyListeners();
  }

  Future<void> loadMealPlans() async {
    _mealPlans = await _mealPlanService.getAllMealPlans();
    notifyListeners();
  }

  Future<void> loadMealPlanForDate(DateTime date) async {
    _mealPlanForSelectedDate = await _mealPlanService.getMealPlanForDate(date);
    notifyListeners();
  }

  Future<void> addOrUpdateMealPlan(MealPlan mealPlan) async {
    await _mealPlanService.addOrUpdateMealPlan(mealPlan);
    await loadMealPlans();
  }

  Future<void> deleteMealPlan(String id) async {
    await _mealPlanService.deleteMealPlan(id);
    await loadMealPlans();
    _mealPlanForSelectedDate = null;
    notifyListeners();
  }
}