import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/tutorial_models.dart';

class TutorialCatalogRepository {
  static const _assetPath = 'assets/data/tutorial_resources.json';

  Future<TutorialCatalog> loadCatalog() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

    return TutorialCatalog(
      sections: _sectionConfigs.entries.map((entry) {
        final config = entry.value;
        final rawItems = (jsonMap[entry.key] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();

        return TutorialSection(
          key: entry.key,
          title: config.title,
          subtitle: config.subtitle,
          icon: config.icon,
          color: config.color,
          resources: rawItems
              .map(
                (item) => TutorialResource(
                  id: item['id'] as int,
                  title: item['title'] as String? ?? '',
                  url: item['url'] as String? ?? '',
                  description:
                      item['description'] as String? ??
                      item['source'] as String? ??
                      item['focus'] as String? ??
                      '',
                  level:
                      item['level'] as String? ??
                      item['focus'] as String? ??
                      'all',
                  type: _isYouTube(item['url'] as String? ?? '')
                      ? TutorialResourceType.video
                      : TutorialResourceType.article,
                  source: item['source'] as String?,
                  focus: item['focus'] as String?,
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }

  static bool _isYouTube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }
}

class _SectionConfig {
  const _SectionConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

const _sectionConfigs = <String, _SectionConfig>{
  'tutorialVideos': _SectionConfig(
    title: 'Tutorial Videos',
    subtitle: 'Start with the core rules and skill walkthroughs.',
    icon: Icons.ondemand_video_rounded,
    color: Color(0xFF0F766E),
  ),
  'drillCollections': _SectionConfig(
    title: 'Drill Collections',
    subtitle: 'Browse larger drill libraries by skill focus.',
    icon: Icons.dashboard_customize_rounded,
    color: Color(0xFFF97316),
  ),
  'servingResources': _SectionConfig(
    title: 'Serving',
    subtitle: 'Toss, contact, consistency, and progression drills.',
    icon: Icons.sports_tennis_rounded,
    color: Color(0xFF2563EB),
  ),
  'settingResources': _SectionConfig(
    title: 'Setting',
    subtitle: 'Build hand shape, timing, and setter rhythm.',
    icon: Icons.back_hand_rounded,
    color: Color(0xFF7C3AED),
  ),
  'spikingResources': _SectionConfig(
    title: 'Spiking',
    subtitle: 'Approach mechanics and attacking power work.',
    icon: Icons.north_east_rounded,
    color: Color(0xFFDC2626),
  ),
  'blockingResources': _SectionConfig(
    title: 'Blocking',
    subtitle: 'Read the hitter and close the block with intent.',
    icon: Icons.crop_portrait_rounded,
    color: Color(0xFFEA580C),
  ),
  'diggingDefenseResources': _SectionConfig(
    title: 'Digging & Defense',
    subtitle: 'Defensive positioning, reading, and digging reps.',
    icon: Icons.shield_rounded,
    color: Color(0xFF0EA5E9),
  ),
  'warmUpResources': _SectionConfig(
    title: 'Warm-Ups',
    subtitle: 'Get the team moving before technical work starts.',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFF59E0B),
  ),
  'conditioningResources': _SectionConfig(
    title: 'Conditioning',
    subtitle: 'Build jump capacity, stability, and repeat effort.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFF16A34A),
  ),
  'teamBuildingResources': _SectionConfig(
    title: 'Team Building',
    subtitle: 'Cooperative and communication-centered drills.',
    icon: Icons.groups_rounded,
    color: Color(0xFF9333EA),
  ),
  'advancedResources': _SectionConfig(
    title: 'Advanced',
    subtitle: 'Higher-level work for elite athletes and teams.',
    icon: Icons.bolt_rounded,
    color: Color(0xFFB91C1C),
  ),
  'coachingGuides': _SectionConfig(
    title: 'Coaching Guides',
    subtitle: 'Planning support for first-time and developing coaches.',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF475569),
  ),
};
