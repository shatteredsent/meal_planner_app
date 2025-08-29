import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/meal_plan_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<String> _checkedIngredients = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                _checkedIngredients.clear();
              });
            },
          ),
        ],
      ),
      body: Consumer2<MealPlanProvider, ShoppingListProvider>(
        builder: (context, mealPlanProvider, shoppingProvider, child) {
          final ingredients = mealPlanProvider.assignedIngredients;
          final visibleIngredients = ingredients.where((ing) => !_checkedIngredients.contains(ing)).toList();
          return Column(
            children: [
              Expanded(
                child: visibleIngredients.isEmpty
                    ? const Center(
                        child: Text(
                          'Your shopping list is empty! Assign meals to see ingredients.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: ingredients.length,
                        itemBuilder: (context, idx) {
                          final ingredient = ingredients[idx];
                          return CheckboxListTile(
                            title: Text(ingredient),
                            value: _checkedIngredients.contains(ingredient),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _checkedIngredients.add(ingredient);
                                } else {
                                  _checkedIngredients.remove(ingredient);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.speaker), // Alexa-style icon
                    label: const Text('Send to Alexa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final unselectedIngredients = ingredients.where((ing) => !_checkedIngredients.contains(ing)).toList();
                      if (unselectedIngredients.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Send to Alexa'),
                            content: const Text('No items to send.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      final shoppingListText = unselectedIngredients.join('\n');
                      await Clipboard.setData(ClipboardData(text: shoppingListText));
                      bool launchedAlexa = false;
                      try {
                        final alexaUri = Uri.parse('alexa://');
                        if (await canLaunchUrl(alexaUri)) {
                          await launchUrl(alexaUri);
                          launchedAlexa = true;
                        }
                      } catch (e) {
                        launchedAlexa = false;
                      }
                      if (!launchedAlexa) {
                        final webUri = Uri.parse('https://alexa.amazon.com/shopping-list');
                        if (await canLaunchUrl(webUri)) {
                          await launchUrl(webUri);
                        } else {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Send to Alexa'),
                              content: const Text('Could not open Alexa app or website.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shopping list copied! Paste in Alexa app.')),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}