import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_care/auth/api_config.dart';
import 'package:http/http.dart' as http;

/// Riverpod FutureProvider that fetches available services from FastAPI backend.
final servicesProvider = FutureProvider<List<ServiceItem>>((ref) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/services');
  final response = await http.get(uri).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => ServiceItem.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load services from backend: ${response.statusCode}');
  }
});

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.rating,
    required this.icon,
    required this.room,
    required this.duration,
    required this.staffName,
    required this.staffAvatarSeed,
    required this.unavailableSlotIndices,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int price;
  final String rating;
  final IconData icon;
  final String room;
  final String duration;
  final String staffName;
  final String staffAvatarSeed;
  final Set<int> unavailableSlotIndices;

  String get priceDisplay => '\$$price';

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final caregiversList = json['caregivers'] as List?;
    final firstCaregiverName = (caregiversList != null && caregiversList.isNotEmpty)
        ? caregiversList[0]['name'] as String
        : 'No staff assigned';
    final firstCaregiverId = (caregiversList != null && caregiversList.isNotEmpty)
        ? caregiversList[0]['id'] as String
        : 'default-staff';

    return ServiceItem(
      id: json['id'] as String,
      title: json['name'] as String,
      subtitle: json['description'] != null
          ? (json['description'] as String).split('\n')[0]
          : 'Healthcare service',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toInt(),
      rating: '4.8', // Rating is not in database, fallback to a standard high rating
      icon: _getIconForName(json['name'] as String),
      room: json['location'] as String? ?? 'Clinic Room',
      duration: '${json['duration_minutes']} mins',
      staffName: firstCaregiverName,
      staffAvatarSeed: firstCaregiverId,
      unavailableSlotIndices: {}, // Loaded dynamically in detail view
    );
  }

  static IconData _getIconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wound') || lower.contains('dressing')) {
      return Icons.grid_view_rounded;
    } else if (lower.contains('physio') || lower.contains('therapy')) {
      return Icons.show_chart;
    } else if (lower.contains('vaccin') || lower.contains('immun')) {
      return Icons.vaccines_outlined;
    } else if (lower.contains('checkup') || lower.contains('assess')) {
      return Icons.health_and_safety_outlined;
    } else if (lower.contains('dental') || lower.contains('clean')) {
      return Icons.sentiment_satisfied_alt_outlined;
    }
    return Icons.medical_services_outlined;
  }
}
