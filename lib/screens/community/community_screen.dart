import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../mock/mock_data.dart';
import '../../models/community_post.dart';
import '../events/sustainability_events_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Community')),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SustainabilityEventsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.event_outlined, size: 16),
                label: const Text('Events'),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        ...mockPosts.map((post) => _PostCard(post: post)),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: EcoLoopTheme.softGreen,
                    child: Icon(Icons.eco, color: EcoLoopTheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                          color: EcoLoopTheme.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 190,
              width: double.infinity,
              color: EcoLoopTheme.softGreen,
              alignment: Alignment.center,
              child: Text(
                post.colorLabel,
                style: const TextStyle(
                  color: EcoLoopTheme.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 20),
                      const SizedBox(width: 4),
                      Text('${post.likeCount}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline, size: 20),
                      const SizedBox(width: 4),
                      Text('${post.commentCount}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
