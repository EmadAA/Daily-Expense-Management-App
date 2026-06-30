// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';
import '../services/refresh_service.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final name = ref.read(profileProvider).name;
    _nameCtrl.text = name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Show modern success/error dialog ──────────────────────────────────────
  void _showResultDialog({required bool isSuccess, required String message}) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isSuccess ? const Color(0xFF1D9E75) : Colors.red)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: isSuccess ? const Color(0xFF1D9E75) : Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? 'Success!' : 'Failed',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor:
                        isSuccess ? const Color(0xFF1D9E75) : Colors.red,
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    await ref.read(profileProvider.notifier).updateName(_nameCtrl.text.trim());
    if (!mounted) return;
    _showResultDialog(
      isSuccess: true,
      message: 'Your name has been updated successfully.',
    );
  }

  Future<void> _savePassword() async {
    if (_currentPassCtrl.text.isEmpty ||
        _newPassCtrl.text.isEmpty ||
        _confirmPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('New password must be at least 6 characters')),
      );
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    final error = await ref.read(profileProvider.notifier).updatePassword(
          _currentPassCtrl.text,
          _newPassCtrl.text,
        );

    if (!mounted) return;

    if (error != null) {
      _showResultDialog(isSuccess: false, message: error);
    } else {
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showResultDialog(
        isSuccess: true,
        message: 'Your password has been changed successfully.',
      );
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final email = ProfileService().currentEmail;

    // Sync controller with provider state
    if (profileState.name.isNotEmpty &&
        _nameCtrl.text != profileState.name &&
        !profileState.isLoading) {
      _nameCtrl.text = profileState.name;
    }

    final initial = profileState.name.isNotEmpty
        ? profileState.name[0].toUpperCase()
        : email.isNotEmpty
            ? email[0].toUpperCase()
            : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A2E),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              tooltip: 'Refresh',
              onPressed: () => refreshAll(ref),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1D9E75),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: profileState.isLoading && profileState.name.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1D9E75),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),

                  // ── Profile Header Card ───────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D9E75), Color(0xFF147A5B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D9E75).withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D9E75),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name
                          if (profileState.name.isNotEmpty)
                            Text(
                              profileState.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),

                          // Email
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout_rounded,
                                  size: 18, color: Color(0xFF1D9E75)),
                              label: const Text(
                                'Logout',
                                style: TextStyle(
                                  color: Color(0xFF1D9E75),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Update Name Section ───────────────────────────────────
                  _buildSectionCard(
                    title: 'Update Name',
                    icon: Icons.edit_outlined,
                    iconColor: const Color(0xFF1D9E75),
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: const Color(0xFF1D9E75).withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F5F2),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          labelStyle: const TextStyle(color: Color(0xFF1D9E75)),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: profileState.isLoading ? null : _saveName,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: const Color(0xFF1D9E75),
                            elevation: 0,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Change Password Section ───────────────────────────────
                  _buildSectionCard(
                    title: 'Change Password',
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    children: [
                      _buildPasswordField(
                        controller: _currentPassCtrl,
                        label: 'Current password',
                        obscure: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        controller: _newPassCtrl,
                        label: 'New password',
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        helperText: 'Min. 6 characters',
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        controller: _confirmPassCtrl,
                        label: 'Confirm new password',
                        obscure: _obscureConfirm,
                        onToggle: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              profileState.isLoading ? null : _savePassword,
                          icon: profileState.isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.lock_reset_rounded, size: 18),
                          label: const Text(
                            'Update Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                            elevation: 0,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Reusable Section Card Widget ─────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.12),
                        iconColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // ── Reusable Password Field Widget ───────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFFF6B6B)),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade400,
              ),
              onPressed: onToggle,
              padding: const EdgeInsets.all(12),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F8F6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: const TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}