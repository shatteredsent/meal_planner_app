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

