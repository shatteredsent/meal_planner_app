import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception('Local database is not supported on web.');
    }
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'meal_planner.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recipes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            ingredients TEXT,
            instructions TEXT,
            prepTime INTEGER,
            cookTime INTEGER,
            servings INTEGER,
            imageUrl TEXT,
            category TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            category TEXT,
            isCompleted INTEGER,
            dateAdded TEXT
          )
        ''');
      },
    );
  }

  // --- Recipe Operations ---

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await database;
    return db.insert('recipes', recipe.toJson());
  }

  Future<List<Recipe>> getRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recipes');
    return List.generate(maps.length, (i) => Recipe.fromJson(maps[i]));
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Recipe.fromJson(maps.first);
    }
    return null;
  }

  // --- Shopping List Operations ---

  Future<int> insertShoppingItem(ShoppingItem item) async {
    final db = await database;
    return db.insert('shopping_items', item.toJson());
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    final db = await database;
    await db.update(
      'shopping_items',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteShoppingItem(int id) async {
    final db = await database;
    await db.delete(
      'shopping_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ShoppingItem>> getShoppingItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shopping_items');
    return List.generate(maps.length, (i) => ShoppingItem.fromJson(maps[i]));
  }
}

