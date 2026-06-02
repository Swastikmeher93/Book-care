import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_care/auth/login_view.dart';
import 'package:health_care/cart/cart_view.dart';
import 'package:health_care/cart/booking_confirmed_view.dart';
import 'package:health_care/home/home_view.dart';
import 'package:health_care/providers/auth_provider.dart';
import 'package:health_care/service_detail/service_detail_view.dart';
import 'package:health_care/services_card/services/services_controller.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    final goRouter = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginView()),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeView(),
          routes: [
            GoRoute(
              path: 'service-detail',
              builder: (context, state) {
                // We need to pass the service item. We'll use state.extra?
                // For simplicity, we'll pass via state.extra as a ServiceItem.
                final extra = state.extra as Map?;
                final service = extra?['service'] as ServiceItem?;
                if (service == null) {
                  // fallback to home if service not provided
                  return const HomeView();
                }
                return ServiceDetailView(service: service);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartView(),
          routes: [
            GoRoute(
              path: 'booking-confirmed',
              builder: (context, state) {
                final extra = state.extra as Map?;
                final bookingData = extra?['booking'] as Map<String, dynamic>?;
                return BookingConfirmedView(bookingData: bookingData);
              },
            ),
          ],
        ),
      ],
      // Optional: configure error pages, etc.
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('No route found for ${state.uri}')),
      ),
    );

    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      title: 'CareBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80FF)),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
    );
  }
}
