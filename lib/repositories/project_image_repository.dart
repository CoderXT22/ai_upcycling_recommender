import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProjectImageRepository {
  ProjectImageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadBeforePhoto({
    required String userId,
    required String sessionId,
    required XFile image,
  }) async {
    return _uploadProjectPhoto(
      userId: userId,
      sessionId: sessionId,
      image: image,
      fileLabel: 'before',
    );
  }

  Future<String> uploadAfterPhoto({
    required String userId,
    required String sessionId,
    required XFile image,
  }) async {
    return _uploadProjectPhoto(
      userId: userId,
      sessionId: sessionId,
      image: image,
      fileLabel: 'after',
    );
  }

  Future<String> _uploadProjectPhoto({
    required String userId,
    required String sessionId,
    required XFile image,
    required String fileLabel,
  }) async {
    final extension = _extensionForPath(image.path);
    final reference = _storage.ref(
      'project_sessions/$userId/$sessionId/$fileLabel.$extension',
    );
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
