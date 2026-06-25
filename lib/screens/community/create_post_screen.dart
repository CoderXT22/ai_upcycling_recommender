import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/primary_button.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share DIY Project')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: EcoLoopTheme.softGreen,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EcoLoopTheme.border),
            ),
            child: const Column(
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
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Write a caption about your project...',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Post to Community',
            icon: Icons.send_outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
