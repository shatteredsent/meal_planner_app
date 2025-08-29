  class ShoppingItem {
    final int? id;
    final String name;
    final String category;
    final int quantity;
    final bool isCompleted;
    final DateTime dateAdded;

    ShoppingItem({
      this.id,
      required this.name,
      required this.category,
      this.quantity = 1,
      this.isCompleted = false,
      required this.dateAdded,
    });

    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'isCompleted': isCompleted ? 1 : 0,
        'dateAdded': dateAdded.toIso8601String(),
      };
    }

    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'is_completed': isCompleted ? 1 : 0,
        'date_added': dateAdded.millisecondsSinceEpoch,
      };
    }

    factory ShoppingItem.fromJson(Map<String, dynamic> json) {
      return ShoppingItem(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        quantity: json['quantity'] ?? 1,
        isCompleted: json['isCompleted'] == 1 || json['is_completed'] == 1,
        dateAdded: json['dateAdded'] != null
            ? DateTime.parse(json['dateAdded'])
            : DateTime.fromMillisecondsSinceEpoch(json['date_added']),
      );
    }

    ShoppingItem copyWith({
      int? id,
      String? name,
      String? category,
      int? quantity,
      bool? isCompleted,
      DateTime? dateAdded,
    }) {
      return ShoppingItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        isCompleted: isCompleted ?? this.isCompleted,
        dateAdded: dateAdded ?? this.dateAdded,
      );
    }
  }