import 'package:flutter/foundation.dart';

import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../services/recipe_firestore_service.dart';
import '../services/meal_plan_firestore_service.dart';

class MealPlanProvider with ChangeNotifier {
  int _selectedDayIndex = DateTime.now().weekday % 7;
  int get selectedDayIndex => _selectedDayIndex;
  void setSelectedDayIndex(int index) {
    _selectedDayIndex = index;
    notifyListeners();
  }

  final RecipeFirestoreService _recipeService = RecipeFirestoreService();
  final MealPlanFirestoreService _mealPlanService = MealPlanFirestoreService();

  List<Recipe> _recipes = [];
  List<MealPlan> _mealPlans = [];
  MealPlan? _mealPlanForSelectedDate;
  bool _isInitialized = false;

  MealPlanProvider() {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    await loadRecipes();
    await loadMealPlans();
    _isInitialized = true;
  }

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
    if (_mealPlanForSelectedDate != null && _isSameDate(_mealPlanForSelectedDate!.date, mealPlan.date)) {
      _mealPlanForSelectedDate = mealPlan;
    }
    notifyListeners();
  }

  Future<void> deleteMealPlan(String id) async {
    await _mealPlanService.deleteMealPlan(id);
    await loadMealPlans();
    if (_mealPlanForSelectedDate?.id == id) {
      _mealPlanForSelectedDate = null;
    }
    notifyListeners();
  }

  Future<void> clearAllMealPlans() async {
    final allPlans = await _mealPlanService.getAllMealPlans();
    for (var plan in allPlans) {
      await _mealPlanService.deleteMealPlan(plan.id);
    }
    _mealPlans.clear();
    _mealPlanForSelectedDate = null;
    notifyListeners();
  }

  /// Returns a map of day name to meal slots (breakfast, lunch, dinner) for the week.
  Map<String, Map<String, Recipe?>> getMealsByDay() {
    final Map<String, Map<String, Recipe?>> weeklyMeals = {
      'Sunday': {}, 'Monday': {}, 'Tuesday': {}, 'Wednesday': {}, 'Thursday': {}, 'Friday': {}, 'Saturday': {}
    };
    for (final plan in _mealPlans) {
      final weekday = plan.date.weekday % 7;
      final dayName = [
        'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
      ][weekday];
      weeklyMeals[dayName] = {
        'breakfast': plan.breakfast,
        'lunch': plan.lunch,
        'dinner': plan.dinner,
      };
    }
    return weeklyMeals;
  }

  Future<void> assignRecipeToMeal({
    required DateTime date,
    required Recipe recipe,
    required String mealType,
  }) async {
    MealPlan? existingPlan = await _mealPlanService.getMealPlanForDate(date);
    if (existingPlan == null) {
      final newPlan = MealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        breakfast: mealType == 'breakfast' ? recipe : null,
        lunch: mealType == 'lunch' ? recipe : null,
        dinner: mealType == 'dinner' ? recipe : null,
      );
      await addOrUpdateMealPlan(newPlan);
    } else {
      final updatedPlan = MealPlan(
        id: existingPlan.id,
        date: existingPlan.date,
        breakfast: mealType == 'breakfast' ? recipe : existingPlan.breakfast,
        lunch: mealType == 'lunch' ? recipe : existingPlan.lunch,
        dinner: mealType == 'dinner' ? recipe : existingPlan.dinner,
      );
      await addOrUpdateMealPlan(updatedPlan);
    }
  }

  Future<void> removeRecipeFromMeal({
    required DateTime date,
    required String mealType,
  }) async {
    MealPlan? existingPlan = await _mealPlanService.getMealPlanForDate(date);
    if (existingPlan != null) {
      final updatedPlan = MealPlan(
        id: existingPlan.id,
        date: existingPlan.date,
        breakfast: mealType == 'breakfast' ? null : existingPlan.breakfast,
        lunch: mealType == 'lunch' ? null : existingPlan.lunch,
        dinner: mealType == 'dinner' ? null : existingPlan.dinner,
      );
      if (updatedPlan.breakfast == null && updatedPlan.lunch == null && updatedPlan.dinner == null) {
        await deleteMealPlan(updatedPlan.id);
      } else {
        await addOrUpdateMealPlan(updatedPlan);
      }
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> refresh() async {
    await loadRecipes();
    await loadMealPlans();
    if (_mealPlanForSelectedDate != null) {
      await loadMealPlanForDate(_mealPlanForSelectedDate!.date);
    }
  }
}