import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  @override
  Session? build() {
    final supabase = Supabase.instance.client;
    
    // Listen to auth changes
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != state) {
        state = data.session;
      }
    });

    return supabase.auth.currentSession;
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = null;
  }

  bool get isAuthenticated => state != null;
  User? get user => state?.user;
}
