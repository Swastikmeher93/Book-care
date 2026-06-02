import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../auth/api_config.dart';

class CartItem {
  const CartItem({
    required this.serviceId,
    required this.title,
    required this.icon,
    required this.date,
    required this.scheduledDate,
    required this.time,
    required this.startTime,
    required this.room,
    required this.price,
  });

  final String serviceId;
  final String title;
  final IconData icon;
  final String date;
  final String scheduledDate;
  final String time;
  final String startTime;
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

  /// Sends checkout request to backend and clears the cart on success.
  /// Returns the parsed checkout response map.
  Future<Map<String, dynamic>> checkout(String patientId) async {
    final itemsPayload = state.map((item) => {
      'service_id': item.serviceId,
      'scheduled_date': item.scheduledDate,
      'start_time': item.startTime,
    }).toList();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cart/checkout'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'patient_id': patientId,
        'items': itemsPayload,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      clear();
      return data;
    } else {
      String errMsg = 'Checkout failed';
      try {
        final body = jsonDecode(response.body);
        if (body['detail'] != null) {
          errMsg = body['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
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
