import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/organisation_profile.dart';
import '../../repositories/organisation_repository.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'organisation_events_screen.dart';
import 'organisation_support_hub_screen.dart';
import 'organisation_profile_screen.dart';

class OrganisationHomeScreen extends StatelessWidget {
  const OrganisationHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organisation'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<OrganisationProfile?>(
        stream: OrganisationRepository().watchOrganisationForUser(user.uid),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading
                            ? 'Loading organisation...'
                            : profile?.organisationName ?? 'Organisation account',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLoading
                            ? 'Checking your organisation details.'
                            : profile == null
                            ? 'Add organisation details to use organisation tools.'
                            : '${profile.organisationType} - ${profile.location}',
                        style: const TextStyle(color: EcoLoopTheme.mutedText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _OrganisationTile(
                icon: Icons.business_outlined,
                title: 'Organisation Profile',
                subtitle: 'View or update organisation details',
                onTap: isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OrganisationProfileScreen(profile: profile),
                          ),
                        );
                      },
              ),
              _OrganisationTile(
                icon: Icons.storefront_outlined,
                title: 'Organisation Support Hub',
                subtitle:
                    'Browse published upcycled products and impact reports',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrganisationSupportHubScreen(),
                    ),
                  );
                },
              ),
              _OrganisationTile(
                icon: Icons.event_outlined,
                title: 'Sustainability Events',
                subtitle: 'Create public sustainability event shoutouts',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrganisationEventsScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrganisationTile extends StatelessWidget {
  const _OrganisationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: EcoLoopTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
