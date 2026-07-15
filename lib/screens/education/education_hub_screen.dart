import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../mock/mock_data.dart';
import '../../models/education_article.dart';
import '../../repositories/education_repository.dart';
import '../../services/link_launcher_service.dart';

class EducationHubScreen extends StatelessWidget {
  const EducationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Learn sustainable waste habits',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Practical tips with source references for recycling, upcycling, and daily sorting.',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<EducationArticle>>(
            stream: EducationRepository().watchActiveArticles(),
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
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Showing sample content while Firestore is unavailable.',
                        style: TextStyle(color: EcoLoopTheme.mutedText),
                      ),
                    ),
                    ...mockArticles.map(
                      (article) => _ArticleCard(article: article),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const _EmptyEducationState();
              }

              final articles = snapshot.data!;

              return Column(
                children: articles
                    .map((article) => _ArticleCard(article: article))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final EducationArticle article;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArticleReaderScreen(article: article),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: EcoLoopTheme.softGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: article.imageUrl.isEmpty
                      ? const Icon(
                          Icons.lightbulb_outline,
                          color: EcoLoopTheme.primary,
                        )
                      : Image.network(
                          article.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.lightbulb_outline,
                            color: EcoLoopTheme.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.category,
                        style: const TextStyle(
                          color: EcoLoopTheme.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.summary,
                        style: const TextStyle(color: EcoLoopTheme.mutedText),
                      ),
                      if (article.readTime.isNotEmpty ||
                          _sourceLine(article).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _educationMetaLine(article),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArticleReaderScreen extends StatelessWidget {
  const ArticleReaderScreen({super.key, required this.article});

  final EducationArticle article;

  @override
  Widget build(BuildContext context) {
    final content = article.content.trim().isEmpty
        ? article.summary
        : article.content;

    return Scaffold(
      appBar: AppBar(title: const Text('Education Article')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (article.imageUrl.isNotEmpty) ...[
            Container(
              height: 180,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: EcoLoopTheme.softGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.lightbulb_outline,
                  color: EcoLoopTheme.primary,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            article.category,
            style: const TextStyle(
              color: EcoLoopTheme.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          if (_sourceLine(article).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _sourceLine(article),
              style: const TextStyle(color: EcoLoopTheme.mutedText),
            ),
          ],
          if (article.readTime.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              article.readTime,
              style: const TextStyle(color: EcoLoopTheme.mutedText),
            ),
          ],
          if (article.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: article.tags
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.45)),
          if (article.sourceUrl.isNotEmpty ||
              article.sourceTitle.isNotEmpty) ...[
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.link_outlined,
                  color: EcoLoopTheme.primary,
                ),
                title: Text(
                  article.sourceTitle.isEmpty
                      ? 'Reference source'
                      : article.sourceTitle,
                ),
                subtitle: Text(
                  article.sourceUrl.isEmpty
                      ? article.sourceType
                      : article.sourceUrl,
                ),
                trailing: article.sourceUrl.isEmpty
                    ? null
                    : const Icon(Icons.open_in_new),
                onTap: article.sourceUrl.isEmpty
                    ? null
                    : () => const LinkLauncherService().openUrl(
                        context,
                        article.sourceUrl,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyEducationState extends StatelessWidget {
  const _EmptyEducationState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No education content found in Firestore yet. Add documents under education_articles to display them here.',
          style: TextStyle(color: EcoLoopTheme.mutedText),
        ),
      ),
    );
  }
}

String _sourceLine(EducationArticle article) {
  if (article.sourceTitle.isNotEmpty && article.sourceType.isNotEmpty) {
    return '${article.sourceType}: ${article.sourceTitle}';
  }
  if (article.sourceTitle.isNotEmpty) return article.sourceTitle;
  return article.sourceType;
}

String _educationMetaLine(EducationArticle article) {
  final parts = [
    if (article.readTime.isNotEmpty) article.readTime,
    if (_sourceLine(article).isNotEmpty) _sourceLine(article),
  ];
  return parts.join(' - ');
}
