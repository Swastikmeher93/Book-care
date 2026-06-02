import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:health_care/auth/api_config.dart';

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

/// Riverpod FutureProvider that tracks and retrieves the default PostgreSQL patient profile.
/// Bypasses authentication so the application connects directly to the backend open database.
final patientProfileProvider = FutureProvider<PatientProfile?>((ref) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/patients');
  final response = await http.get(uri).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return PatientProfile.fromJson(data[0]);
    } else {
      // If no patient exists, seed a default 'John Smith' patient record
      final createUri = Uri.parse('${ApiConfig.baseUrl}/patients');
      final createRes = await http.post(
        createUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': 'John',
          'last_name': 'Smith',
          'email': 'john.smith@example.com',
          'phone': '555-0123'
        }),
      ).timeout(const Duration(seconds: 10));

      if (createRes.statusCode == 201) {
        final Map<String, dynamic> createdData = jsonDecode(createRes.body);
        return PatientProfile.fromJson(createdData);
      }
    }
  }
  throw Exception('Failed to load default patient profile');
});
