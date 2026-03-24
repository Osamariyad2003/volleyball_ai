import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../data/models/tutorial_models.dart';

class TutorialVideoScreen extends StatefulWidget {
  const TutorialVideoScreen({
    super.key,
    required this.resource,
    required this.color,
  });

  final TutorialResource resource;
  final Color color;

  @override
  State<TutorialVideoScreen> createState() => _TutorialVideoScreenState();
}

class _TutorialVideoScreenState extends State<TutorialVideoScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.resource.url);
    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.resource.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_controller != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: widget.color,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: widget.color.withValues(alpha: 0.1),
              ),
              child: const Text(
                'This video could not be embedded. Open it on YouTube instead.',
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.resource.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.resource.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Pill(
                        label: widget.resource.levelLabel,
                        color: widget.color,
                      ),
                      _Pill(
                        label: 'YouTube',
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: _openOnYoutube,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open In YouTube'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOnYoutube() async {
    await launchUrl(
      Uri.parse(widget.resource.url),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}
