import '../supabase_config.dart';

class AuthService {
  // Register with email & password
  Future<void> register(String email, String password) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Login with email & password
  Future<void> login(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Get current logged-in user id
  String? get currentUserId => supabase.auth.currentUser?.id;
}
