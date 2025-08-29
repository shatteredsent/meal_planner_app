// Backup of ShoppingListProvider as of August 28, 2025 (v2)

import 'package:flutter/foundation.dart';
import '../models/shopping_item.dart';
import '../models/meal_plan.dart';
import '../services/database_service.dart';

class ShoppingListProvider with ChangeNotifier {
  Future<void> deleteItem(int id) async {
    _shoppingItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> toggleItemCompletion(ShoppingItem item) async {
    final idx = _shoppingItems.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _shoppingItems[idx] = item.copyWith(isCompleted: !item.isCompleted);
      notifyListeners();
    }
  }

  Future<void> addShoppingItem(String name, String category) async {
    final item = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch, // Always assign a unique id
      name: name,
      category: category,
      dateAdded: DateTime.now(),
    );
    _shoppingItems.add(item);
    notifyListeners();
  }

  Future<void> toggleCompletionByName(String name) async {
    try {
      final idx = _shoppingItems.indexWhere((i) => i.name == name);
      if (idx != -1) {
        final item = _shoppingItems[idx];
        _shoppingItems[idx] = item.copyWith(isCompleted: !item.isCompleted);
        notifyListeners();
      }
    } catch (e) {
      // Item not found, do nothing
    }
  }

  Future<void> clearCompletedItems() async {
    _shoppingItems.removeWhere((item) => item.isCompleted);
    notifyListeners();
  }

  final DatabaseService _databaseService = DatabaseService();
  List<ShoppingItem> _shoppingItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  ShoppingListProvider();

  List<ShoppingItem> get shoppingItems => _shoppingItems;
  List<ShoppingItem> get completedItems =>
      _shoppingItems.where((item) => item.isCompleted).toList();
  List<ShoppingItem> get pendingItems =>
      _shoppingItems.where((item) => !item.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ShoppingItem> get items => _shoppingItems;
  Map<String, List<ShoppingItem>> get itemsByCategory {
    final Map<String, List<ShoppingItem>> categorizedItems = {};
    for (var item in _shoppingItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }
    return categorizedItems;
  }
  int get pendingItemsCount => pendingItems.length;
  Map<String, int> getItemsCountByCategory() {
    final counts = <String, int>{};
    for (var item in _shoppingItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }
  double get completionPercentage {
    if (_shoppingItems.isEmpty) return 0.0;
    return completedItems.length / _shoppingItems.length;
  }
  void _setLoading(bool loading) {
    _isLoading = loading;
  }
  void _setError(String? error) {
    _errorMessage = error;
  }
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  Future<void> loadShoppingItems() async {
    _setLoading(true);
    _setError(null);
    try {
      _shoppingItems = await _databaseService.getShoppingItems();
    } catch (e) {
      _setError('Failed to load shopping items: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  List<ShoppingItem> searchItems(String query) {
    if (query.isEmpty) return _shoppingItems;
    final lowerQuery = query.toLowerCase();
    return _shoppingItems.where((item) =>
        item.name.toLowerCase().contains(lowerQuery) ||
        item.category.toLowerCase().contains(lowerQuery)).toList();
  }
  void sortItems({required String sortBy, bool ascending = true}) {
    switch (sortBy.toLowerCase()) {
      case 'name':
        _shoppingItems.sort((a, b) => ascending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case 'category':
        _shoppingItems.sort((a, b) => ascending
            ? a.category.compareTo(b.category)
            : b.category.compareTo(a.category));
        break;
      case 'date':
        _shoppingItems.sort((a, b) => ascending
            ? a.dateAdded.compareTo(b.dateAdded)
            : b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'completed':
        _shoppingItems.sort((a, b) => ascending
            ? a.isCompleted.toString().compareTo(b.isCompleted.toString())
            : b.isCompleted.toString().compareTo(a.isCompleted.toString()));
        break;
    }
    notifyListeners();
  }
  Future<void> generateShoppingListFromMealPlans(List<MealPlan> mealPlans) async {
    _setLoading(true);
    _setError(null);
    try {
      final Map<String, int> ingredientCounts = {};
      for (var mealPlan in mealPlans) {
        for (var recipe in [mealPlan.breakfast, mealPlan.lunch, mealPlan.dinner]) {
          if (recipe != null && recipe.ingredients.isNotEmpty) {
            for (var ingredient in recipe.ingredients) {
              final cleanIngredient = ingredient.trim();
              if (cleanIngredient.isNotEmpty) {
                ingredientCounts[cleanIngredient] = (ingredientCounts[cleanIngredient] ?? 0) + 1;
              }
            }
          }
        }
      }
      if (ingredientCounts.isEmpty) {
        _setError('No ingredients found in the selected meal plans');
      }
      _shoppingItems.clear();
      final newItems = ingredientCounts.entries.map((entry) {
        final itemName = entry.value > 1 ? '${entry.key} (${entry.value}x)' : entry.key;
        return ShoppingItem(
          id: DateTime.now().millisecondsSinceEpoch,
          name: itemName,
          category: _categorizeIngredient(entry.key),
          dateAdded: DateTime.now(),
        );
      }).toList();
      _shoppingItems.addAll(newItems);
    } catch (e) {
      _setError('Failed to generate shopping list: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  Future<void> clearAndRefreshShoppingList() async {
    _shoppingItems.clear();
    await loadShoppingItems();
    notifyListeners();
  }
  String _categorizeIngredient(String ingredient) {
    final lowerIngredient = ingredient.toLowerCase().trim();
    final categoryMaps = {
      'Meat & Seafood': ['chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'shrimp', 'turkey', 'lamb', 'crab', 'lobster', 'bacon', 'ham', 'sausage'],
      'Dairy': ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'sour cream', 'cottage cheese', 'mozzarella', 'cheddar', 'parmesan', 'eggs'],
      'Produce': ['apple', 'banana', 'berry', 'orange', 'tomato', 'onion', 'carrot', 'lettuce', 'spinach', 'broccoli', 'potato', 'bell pepper', 'cucumber', 'avocado', 'lemon', 'lime', 'garlic', 'ginger', 'mushroom'],
      'Grains': ['bread', 'pasta', 'rice', 'cereal', 'flour', 'oats', 'quinoa', 'barley', 'wheat', 'bagel', 'tortilla', 'crackers'],
      'Pantry': ['oil', 'vinegar', 'salt', 'pepper', 'sugar', 'spices', 'herbs', 'sauce', 'dressing', 'honey', 'vanilla', 'baking powder', 'soy sauce'],
      'Frozen': ['frozen', 'ice cream', 'frozen vegetables', 'frozen fruit'],
      'Beverages': ['juice', 'soda', 'water', 'coffee', 'tea', 'wine', 'beer'],
    };
    for (var category in categoryMaps.keys) {
      if (categoryMaps[category]!.any((item) => lowerIngredient.contains(item))) {
        return category;
      }
    }
    return 'Other';
  }
}
