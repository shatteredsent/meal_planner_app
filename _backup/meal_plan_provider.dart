import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import '../services/recipe_firestore_service.dart';
import '../services/meal_plan_firestore_service.dart';

class MealPlanProvider with ChangeNotifier {
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

