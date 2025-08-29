import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';


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
          final categoryOrder = [
            'Produce',
            'Meat & Seafood',
            'Dairy & Eggs',
            'Pantry & Dry Goods',
            'Frozen Foods',
            'Bakery',
            'Beverages',
            'Other/Miscellaneous',
          ];

          return ListView(
            children: [
                ...categoryOrder.where((cat) => itemsByCategory.containsKey(cat)).map((category) {
                  final items = itemsByCategory[category]!;
                  return ExpansionTile(
                    title: Text(
                      '$category (${items.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: true,
                    children: items.map((item) {
                      return ListTile(
                        title: Text(
                          item.quantity > 1 ? '${item.name} (x${item.quantity})' : item.name,
                        ),
                        trailing: Checkbox(
                          value: item.isCompleted,
                          onChanged: (checked) {
                            provider.toggleItemCompletion(item);
                          },
                        ),
                        onLongPress: () {
                          if (item.id != null) {
                            provider.deleteItem(item.id!);
                          }
                        },
                      );
                    }).toList(),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}