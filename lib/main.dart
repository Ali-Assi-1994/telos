import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:telos/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env.dev');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  runApp(
    ProviderScope(
      // Riverpod 3 auto-retries failing providers by default. This app's
      // error handling (AsyncValue.guard, .when(error: ...)) was designed
      // around errors surfacing immediately, so restore that behavior.
      retry: (int retryCount, Object error) => null,
      child: const App(),
    ),
  );
}
