import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final servicesProvider = Provider<List<ServiceItem>>((ref) {
  return const [
    ServiceItem(
      title: 'Wound Dressing',
      subtitle: 'Professional wound care at home',
      description:
          'Expert wound care delivered at home by trained nurses using sterile techniques and quality materials.',
      price: 45,
      rating: '4.8',
      icon: Icons.grid_view_rounded,
      room: 'Room 3, Floor 2',
      duration: '30 mins',
      staffName: 'Dr. Sarah Lee',
      staffAvatarSeed: 'sarah-lee',
      unavailableSlotIndices: {2, 7, 14, 22, 30},
    ),
    ServiceItem(
      title: 'Physiotherapy Session',
      subtitle: 'Recovery and mobility therapy',
      description:
          'Personalized rehabilitation and mobility therapy with certified specialists.',
      price: 80,
      rating: '4.9',
      icon: Icons.show_chart,
      room: 'Room 5, Floor 1',
      duration: '45 mins',
      staffName: 'Dr. James Okafor',
      staffAvatarSeed: 'james-okafor',
      unavailableSlotIndices: {3, 11, 18, 24, 33},
    ),
    ServiceItem(
      title: 'Vaccination Visit',
      subtitle: 'Immunisation and vaccine service',
      description:
          'Safe and quick immunisation service administered by licensed healthcare professionals.',
      price: 35,
      rating: '4.7',
      icon: Icons.vaccines_outlined,
      room: 'Room 1, Floor 2',
      duration: '20 mins',
      staffName: 'Dr. Priya Sharma',
      staffAvatarSeed: 'priya-sharma',
      unavailableSlotIndices: {1, 8, 16, 20, 28},
    ),
    ServiceItem(
      title: 'General Checkup',
      subtitle: 'Full body health assessment',
      description:
          'Comprehensive health assessment covering vitals, blood work review, and lifestyle consultation.',
      price: 50,
      rating: '4.7',
      icon: Icons.health_and_safety_outlined,
      room: 'Room 4, Floor 1',
      duration: '60 mins',
      staffName: 'Dr. Emily Chen',
      staffAvatarSeed: 'emily-chen',
      unavailableSlotIndices: {4, 9, 17, 23, 31},
    ),
    ServiceItem(
      title: 'Dental Cleaning',
      subtitle: 'Professional teeth cleaning',
      description:
          'Professional dental hygiene service including scaling, polishing, and oral health assessment.',
      price: 40,
      rating: '4.6',
      icon: Icons.sentiment_satisfied_alt_outlined,
      room: 'Room 2, Floor 3',
      duration: '40 mins',
      staffName: 'Dr. Mark Wilson',
      staffAvatarSeed: 'mark-wilson',
      unavailableSlotIndices: {5, 12, 19, 26, 32},
    ),
  ];
});

class ServiceItem {
  const ServiceItem({
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
}
