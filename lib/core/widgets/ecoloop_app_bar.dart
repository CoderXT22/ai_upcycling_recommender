import 'package:flutter/material.dart';

import '../../screens/education/education_hub_screen.dart';
import '../../screens/profile/profile_screen.dart';
import 'app_logo.dart';

class EcoLoopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EcoLoopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const AppLogo(compact: true),
      actions: [
        IconButton(
          tooltip: 'Education Hub',
          icon: const Icon(Icons.school_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EducationHubScreen()),
            );
          },
        ),
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
        ),
      ],
    );
  }
}
