import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/constants/selangor_areas.dart';
import '../../models/app_user.dart';
import '../../repositories/community_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../projects/my_projects_screen.dart';
import 'saved_diy_guides_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    final resetEmail = AuthService().currentUser?.email ?? email;
    if (resetEmail.trim().isEmpty) return;

    try {
      await AuthService().sendPasswordReset(resetEmail);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $resetEmail.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send reset email. Please try again later.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = AuthService().currentUser;
    if (firebaseUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<AppUser?>(
        stream: UserRepository().watchUserProfile(firebaseUser.uid),
        builder: (context, snapshot) {
          final appUser =
              snapshot.data ??
              AppUser(
                uid: firebaseUser.uid,
                displayName: firebaseUser.displayName ?? 'EcoLoop User',
                email: firebaseUser.email ?? '',
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(user: appUser),
              const SizedBox(height: 22),
              _StatsRow(userId: firebaseUser.uid),
              const SizedBox(height: 18),
              _ProfileTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update name, phone number, and preferred area',
                onTap: () => _showEditProfileSheet(context, appUser),
              ),
              _ProfileTile(
                icon: Icons.inventory_2_outlined,
                title: 'My Projects',
                subtitle: 'Track started DIY projects and impact reports',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyProjectsScreen(),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.bookmark_border,
                title: 'Saved DIY Guides',
                subtitle: 'Guides bookmarked for later',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SavedDiyGuidesScreen(),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.lock_reset,
                title: 'Change Password',
                subtitle: 'Send password reset email',
                onTap: () => _sendPasswordReset(context, appUser.email),
              ),
              _ProfileTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Return to login screen',
                onTap: () => _logout(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.trim().isNotEmpty
        ? user.displayName
        : 'EcoLoop User';
    final phone = user.phoneNumber.trim().isNotEmpty
        ? user.phoneNumber
        : 'Phone not set';
    final area = user.preferredArea.trim().isNotEmpty
        ? user.preferredArea
        : 'Preferred area not set';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: EcoLoopTheme.primary,
          child: Icon(Icons.person, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 4),
              Text(
                '$area, Selangor',
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: UserRepository().watchCompletedGuideCount(userId),
            builder: (context, snapshot) {
              return _StatCard(
                value: '${snapshot.data ?? 0}',
                label: 'DIY Done',
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<int>(
            stream: UserRepository().watchRecyclingActivityCount(userId),
            builder: (context, snapshot) {
              return _StatCard(
                value: '${snapshot.data ?? 0}',
                label: 'Recycled',
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<int>(
            stream: CommunityRepository().watchUserPostCount(userId),
            builder: (context, snapshot) {
              return _StatCard(value: '${snapshot.data ?? 0}', label: 'Posts');
            },
          ),
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

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final AppUser user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _preferredArea;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _preferredArea = SelangorAreas.values.contains(widget.user.preferredArea)
        ? widget.user.preferredArea
        : SelangorAreas.values.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await UserRepository().updateUserProfile(
      uid: widget.user.uid,
      displayName: _nameController.text,
      phoneNumber: _phoneController.text,
      preferredArea: _preferredArea,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _preferredArea,
            decoration: const InputDecoration(
              labelText: 'Preferred Selangor area',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: SelangorAreas.values
                .map((area) => DropdownMenuItem(value: area, child: Text(area)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _preferredArea = value);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
