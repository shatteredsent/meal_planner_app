import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../services/recipe_firestore_service.dart';
import '../services/meal_plan_firestore_service.dart';

class MealPlanProvider with ChangeNotifier {
	/// Returns a deduplicated list of ingredients from all assigned/planned meals
	List<String> get assignedIngredients {
		final Set<String> ingredients = {};
		for (final plan in _mealPlans) {
			if (plan.breakfast != null) {
				ingredients.addAll(plan.breakfast!.ingredients);
			}
			if (plan.lunch != null) {
				ingredients.addAll(plan.lunch!.ingredients);
			}
			if (plan.dinner != null) {
				ingredients.addAll(plan.dinner!.ingredients);
			}
		}
		return ingredients.toList();
	}
	bool _isSameDate(DateTime a, DateTime b) {
		return a.year == b.year && a.month == b.month && a.day == b.day;
	}
	// Persist the selected day index (0 = Sunday, 6 = Saturday)
	int _selectedDayIndex = DateTime.now().weekday % 7; // Default to today (Sunday=0)

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
    
		// Load existing data instead of clearing it
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
    
		// Update the selected date meal plan if it matches
		if (_mealPlanForSelectedDate != null && 
				_isSameDate(_mealPlanForSelectedDate!.date, mealPlan.date)) {
			_mealPlanForSelectedDate = mealPlan;
		}
		notifyListeners();
	}

	Future<void> deleteMealPlan(String id) async {
		await _mealPlanService.deleteMealPlan(id);
		await loadMealPlans();
    
		// Clear selected meal plan if it was deleted
		if (_mealPlanForSelectedDate?.id == id) {
			_mealPlanForSelectedDate = null;
		}
		notifyListeners();
	}

	// Only clear all meal plans when explicitly requested (not on init)
	Future<void> clearAllMealPlans() async {
		final allPlans = await _mealPlanService.getAllMealPlans();
		for (var plan in allPlans) {
			await _mealPlanService.deleteMealPlan(plan.id);
		}
		_mealPlans.clear();
		_mealPlanForSelectedDate = null;
		notifyListeners();
	}

	// Helper method to assign a recipe to a specific meal slot
	Future<void> assignRecipeToMeal({
		required DateTime date,
		required Recipe recipe,
		required String mealType, // 'breakfast', 'lunch', or 'dinner'
	}) async {
		// Get existing meal plan for the date or create new one
		MealPlan? existingPlan = await _mealPlanService.getMealPlanForDate(date);
    
		if (existingPlan == null) {
			// Create new meal plan
			final newPlan = MealPlan(
				id: DateTime.now().millisecondsSinceEpoch.toString(),
				date: date,
				breakfast: mealType == 'breakfast' ? recipe : null,
				lunch: mealType == 'lunch' ? recipe : null,
				dinner: mealType == 'dinner' ? recipe : null,
			);
			await addOrUpdateMealPlan(newPlan);
		} else {
			// Update existing meal plan
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

	// Helper method to remove recipe from a meal slot
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
			
			// If all meals are null, delete the meal plan entirely
			if (updatedPlan.breakfast == null && 
					updatedPlan.lunch == null && 
					updatedPlan.dinner == null) {
				await deleteMealPlan(updatedPlan.id);
			} else {
				await addOrUpdateMealPlan(updatedPlan);
			}
		}
	}

	// Force refresh all data
	Future<void> refresh() async {
		await loadRecipes();
		await loadMealPlans();
		if (_mealPlanForSelectedDate != null) {
			await loadMealPlanForDate(_mealPlanForSelectedDate!.date);
		}
	}
}