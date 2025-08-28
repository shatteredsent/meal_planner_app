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

          final pendingItems = provider.pendingItems;
          final completedItems = provider.completedItems;

          return ListView(
            children: [
              if (pendingItems.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Pending Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...pendingItems.map((item) => ShoppingItemCard(item: item)),
              ],
              if (completedItems.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Completed Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...completedItems.map((item) => ShoppingItemCard(item: item)),
              ],
            ],
          );
        },
      ),
    );
  }
}