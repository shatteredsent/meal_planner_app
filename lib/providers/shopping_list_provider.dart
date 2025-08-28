  import 'package:flutter/foundation.dart';
  import '../models/shopping_item.dart';
  import '../models/meal_plan.dart';
  import '../services/database_service.dart';

  class ShoppingListProvider with ChangeNotifier {
    final DatabaseService _databaseService = DatabaseService();
    List<ShoppingItem> _shoppingItems = [];

    List<ShoppingItem> get shoppingItems => _shoppingItems;
    List<ShoppingItem> get completedItems =>
        _shoppingItems.where((item) => item.isCompleted).toList();
    List<ShoppingItem> get pendingItems =>
        _shoppingItems.where((item) => !item.isCompleted).toList();

    // Expose items for AlexaService
    List<ShoppingItem> get items => _shoppingItems;

    Future<void> loadShoppingItems() async {
      _shoppingItems = await _databaseService.getShoppingItems();
      notifyListeners();
    }

    Future<void> addShoppingItem(String name, String category) async {
      final item = ShoppingItem(
        name: name,
        category: category,
        dateAdded: DateTime.now(),
      );
      await _databaseService.insertShoppingItem(item);
      await loadShoppingItems();
    }

    // Add item by ShoppingItem instance
    Future<void> addItem(ShoppingItem item) async {
      await _databaseService.insertShoppingItem(item);
      await loadShoppingItems();
    }

    Future<void> toggleItemCompletion(ShoppingItem item) async {
      final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
      await _databaseService.updateShoppingItem(updatedItem);
      await loadShoppingItems();
    }

    // Toggle completion by item name
    Future<void> toggleCompletionByName(String name) async {
      try {
        final item = _shoppingItems.firstWhere((i) => i.name == name);
        await toggleItemCompletion(item);
      } catch (e) {
        // Item not found, do nothing or handle as needed
      }
    }

    Future<void> deleteItem(int id) async {
      await _databaseService.deleteShoppingItem(id);
      await loadShoppingItems();
    }

    // Clear all completed items
    Future<void> clearCompletedItems() async {
      final completed = completedItems;
      for (var item in completed) {
        await _databaseService.deleteShoppingItem(item.id!);
      }
      await loadShoppingItems();
    }

    Future<void> generateShoppingListFromMealPlans(List<MealPlan> mealPlans) async {
      Set<String> allIngredients = {};
      for (var mealPlan in mealPlans) {
        if (mealPlan.breakfast != null) {
          allIngredients.addAll(mealPlan.breakfast!.ingredients);
        }
        if (mealPlan.lunch != null) {
          allIngredients.addAll(mealPlan.lunch!.ingredients);
        }
        if (mealPlan.dinner != null) {
          allIngredients.addAll(mealPlan.dinner!.ingredients);
        }
        if (mealPlan.snack != null) {
          allIngredients.addAll(mealPlan.snack!.ingredients);
        }
      }
      // Clear existing items and add new ones
      for (var item in _shoppingItems) {
        await _databaseService.deleteShoppingItem(item.id!);
      }
      for (var ingredient in allIngredients) {
        await addShoppingItem(ingredient, _categorizeIngredient(ingredient));
      }
    }

    String _categorizeIngredient(String ingredient) {
      ingredient = ingredient.toLowerCase();
      if (ingredient.contains('chicken') || ingredient.contains('beef') ||
          ingredient.contains('pork') || ingredient.contains('fish')) {
        return 'Meat & Seafood';
      }
      if (ingredient.contains('milk') || ingredient.contains('cheese') ||
          ingredient.contains('yogurt') || ingredient.contains('butter')) {
        return 'Dairy';
      }
      if (ingredient.contains('apple') || ingredient.contains('banana') ||
          ingredient.contains('berry') || ingredient.contains('orange')) {
        return 'Produce';
      }
      if (ingredient.contains('bread') || ingredient.contains('pasta') ||
          ingredient.contains('rice') || ingredient.contains('cereal')) {
        return 'Grains';
      }
      return 'Other';
    }
  }