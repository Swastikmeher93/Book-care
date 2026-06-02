import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  const CartItem({
    required this.title,
    required this.icon,
    required this.date,
    required this.time,
    required this.room,
    required this.price,
  });

  final String title;
  final IconData icon;
  final String date;
  final String time;
  final String room;
  final int price;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void add(CartItem item) {
    state = [...state, item];
  }

  void remove(int index) {
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  void clear() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

// Derived providers
final cartSubtotalProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.price);
});

final cartServiceFeeProvider = Provider<int>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  return subtotal > 0 ? 8 : 0;
});

final cartTotalProvider = Provider<int>((ref) {
  return ref.watch(cartSubtotalProvider) + ref.watch(cartServiceFeeProvider);
});
