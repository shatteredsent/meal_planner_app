import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeFirestoreService {
  final CollectionReference recipesCollection =
      FirebaseFirestore.instance.collection('recipes');

  Future<void> addRecipe(Recipe recipe) async {
  print('Saving recipe to Firestore:');
  print(recipe.toJson());
  await recipesCollection.add(recipe.toJson());
  print('Recipe saved!');
  }

  Future<List<Recipe>> getRecipes() async {
    final snapshot = await recipesCollection.get();
    return snapshot.docs.map((doc) => Recipe.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> updateRecipe(String id, Recipe recipe) async {
    await recipesCollection.doc(id).update(recipe.toJson());
  }

  Future<void> deleteRecipe(String id) async {
    await recipesCollection.doc(id).delete();
  }
}
