import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/shopping_item_card.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              // TODO: Implement clear completed items
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clear completed items')),
              );
            },
          ),
        ],
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, child) {
          if (provider.shoppingItems.isEmpty) {
            return const Center(
              child: Text(
                'Your shopping list is empty!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final itemsByCategory = provider.itemsByCategory;

          return ListView(
            children: [
              for (var category in itemsByCategory.keys)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...itemsByCategory[category]!.map((item) => ShoppingItemCard(item: item)),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}