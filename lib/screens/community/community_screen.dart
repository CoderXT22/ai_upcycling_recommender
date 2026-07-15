import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../mock/mock_data.dart';
import '../../models/community_comment.dart';
import '../../models/community_post.dart';
import '../../repositories/community_repository.dart';
import '../../services/auth_service.dart';
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
        StreamBuilder<List<CommunityPost>>(
          stream: CommunityRepository().watchPublicPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Showing sample posts while Firestore is unavailable.',
                      style: TextStyle(color: EcoLoopTheme.mutedText),
                    ),
                  ),
                  ...mockPosts.map((post) => _PostCard(post: post)),
                ],
              );
            }

            final posts = snapshot.data ?? const <CommunityPost>[];
            if (posts.isEmpty) return const _EmptyCommunityState();

            return Column(
              children: posts.map((post) => _PostCard(post: post)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  Future<void> _toggleLike(BuildContext context) async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts.')),
      );
      return;
    }

    await CommunityRepository().toggleLike(postId: post.id, userId: userId);
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid;

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
            _PostImagePlaceholder(post: post),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (userId == null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _toggleLike(context),
                          icon: const Icon(Icons.favorite_border),
                        )
                      else
                        StreamBuilder<bool>(
                          stream: CommunityRepository().watchIsLiked(
                            postId: post.id,
                            userId: userId,
                          ),
                          builder: (context, snapshot) {
                            final isLiked = snapshot.data ?? false;
                            return IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _toggleLike(context),
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked
                                    ? Colors.redAccent
                                    : EcoLoopTheme.text,
                              ),
                            );
                          },
                        ),
                      Text('${post.likeCount}'),
                      const SizedBox(width: 12),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openComments(context),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      Text('${post.commentCount}'),
                    ],
                  ),
                  const SizedBox(height: 6),
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

class _PostImagePlaceholder extends StatelessWidget {
  const _PostImagePlaceholder({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    if (post.imageUrl.isNotEmpty) {
      return Image.network(
        post.imageUrl,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _LabelBox(label: post.colorLabel),
      );
    }
    return _LabelBox(label: post.colorLabel);
  }
}

class _LabelBox extends StatelessWidget {
  const _LabelBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      color: EcoLoopTheme.softGreen,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: EcoLoopTheme.primaryDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.post});

  final CommunityPost post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    await CommunityRepository().addComment(
      postId: widget.post.id,
      userId: user.uid,
      authorName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'EcoLoop User',
      text: _commentController.text,
    );
    _commentController.clear();
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<CommunityComment>>(
                stream: CommunityRepository().watchComments(widget.post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data ?? const <CommunityComment>[];
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet. Start the conversation!',
                        style: TextStyle(color: EcoLoopTheme.mutedText),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: EcoLoopTheme.softGreen,
                          child: Icon(
                            Icons.person_outline,
                            color: EcoLoopTheme.primary,
                          ),
                        ),
                        title: Text(
                          comment.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(comment.text),
                        trailing: Text(
                          comment.createdAtText,
                          style: const TextStyle(
                            color: EcoLoopTheme.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (user == null)
              const Text('Please log in to comment.')
            else ...[
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: _isSending ? 'Posting...' : 'Post Comment',
                icon: Icons.send_outlined,
                onPressed: _isSending ? () {} : _addComment,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No community posts yet. Share the first DIY project!',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
        ),
      ),
    );
  }
}
