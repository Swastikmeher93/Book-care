import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that tracks the current Supabase auth user.
final authStateProvider = NotifierProvider<AuthStateNotifier, User?>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends Notifier<User?> {
  StreamSubscription<AuthState>? _subscription;

  @override
  User? build() {
    // Seed with the already-signed-in user (if any).
    final initialUser = Supabase.instance.client.auth.currentUser;

    // Keep state in sync with Supabase auth events.
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) => state = data.session?.user,
    );

    // Cancel the subscription when this notifier is disposed.
    ref.onDispose(() => _subscription?.cancel());

    return initialUser;
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}