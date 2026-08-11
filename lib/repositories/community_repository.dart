import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_comment.dart';
import '../models/community_post.dart';

class CommunityRepository {
  CommunityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  Stream<List<CommunityPost>> watchPublicPosts() {
    return _posts.where('visibility', isEqualTo: 'public').snapshots().map((
      snapshot,
    ) {
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = _timestampMillis(a.data()['created_at']);
          final bTime = _timestampMillis(b.data()['created_at']);
          return bTime.compareTo(aTime);
        });
      return docs.map(CommunityPost.fromFirestore).toList();
    });
  }

  Stream<int> watchUserPostCount(String userId) {
    return _posts
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<CommunityComment>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CommunityComment.fromFirestore).toList(),
        );
  }

  Stream<bool> watchIsLiked({required String postId, required String userId}) {
    return _posts
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> createPost({
    required String userId,
    required String authorName,
    required String caption,
    String imageUrl = '',
    String colorLabel = 'DIY project',
  }) {
    return _posts.add({
      'user_id': userId,
      'author_name': authorName,
      'caption': caption.trim(),
      'image_url': imageUrl,
      'color_label': colorLabel.trim().isEmpty ? 'DIY project' : colorLabel,
      'like_count': 0,
      'comment_count': 0,
      'visibility': 'public',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postReference = _posts.doc(postId);
    final likeReference = postReference.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeReference);
      if (likeSnapshot.exists) {
        transaction.delete(likeReference);
        transaction.update(postReference, {
          'like_count': FieldValue.increment(-1),
          'updated_at': FieldValue.serverTimestamp(),
        });
        return;
      }

      transaction.set(likeReference, {
        'user_id': userId,
        'created_at': FieldValue.serverTimestamp(),
      });
      transaction.update(postReference, {
        'like_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String authorName,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final postReference = _posts.doc(postId);
    await postReference.collection('comments').add({
      'user_id': userId,
      'author_name': authorName,
      'text': trimmedText,
      'created_at': FieldValue.serverTimestamp(),
    });
    await postReference.update({
      'comment_count': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}

int _timestampMillis(Object? value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  return 0;
}
