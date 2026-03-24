import 'package:flutter/material.dart';

enum TutorialResourceType { video, article }

class TutorialCatalog {
  const TutorialCatalog({required this.sections});

  final List<TutorialSection> sections;

  int get totalResources => sections.fold<int>(
    0,
    (count, section) => count + section.resources.length,
  );

  List<TutorialResource> get featuredVideos => sections
      .expand((section) => section.resources)
      .where((resource) => resource.type == TutorialResourceType.video)
      .take(6)
      .toList();
}

class TutorialSection {
  const TutorialSection({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.resources,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<TutorialResource> resources;
}

class TutorialResource {
  const TutorialResource({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
    required this.level,
    required this.type,
    required this.source,
    required this.focus,
  });

  final int id;
  final String title;
  final String url;
  final String description;
  final String level;
  final TutorialResourceType type;
  final String? source;
  final String? focus;

  bool get isVideo => type == TutorialResourceType.video;

  String get levelLabel => level.isEmpty ? 'all levels' : level;
}
