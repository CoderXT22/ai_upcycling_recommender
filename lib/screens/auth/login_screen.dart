import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/app_user.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../navigation/main_navigation_screen.dart';
import '../organisations/organisation_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userRepository = UserRepository();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user != null) {
        await _userRepository.updateLastLogin(user.uid);
      }
      if (!mounted) return;
      final appUser = user == null
          ? null
          : await _userRepository.fetchUserProfile(user.uid);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => appUser?.role == AppUserRoles.organisationUser
              ? const OrganisationHomeScreen()
              : const MainNavigationScreen(),
        ),
      );
    } catch (error) {
      setState(() => _errorMessage = _friendlyAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter your email address first.');
      return;
    }

    try {
      await _authService.sendPasswordReset(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (error) {
      setState(() => _errorMessage = _friendlyAuthError(error));
    }
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid-credential') ||
        message.contains('wrong-password')) {
      return 'Invalid email or password.';
    }
    if (message.contains('user-not-found')) {
      return 'No account found for this email.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(),
                const SizedBox(height: 14),
                const Text(
                  'EcoLoop',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your sustainability companion',
                  style: TextStyle(color: EcoLoopTheme.mutedText),
                ),
                const SizedBox(height: 28),
                _AuthSwitch(
                  activeLabel: 'Login',
                  inactiveLabel: 'Register',
                  onInactivePressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    hintText: 'Email address',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: 'Password',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(label: 'Login', onPressed: _login),
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Forgot password? Reset'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthSwitch extends StatelessWidget {
  const _AuthSwitch({
    required this.activeLabel,
    required this.inactiveLabel,
    required this.onInactivePressed,
  });

  final String activeLabel;
  final String inactiveLabel;
  final VoidCallback onInactivePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: EcoLoopTheme.softGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EcoLoopTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: onInactivePressed,
              child: Text(inactiveLabel),
            ),
          ),
        ],
      ),
    );
  }
}
