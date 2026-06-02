import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that tracks the current Supabase user session.
final authStateProvider = StateNotifierProvider<AuthStateNotifier, User?>(
  (ref) => AuthStateNotifier(),
);

class AuthStateNotifier extends StateNotifier<User?> {
  AuthStateNotifier() : super(null) {
    _init();
  }

  void _init() {
    // Set initial state
    state = Supabase.instance.client.auth.currentUser;

    // Listen to auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      state = session?.user;
    });
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}