import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import 'app_theme.dart';

class EcoLoopApp extends StatelessWidget {
  const EcoLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoLoop',
      debugShowCheckedModeBanner: false,
      theme: EcoLoopTheme.light,
      home: const LoginScreen(),
    );
  }
}
