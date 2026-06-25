import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: EcoLoopTheme.primary,
                child: Icon(Icons.person, color: Colors.white, size: 34),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yeow Xin Ting',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Selangor, Malaysia',
                    style: TextStyle(color: EcoLoopTheme.mutedText),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _StatsRow(),
          const SizedBox(height: 18),
          const _ProfileTile(
            icon: Icons.bookmark_border,
            title: 'Saved DIY Guides',
            subtitle: 'Guides bookmarked for later',
          ),
          const _ProfileTile(
            icon: Icons.location_on_outlined,
            title: 'Preferred Location',
            subtitle: 'Used for Selangor centre suggestions',
          ),
          const _ProfileTile(
            icon: Icons.history,
            title: 'Activity Summary',
            subtitle: 'Completed DIY, recycling, and shared posts',
          ),
          const _ProfileTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Return to login screen',
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(value: '8', label: 'DIY Done'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(value: '12', label: 'Recycled'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(value: '3', label: 'Posts'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: EcoLoopTheme.primaryDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: EcoLoopTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
