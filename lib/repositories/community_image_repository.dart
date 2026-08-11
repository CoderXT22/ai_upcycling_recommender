import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CommunityImageRepository {
  CommunityImageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadPostImage({
    required String userId,
    required XFile image,
  }) async {
    final extension = _extensionForPath(image.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final reference = _storage.ref('community_posts/$userId/$fileName');

    final uploadTask = await reference.putData(
      await image.readAsBytes(),
      SettableMetadata(contentType: _contentTypeForExtension(extension)),
    );

    return uploadTask.ref.getDownloadURL();
  }

  String _extensionForPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'png';
    if (lowerPath.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
