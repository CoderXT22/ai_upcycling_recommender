import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 28 : 52,
          height: compact ? 28 : 52,
          decoration: BoxDecoration(
            color: EcoLoopTheme.primary,
            borderRadius: BorderRadius.circular(compact ? 8 : 14),
          ),
          child: Icon(
            Icons.eco_outlined,
            color: Colors.white,
            size: compact ? 18 : 32,
          ),
        ),
        if (compact) ...[
          const SizedBox(width: 8),
          const Text(
            'EcoLoop',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}
