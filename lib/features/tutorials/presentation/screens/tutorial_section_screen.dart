import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/tutorial_models.dart';
import '../widgets/tutorial_resource_card.dart';
import 'tutorial_video_screen.dart';

class TutorialSectionScreen extends StatelessWidget {
  const TutorialSectionScreen({super.key, required this.section});

  final TutorialSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: section.resources.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final resource = section.resources[index];
          return TutorialResourceCard(
            resource: resource,
            color: section.color,
            onTap: () => _openResource(context, resource),
          );
        },
      ),
    );
  }

  Future<void> _openResource(
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
