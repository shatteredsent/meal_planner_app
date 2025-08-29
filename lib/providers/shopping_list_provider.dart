import 'package:flutter/foundation.dart';
import '../models/shopping_item.dart';
import '../models/meal_plan.dart';
import '../services/database_service.dart';

class ShoppingListProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<ShoppingItem> _shoppingItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  final bool _isInitializing = true;

  // Do NOT perform async or notifyListeners in constructor!
  // Do NOT use WidgetsBinding.instance.addPostFrameCallback in this provider.
  // Instead, call clearAllItems() or generateShoppingListFromMealPlans() from your main widget's initState using a post-frame callback.
  ShoppingListProvider();

  // Getters
  List<ShoppingItem> get shoppingItems => _shoppingItems;
  List<ShoppingItem> get completedItems =>
      _shoppingItems.where((item) => item.isCompleted).toList();
  List<ShoppingItem> get pendingItems =>
      _shoppingItems.where((item) => !item.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Expose items for AlexaService
  List<ShoppingItem> get items => _shoppingItems;

  // Get items by category
  Map<String, List<ShoppingItem>> get itemsByCategory {
    final Map<String, List<ShoppingItem>> categorizedItems = {};
    for (var item in _shoppingItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }
    return categorizedItems;
  }

  // Get pending items count
  int get pendingItemsCount => pendingItems.length;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!_isInitializing) {
      notifyListeners();
    }
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    if (!_isInitializing) {
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (!_isInitializing) {
      notifyListeners();
    }
  }

  Future<void> loadShoppingItems() async {
    try {
      _setLoading(true);
      _setError(null);

      if (kIsWeb) {
        // No-op for web, just use in-memory list
        _setLoading(false);
        return;
      }

      _shoppingItems = await _databaseService.getShoppingItems();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load shopping items: $e');
      _setLoading(false);
      debugPrint('Error loading shopping items: $e');
    }
  }

  Future<void> addShoppingItem(String name, String category) async {
    try {
      _setError(null);
    
      // Prevent duplicate items
      if (_shoppingItems.any((item) => item.name.toLowerCase().trim() == name.toLowerCase().trim())) {
        _setError('Item "$name" already exists in the list');
        return;
      }

      final item = ShoppingItem(
        name: name.trim(),
        category: category,
        dateAdded: DateTime.now(),
      );

      if (kIsWeb) {
        _shoppingItems.add(item);
        if (!_isInitializing) {
          notifyListeners();
        }
        return;
      }

      await _databaseService.insertShoppingItem(item);
      await loadShoppingItems();
    } catch (e) {
      _setError('Failed to add item: $e');
      debugPrint('Error adding shopping item: $e');
    }
  }

  // Add item by ShoppingItem instance
  Future<void> addItem(ShoppingItem item) async {
    try {
      _setError(null);

      // Prevent duplicate items
      if (_shoppingItems.any((existing) => existing.name.toLowerCase().trim() == item.name.toLowerCase().trim())) {
        _setError('Item "${item.name}" already exists in the list');
        return;
      }

      if (kIsWeb) {
        _shoppingItems.add(item);
        if (!_isInitializing) {
          notifyListeners();
        }
        return;
      }

      await _databaseService.insertShoppingItem(item);
      await loadShoppingItems();
    } catch (e) {
      _setError('Failed to add item: $e');
      debugPrint('Error adding item: $e');
    }
  }

  Future<void> toggleItemCompletion(ShoppingItem item) async {
    try {
      _setError(null);

      if (kIsWeb) {
        final idx = _shoppingItems.indexWhere((i) => i.name == item.name);
        if (idx != -1) {
          _shoppingItems[idx] = item.copyWith(isCompleted: !item.isCompleted);
          if (!_isInitializing) {
            notifyListeners();
          }
        }
        return;
      }

      final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
      await _databaseService.updateShoppingItem(updatedItem);
      await loadShoppingItems();
    } catch (e) {
      _setError('Failed to update item: $e');
      debugPrint('Error toggling item completion: $e');
    }
  }

  // Toggle completion by item name
  Future<void> toggleCompletionByName(String name) async {
    try {
      final item = _shoppingItems.firstWhere((i) => i.name.toLowerCase() == name.toLowerCase());
      await toggleItemCompletion(item);
    } catch (e) {
      _setError('Item "$name" not found');
      debugPrint('Error toggling completion by name: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      _setError(null);

      if (kIsWeb) {
        _shoppingItems.removeWhere((item) => item.id == id);
        if (!_isInitializing) {
          notifyListeners();
        }
        return;
      }

      await _databaseService.deleteShoppingItem(id);
      await loadShoppingItems();
    } catch (e) {
      _setError('Failed to delete item: $e');
      debugPrint('Error deleting item: $e');
    }
  }

  // Delete item by name
  Future<void> deleteItemByName(String name) async {
    try {
      final item = _shoppingItems.firstWhere((i) => i.name.toLowerCase() == name.toLowerCase());
      if (item.id != null) {
        await deleteItem(item.id!);
      }
    } catch (e) {
      _setError('Item "$name" not found');
      debugPrint('Error deleting item by name: $e');
    }
  }

  // Clear all completed items
  Future<void> clearCompletedItems() async {
    try {
      _setLoading(true);
      _setError(null);

      if (kIsWeb) {
        _shoppingItems.removeWhere((item) => item.isCompleted);
        if (!_isInitializing) {
          _setLoading(false);
        }
        return;
      }

      final completed = completedItems;
      for (var item in completed) {
        if (item.id != null) {
          await _databaseService.deleteShoppingItem(item.id!);
        }
      }
      await loadShoppingItems();
    } catch (e) {
      _setError('Failed to clear completed items: $e');
      _setLoading(false);
      debugPrint('Error clearing completed items: $e');
    }
  }

  // Clear all items
  Future<void> clearAllItems() async {
    try {
      _setLoading(true);
      _setError(null);

      if (kIsWeb) {
        _shoppingItems.clear();
        if (!_isInitializing) {
          _setLoading(false);
        }
        return;
      }

      for (var item in _shoppingItems) {
        if (item.id != null) {
          await _databaseService.deleteShoppingItem(item.id!);
        }
      }
      await loadShoppingItems();
    } catch (e) {
      _setError('Failed to clear all items: $e');
      _setLoading(false);
      debugPrint('Error clearing all items: $e');
    }
  }

  // Search items
  List<ShoppingItem> searchItems(String query) {
    if (query.isEmpty) return _shoppingItems;
  
    final lowerQuery = query.toLowerCase();
    return _shoppingItems.where((item) =>
      item.name.toLowerCase().contains(lowerQuery) ||
      item.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Sort items
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
    if (!_isInitializing) {
      notifyListeners();
    }
  }

  Future<void> generateShoppingListFromMealPlans(List<MealPlan> mealPlans) async {
    try {
      _setLoading(true);
      _setError(null);

      // Always clear the shopping list before generating new items
      _shoppingItems.clear();
      if (!_isInitializing) {
        notifyListeners();
      }

  final Map<String, int> ingredientCounts = {};

      debugPrint('=== generateShoppingListFromMealPlans called with ${mealPlans.length} meal plans ===');

      // Debug: print meal plan recipes and ingredients
      for (int i = 0; i < mealPlans.length; i++) {
        final plan = mealPlans[i];
        debugPrint('MealPlan $i:');
        debugPrint('  Breakfast: ${plan.breakfast?.name ?? "null"} - ingredients: ${plan.breakfast?.ingredients}');
        debugPrint('  Lunch: ${plan.lunch?.name ?? "null"} - ingredients: ${plan.lunch?.ingredients}');
        debugPrint('  Dinner: ${plan.dinner?.name ?? "null"} - ingredients: ${plan.dinner?.ingredients}');
      }

      // Aggregate ingredient counts from currently assigned recipes
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

      debugPrint('Ingredient counts: $ingredientCounts');

      if (ingredientCounts.isEmpty) {
        _setError('No ingredients found in the selected meal plans');
        _setLoading(false);
        if (!_isInitializing) {
          notifyListeners();
        }
        return;
      }

      // Web branch: add items directly, single notify
      if (kIsWeb) {
        debugPrint('Adding ${ingredientCounts.length} unique ingredients to shopping list (web)');
        _shoppingItems.clear();

        final newItems = ingredientCounts.entries.map((entry) {
          return ShoppingItem(
            name: entry.key,
            category: _categorizeIngredient(entry.key),
            quantity: entry.value,
            dateAdded: DateTime.now(),
          );
        }).toList();

        _shoppingItems.addAll(newItems);
        debugPrint('Successfully added ${newItems.length} items. Current list size: ${_shoppingItems.length}');
        _setLoading(false);
        if (!_isInitializing) {
          notifyListeners();
        }
        return;
      }

      // Non-web branch: clear DB, then add items using batch operations
      debugPrint('Adding ${ingredientCounts.length} unique ingredients to shopping list (mobile/db)');

      // Clear existing items
      final existingItems = await _databaseService.getShoppingItems();
      for (var item in existingItems) {
        if (item.id != null) {
          await _databaseService.deleteShoppingItem(item.id!);
        }
      }

      // Add new items
      int addedCount = 0;
      for (var entry in ingredientCounts.entries) {
        debugPrint('Adding item: ${entry.key} x${entry.value}');
        final item = ShoppingItem(
          name: entry.key,
          category: _categorizeIngredient(entry.key),
          quantity: entry.value,
          dateAdded: DateTime.now(),
        );
        await _databaseService.insertShoppingItem(item);
        addedCount++;
      }

      debugPrint('Successfully added $addedCount items.');
      await loadShoppingItems();
      if (!_isInitializing) {
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to generate shopping list: $e');
      _setLoading(false);
      if (!_isInitializing) {
        notifyListeners();
      }
      debugPrint('Error generating shopping list from meal plans: $e');
    }
  }

  /// Force clear and refresh shopping list (for UI or debug)
  Future<void> clearAndRefreshShoppingList() async {
    _shoppingItems.clear();
    await loadShoppingItems();
    if (!_isInitializing) {
      notifyListeners();
    }
  }

  String _categorizeIngredient(String ingredient) {
    final lowerIngredient = ingredient.toLowerCase().trim();

    final categoryMaps = {
      'Meat & Seafood': [
        'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'shrimp',
        'turkey', 'lamb', 'crab', 'lobster', 'bacon', 'ham', 'sausage', 'steak', 'meats', 'seafood', 'duck', 'goose', 'trout', 'cod', 'anchovy', 'sardine'
      ],
      'Dairy & Eggs': [
        'milk', 'cheese', 'yogurt', 'butter', 'cream', 'sour cream',
        'cottage cheese', 'mozzarella', 'cheddar', 'parmesan', 'eggs', 'egg', 'dairy'
      ],
      'Produce': [
        'apple', 'banana', 'berry', 'berries', 'orange', 'tomato', 'onion', 'carrot',
        'lettuce', 'spinach', 'broccoli', 'potato', 'bell pepper', 'cucumber',
        'avocado', 'lemon', 'lime', 'garlic', 'ginger', 'mushroom', 'grape', 'peach', 'pear', 'plum', 'greens', 'vegetable', 'vegetables', 'fruit', 'fruits'
      ],
      'Pantry & Dry Goods': [
        'oil', 'vinegar', 'salt', 'pepper', 'sugar', 'spices', 'herbs',
        'sauce', 'dressing', 'honey', 'vanilla', 'baking powder', 'soy sauce', 'pasta', 'rice', 'flour', 'oats', 'quinoa', 'barley', 'wheat', 'cereal', 'crackers', 'bread', 'bagel', 'tortilla', 'dry', 'pantry', 'lentil', 'beans', 'chickpea', 'split pea', 'cornmeal', 'polenta', 'noodle', 'noodles'
      ],
      'Frozen Foods': [
        'frozen', 'ice cream', 'frozen vegetables', 'frozen fruit', 'frozen foods', 'frozen food', 'frozen pizza', 'frozen meals', 'frozen entree', 'frozen dessert'
      ],
      'Bakery': [
        'bread', 'bagel', 'bun', 'roll', 'croissant', 'muffin', 'cake', 'pastry', 'bakery', 'biscuit', 'pie', 'tart', 'cookie', 'cookies', 'brownie', 'loaf'
      ],
      'Beverages': [
        'juice', 'soda', 'water', 'coffee', 'tea', 'wine', 'beer', 'beverage', 'drinks', 'drink', 'cola', 'lemonade', 'milkshake', 'smoothie'
      ],
      'Other/Miscellaneous': [
        'other', 'misc', 'miscellaneous', 'snack', 'snacks', 'condiment', 'syrup', 'jam', 'jelly', 'preserves', 'pickles', 'chips', 'popcorn', 'nuts', 'nut', 'seeds', 'seed', 'candy', 'chocolate', 'gum', 'mint', 'mints', 'ice', 'ice cubes', 'ice block', 'ice pack'
      ],
    };

    for (var category in categoryMaps.keys) {
      for (var item in categoryMaps[category]!) {
        // Match whole word or plural, ignore case
        final pattern = RegExp(r'\b' + RegExp.escape(item) + r's?\b', caseSensitive: false);
        if (pattern.hasMatch(lowerIngredient)) {
          return category;
        }
      }
    }

    return 'Other/Miscellaneous';
  }

  // Get items count by category
  Map<String, int> getItemsCountByCategory() {
    final counts = <String, int>{};
    for (var item in _shoppingItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  // Get completion percentage
  double get completionPercentage {
    if (_shoppingItems.isEmpty) return 0.0;
    return completedItems.length / _shoppingItems.length;
  }
}