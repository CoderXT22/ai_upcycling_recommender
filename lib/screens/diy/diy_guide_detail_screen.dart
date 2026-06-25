import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/diy_guide.dart';

class DiyGuideDetailScreen extends StatelessWidget {
  const DiyGuideDetailScreen({super.key, required this.guide});

  final DiyGuide guide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DIY Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: EcoLoopTheme.softGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.handyman_outlined,
              size: 56,
              color: EcoLoopTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            guide.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            guide.description,
            style: const TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(guide.difficultyLevel)),
              Chip(label: Text(guide.estimatedTime)),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Materials',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...guide.materialsNeeded.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Steps',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...guide.steps.indexed.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: EcoLoopTheme.primary,
                child: Text(
                  '${entry.$1 + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(entry.$2),
            ),
          ),
        ],
      ),
    );
  }
}
