import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class ProfileService {
  Future<String> fetchName() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .single();
    return res['name'] ?? '';
  }

  Future<void> updateName(String name) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').upsert({
      'id': userId,
      'name': name,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Verify current password by re-authenticating
  Future<bool> verifyCurrentPassword(String password) async {
    final email = supabase.auth.currentUser?.email ?? '';
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  String get currentEmail => supabase.auth.currentUser?.email ?? '';
}
