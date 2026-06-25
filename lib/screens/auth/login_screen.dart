import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../navigation/main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                const TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    hintText: 'Email address',
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: 'Password',
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Login',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(),
                      ),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {},
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
