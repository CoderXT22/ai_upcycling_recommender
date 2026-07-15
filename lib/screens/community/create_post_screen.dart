import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../repositories/community_image_repository.dart';
import '../../repositories/community_repository.dart';
import '../../services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _labelController = TextEditingController();
  XFile? _selectedImage;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final user = AuthService().currentUser;
    final caption = _captionController.text.trim();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before posting.')),
      );
      return;
    }

    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a caption first.')),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final imageUrl = _selectedImage == null
          ? ''
          : await CommunityImageRepository().uploadPostImage(
              userId: user.uid,
              image: _selectedImage!,
            );
      await CommunityRepository().createPost(
        userId: user.uid,
        authorName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'EcoLoop User',
        caption: caption,
        imageUrl: imageUrl,
        colorLabel: _labelController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is FirebaseException
          ? 'Unable to post: ${error.code}'
          : 'Unable to post. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1400,
      );
      if (image == null || !mounted) return;
      setState(() => _selectedImage = image);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select image. Try again.')),
      );
    }
  }

  Future<void> _showImageSourceSheet() {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Add DIY Project Image',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text('Take a photo or choose one from gallery.'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Select From Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share DIY Project')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: _isPosting ? null : _showImageSourceSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: EcoLoopTheme.softGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EcoLoopTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: EcoLoopTheme.primary,
                          size: 44,
                        ),
                        SizedBox(height: 8),
                        Text('Upload completed DIY image'),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: FilledButton.icon(
                            onPressed: _isPosting
                                ? null
                                : _showImageSourceSheet,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Change'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Project label',
              hintText: 'e.g. Bottle planter, Cardboard organizer',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _captionController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Write a caption about your project...',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _isPosting ? 'Posting...' : 'Post to Community',
            icon: Icons.send_outlined,
            onPressed: _isPosting ? () {} : _createPost,
          ),
        ],
      ),
    );
  }
}
