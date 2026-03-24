import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/ai_chat_message.dart';

class AiChatBubble extends StatefulWidget {
  const AiChatBubble({required this.message, super.key});

  final AiChatMessage message;

  @override
  State<AiChatBubble> createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<AiChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: Offset(widget.message.role.isUser ? 0.16 : -0.16, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.role.isUser;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 8),
                  bottomRight: Radius.circular(isUser ? 8 : 22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'Your Request' : 'Exercise Coach',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isUser
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.82)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isUser)
                    Text(
                      widget.message.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        height: 1.35,
                      ),
                    )
                  else
                    _AssistantWorkoutContent(content: widget.message.content),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.jm().format(widget.message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUser
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.72)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantWorkoutContent extends StatelessWidget {
  const _AssistantWorkoutContent({required this.content});

  final String content;

  static const Map<String, String> _fieldLabels = {
    'workout name': 'Workout Name',
    'exercise name': 'Exercise Name',
    'exercise': 'Exercise',
    'goal': 'Goal',
    'exercises': 'Exercises',
    'sets': 'Sets',
    'reps': 'Reps',
    'duration': 'Duration',
    'rest': 'Rest',
    'notes': 'Notes',
    'focus': 'Focus',
    'warm-up': 'Warm-up',
    'warm up': 'Warm-up',
    'warmup': 'Warm-up',
    'cooldown': 'Cooldown',
    'cool-down': 'Cooldown',
    'cool down': 'Cooldown',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = _parseSections();
    final workoutPlan = _extractWorkoutPlan(sections);
    if (workoutPlan != null) {
      return _WorkoutPlanCanvas(plan: workoutPlan);
    }

    if (sections.any((section) => section.type != _WorkoutSectionType.plainText)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < sections.length; index++) ...[
            _buildSection(context, sections[index]),
            if (index != sections.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    final lines = _normalizedLines();

    if (lines.isEmpty) {
      return Text(
        _stripMarkdown(content),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          height: 1.35,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          _buildLine(context, line),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  _WorkoutPlanData? _extractWorkoutPlan(List<_WorkoutSection> sections) {
    if (sections.isEmpty) {
      return null;
    }

    String? workoutName;
    String? goal;
    String? rest;
    String? notes;
    final exercises = <String>[];
    final extraBlocks = <_WorkoutExtraBlock>[];

    for (final section in sections) {
      if (section.type == _WorkoutSectionType.plainText) {
        continue;
      }

      switch (section.label) {
        case 'Workout Name':
        case 'Exercise Name':
        case 'Exercise':
          workoutName ??= section.items.join(' ').trim();
          break;
        case 'Goal':
          goal ??= section.items.join(' ').trim();
          break;
        case 'Exercises':
          exercises.addAll(
            section.items
                .map(_stripBulletPrefix)
                .where((item) => item.trim().isNotEmpty),
          );
          break;
        case 'Rest':
          rest ??= section.items.join(' ').trim();
          break;
        case 'Notes':
          notes ??= section.items.join(' ').trim();
          break;
        default:
          extraBlocks.add(
            _WorkoutExtraBlock(
              title: section.label,
              items: List<String>.from(section.items),
            ),
          );
      }
    }

    final hasCoreContent =
        workoutName != null ||
        goal != null ||
        exercises.isNotEmpty ||
        rest != null ||
        notes != null;
    if (!hasCoreContent) {
      return null;
    }

    return _WorkoutPlanData(
      workoutName: workoutName,
      goal: goal,
      exercises: exercises,
      rest: rest,
      notes: notes,
      extraBlocks: extraBlocks,
    );
  }

  List<_WorkoutSection> _parseSections() {
    final lines = _normalizedLines();

    if (lines.isEmpty) {
      return const [];
    }

    final sections = <_WorkoutSection>[];
    String? activeLabel;
    _WorkoutSectionType? activeType;
    final activeItems = <String>[];
    var structuredSectionCount = 0;

    void flushActiveSection() {
      if (activeLabel == null || activeItems.isEmpty || activeType == null) {
        activeLabel = null;
        activeType = null;
        activeItems.clear();
        return;
      }

      sections.add(
        _WorkoutSection(
          label: activeLabel!,
          items: List<String>.from(activeItems),
          type: activeType!,
        ),
      );
      if (activeType != _WorkoutSectionType.plainText) {
        structuredSectionCount++;
      }
      activeLabel = null;
      activeType = null;
      activeItems.clear();
    }

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final nextLine = index + 1 < lines.length ? lines[index + 1] : null;
      final sectionHeaderMatch = RegExp(r'^([A-Za-z -]+)\s*:\s*$').firstMatch(
        line,
      );
      if (sectionHeaderMatch != null) {
        final normalizedLabel = _normalizeLabel(
          sectionHeaderMatch.group(1) ?? '',
        );
        final label = _fieldLabels[normalizedLabel];
        if (label != null) {
          flushActiveSection();
          activeLabel = label;
          activeType = _isTitleLabel(normalizedLabel)
              ? _WorkoutSectionType.title
              : _WorkoutSectionType.labeledCard;
          continue;
        }
      }

      final inlineField = _parseField(line);
      if (inlineField != null) {
        flushActiveSection();
        sections.add(
          _WorkoutSection(
            label: inlineField.label,
            items: [inlineField.value],
            type: inlineField.type,
          ),
        );
        structuredSectionCount++;
        continue;
      }

      if (_looksLikeWorkoutBlockHeader(line, nextLine)) {
        flushActiveSection();
        activeLabel = line;
        activeType = _WorkoutSectionType.blockCard;
        continue;
      }

      if (activeLabel != null) {
        activeItems.add(line);
        continue;
      }

      sections.add(
        _WorkoutSection(
          label: '',
          items: [line],
          type: _WorkoutSectionType.plainText,
        ),
      );
    }

    flushActiveSection();
    return structuredSectionCount >= 2 ? sections : const [];
  }

  Widget _buildSection(BuildContext context, _WorkoutSection section) {
    final theme = Theme.of(context);

    switch (section.type) {
      case _WorkoutSectionType.title:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            section.items.join(' '),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case _WorkoutSectionType.blockCard:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < section.items.length; index++) ...[
                _buildSectionItem(
                  context,
                  section.items[index],
                  forceBullet: true,
                ),
                if (index != section.items.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      case _WorkoutSectionType.labeledCard:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (var index = 0; index < section.items.length; index++) ...[
                _buildSectionItem(
                  context,
                  section.items[index],
                  forceBullet: section.label == 'Exercises',
                ),
                if (index != section.items.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      case _WorkoutSectionType.plainText:
        return _buildLine(context, section.items.first);
    }
  }

  Widget _buildSectionItem(
    BuildContext context,
    String line, {
    bool forceBullet = false,
  }) {
    final theme = Theme.of(context);
    final bulletText = _stripBulletPrefix(line);
    final shouldUseBullet = forceBullet || _isBullet(line) || !line.contains(':');

    if (shouldUseBullet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Expanded(
            child: Text(
              bulletText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      line,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.35,
      ),
    );
  }

  Widget _buildLine(BuildContext context, String line) {
    final theme = Theme.of(context);
    final field = _parseField(line);
    if (field != null) {
      if (field.type == _WorkoutSectionType.title) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            field.value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              field.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    if (_isBullet(line)) {
      final bulletText = _stripBulletPrefix(line);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Expanded(
            child: Text(
              bulletText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      line,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.35,
      ),
    );
  }

  _WorkoutField? _parseField(String line) {
    final match = RegExp(r'^([A-Za-z -]+)\s*:\s*(.+)$').firstMatch(line);
    if (match == null) {
      return null;
    }

    final normalizedLabel = _normalizeLabel(match.group(1) ?? '');
    final value = match.group(2)?.trim() ?? '';
    final label = _fieldLabels[normalizedLabel];
    if (label == null || value.isEmpty) {
      return null;
    }

    return _WorkoutField(
      label: label,
      value: _stripMarkdown(value),
      type: _isTitleLabel(normalizedLabel)
          ? _WorkoutSectionType.title
          : _WorkoutSectionType.labeledCard,
    );
  }

  bool _isTitleLabel(String normalizedLabel) {
    return normalizedLabel == 'workout name' ||
        normalizedLabel == 'exercise name' ||
        normalizedLabel == 'exercise';
  }

  bool _looksLikeWorkoutBlockHeader(String line, String? nextLine) {
    if (nextLine == null || line.isEmpty || _isBullet(line) || line.contains(':')) {
      return false;
    }

    final normalized = _normalizeLabel(line);
    final looksLikeBlock = normalized.contains('warm-up') ||
        normalized.contains('warm up') ||
        normalized.contains('warmup') ||
        normalized.contains('cooldown') ||
        normalized.contains('cool-down') ||
        normalized.contains('cool down') ||
        normalized.contains('activation') ||
        normalized.contains('mobility') ||
        normalized.contains('circuit') ||
        normalized.contains('drill') ||
        normalized.contains('strength') ||
        normalized.contains('power') ||
        normalized.contains('recovery') ||
        normalized.contains('finisher') ||
        normalized.contains('plyometric') ||
        normalized.contains('conditioning') ||
        normalized.contains('block') ||
        normalized.contains('jump');

    final isCompactHeading =
        line.length <= 48 && line.split(RegExp(r'\s+')).length <= 6;
    final nextLooksLikeWorkoutItem =
        _isBullet(nextLine) || _looksLikeExerciseLine(nextLine);

    return nextLooksLikeWorkoutItem && (looksLikeBlock || isCompactHeading);
  }

  bool _looksLikeExerciseLine(String line) {
    final normalized = _normalizeLabel(line);
    return normalized.contains(' x ') ||
        normalized.contains('each leg') ||
        normalized.contains('seconds') ||
        normalized.contains('second') ||
        normalized.contains('minutes') ||
        normalized.contains('minute') ||
        normalized.contains('sec') ||
        normalized.contains('min');
  }

  List<String> _normalizedLines() {
    return content
        .split('\n')
        .map((line) => _stripMarkdown(line.trim()))
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _normalizeLabel(String value) {
    return _stripMarkdown(value).trim().toLowerCase();
  }

  String _stripMarkdown(String value) {
    var sanitized = value.replaceAll('\r', '').trim();
    sanitized = sanitized.replaceAll(RegExp(r'\*\*'), '');
    sanitized = sanitized.replaceAll(RegExp(r'__'), '');
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'^\*([^*].*?)\*$'),
      (match) => match.group(1) ?? '',
    );
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'^_([^_].*?)_$'),
      (match) => match.group(1) ?? '',
    );
    return sanitized.trim();
  }

  String _stripBulletPrefix(String line) {
    return line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim();
  }

  bool _isBullet(String line) => line.startsWith('- ') || line.startsWith('* ');
}

class _WorkoutPlanCanvas extends StatelessWidget {
  const _WorkoutPlanCanvas({required this.plan});

  final _WorkoutPlanData plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _TemplateNode(
            label: 'Response Template',
            icon: Icons.account_tree_outlined,
          ),
        ),
        Container(
          width: 2,
          height: 16,
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        if (plan.workoutName != null) ...[
          _TitlePlanCard(title: plan.workoutName!),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (plan.goal != null)
              _InfoPlanCard(
                label: 'Goal',
                icon: Icons.track_changes_rounded,
                content: plan.goal!,
              ),
            if (plan.rest != null)
              _InfoPlanCard(
                label: 'Rest Time',
                icon: Icons.timer_outlined,
                content: plan.rest!,
              ),
            if (plan.notes != null)
              _InfoPlanCard(
                label: 'Safety Notes',
                icon: Icons.health_and_safety_outlined,
                content: plan.notes!,
              ),
          ],
        ),
        if (plan.goal != null || plan.rest != null || plan.notes != null)
          const SizedBox(height: 12),
        if (plan.exercises.isNotEmpty) ...[
          _ExercisesPlanCard(exercises: plan.exercises),
          const SizedBox(height: 12),
        ],
        for (var index = 0; index < plan.extraBlocks.length; index++) ...[
          _ExtraWorkoutBlock(block: plan.extraBlocks[index]),
          if (index != plan.extraBlocks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TemplateNode extends StatelessWidget {
  const _TemplateNode({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitlePlanCard extends StatelessWidget {
  const _TitlePlanCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKOUT NAME',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPlanCard extends StatelessWidget {
  const _InfoPlanCard({
    required this.label,
    required this.icon,
    required this.content,
  });

  final String label;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = (MediaQuery.sizeOf(context).width - 74) / 2;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width.clamp(120, 150).toDouble()),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisesPlanCard extends StatelessWidget {
  const _ExercisesPlanCard({required this.exercises});

  final List<String> exercises;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Exercises List',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < exercises.length; index++) ...[
            _ExerciseListItem(
              index: index + 1,
              text: exercises[index],
            ),
            if (index != exercises.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  const _ExerciseListItem({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$index',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtraWorkoutBlock extends StatelessWidget {
  const _ExtraWorkoutBlock({required this.block});

  final _WorkoutExtraBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < block.items.length; index++) ...[
            _ExerciseBulletLine(text: block.items[index]),
            if (index != block.items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ExerciseBulletLine extends StatelessWidget {
  const _ExerciseBulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7, right: 8),
          child: Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutField {
  const _WorkoutField({
    required this.label,
    required this.value,
    required this.type,
  });

  final String label;
  final String value;
  final _WorkoutSectionType type;
}

class _WorkoutSection {
  const _WorkoutSection({
    required this.label,
    required this.items,
    required this.type,
  });

  final String label;
  final List<String> items;
  final _WorkoutSectionType type;
}

enum _WorkoutSectionType { title, labeledCard, blockCard, plainText }

class _WorkoutPlanData {
  const _WorkoutPlanData({
    required this.workoutName,
    required this.goal,
    required this.exercises,
    required this.rest,
    required this.notes,
    required this.extraBlocks,
  });

  final String? workoutName;
  final String? goal;
  final List<String> exercises;
  final String? rest;
  final String? notes;
  final List<_WorkoutExtraBlock> extraBlocks;
}

class _WorkoutExtraBlock {
  const _WorkoutExtraBlock({required this.title, required this.items});

  final String title;
  final List<String> items;
}
