import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

// The service instance
final authServiceProvider = Provider((ref) => AuthService());

// Auth state: tracks loading and error message
class AuthState {
  final bool isLoading;
  final String? error;

  AuthState({this.isLoading = false, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      await _service.login(email, password);
      state = AuthState();
      return true; // success
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      await _service.register(email, password);
      state = AuthState();
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
  }

  void clearError() => state = AuthState();
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
