import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_service.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

class ProfileState {
  final String name;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ProfileState({
    this.name = '',
    this.isLoading = false,
    this.error = null,
    this.successMessage = null,
  });

  ProfileState copyWith({
    String? name,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ProfileState(
      name: name ?? this.name,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _service;

  ProfileNotifier(this._service) : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final name = await _service.fetchName();
      state = state.copyWith(name: name, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateName(String name) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateName(name);
      state = state.copyWith(
        name: name,
        isLoading: false,
        successMessage: 'Name updated successfully!',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Returns null on success, error message on failure
  Future<String?> updatePassword(
      String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      final verified = await _service.verifyCurrentPassword(currentPassword);
      if (!verified) {
        state = state.copyWith(isLoading: false);
        return 'Incorrect current password.';
      }
      await _service.updatePassword(newPassword);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password updated successfully!',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  Future<String?> sendResetEmail(String email) async {
    try {
      await _service.sendPasswordResetEmail(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void clearMessages() => state = state.copyWith();
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref.read(profileServiceProvider)),
);
