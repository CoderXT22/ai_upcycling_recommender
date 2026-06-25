class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.caption,
    required this.timeAgo,
    required this.likeCount,
    required this.commentCount,
    required this.colorLabel,
  });

  final String id;
  final String authorName;
  final String caption;
  final String timeAgo;
  final int likeCount;
  final int commentCount;
  final String colorLabel;
}
