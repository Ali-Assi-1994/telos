import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_service.g.dart';

/// Provides access to the shared [SupabaseClient] instance.
///
/// Repositories should depend on this provider instead of calling
/// [Supabase.instance.client] directly.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}
