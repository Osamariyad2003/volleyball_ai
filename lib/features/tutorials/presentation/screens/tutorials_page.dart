import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/tutorial_providers.dart';
import '../../data/models/tutorial_models.dart';
import '../widgets/tutorial_resource_card.dart';
import 'tutorial_section_screen.dart';
import 'tutorial_video_screen.dart';

class TutorialsPage extends ConsumerWidget {
  const TutorialsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(tutorialCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Volleyball Tutorials')),
      body: catalogAsync.when(
        data: (catalog) => _TutorialCatalogView(catalog: catalog),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load tutorial resources right now.\n$error'),
          ),
        ),
      ),
    );
  }
}

class _TutorialCatalogView extends StatelessWidget {
  const _TutorialCatalogView({required this.catalog});

  final TutorialCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tutorial Library',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${catalog.sections.length} sections and ${catalog.totalResources} curated volleyball resources, divided by skill and coaching need.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Featured Videos', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: catalog.featuredVideos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final resource = catalog.featuredVideos[index];
              return _FeaturedVideoCard(resource: resource);
            },
          ),
        ),
        const SizedBox(height: 22),
        Text('Browse By Section', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        ...catalog.sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SectionCard(section: section),
          ),
        ),
      ],
    );
  }
}

class _FeaturedVideoCard extends StatelessWidget {
  const _FeaturedVideoCard({required this.resource});

  final TutorialResource resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoId = resource.url.contains('watch?v=')
        ? resource.url.split('watch?v=').last.split('&').first
        : '';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TutorialVideoScreen(
              resource: resource,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.cardColor,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  Image.network(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill_rounded, size: 48),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    resource.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final TutorialSection section;

  @override
  Widget build(BuildContext context) {
    final preview = section.resources.take(2).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(section.icon, color: section.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(section.subtitle),
                    ],
                  ),
                ),
                Text('${section.resources.length}'),
              ],
            ),
            const SizedBox(height: 14),
            ...preview.map(
              (resource) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TutorialResourceCard(
                  resource: resource,
                  color: section.color,
                  onTap: () => _openPreview(context, resource),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TutorialSectionScreen(section: section),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Open Section'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPreview(
    BuildContext context,
    TutorialResource resource,
  ) async {
    if (resource.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TutorialVideoScreen(resource: resource, color: section.color),
        ),
      );
      return;
    }

    await launchUrl(
      Uri.parse(resource.url),
      mode: LaunchMode.externalApplication,
    );
  }
}
