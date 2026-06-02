import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_care/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tntvebgyadjewfervpon.supabase.co',
    anonKey: 'sb_publishable_qmLfu_TMNCo6XVc1oGlEDg_t9WpmXqj',
  );

  runApp(const ProviderScope(child: MyApp()));
}