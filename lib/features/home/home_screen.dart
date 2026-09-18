import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/strings.dart';
import '../../data/local/progress_repository.dart';
import '../../data/models/passage.dart';
import '../../data/models/topic.dart';
import '../../data/providers.dart';
import '../../ui/theme/app_theme.dart';
import '../player/playback/playback_timeline.dart';
import '../../ui/widgets/echora_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTopic,
    required this.onOpenPassage,
  });

  final void Function(String topicId) onOpenTopic;
  final void Function(String passageId) onOpenPassage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider);
    final resumable = ref.watch(resumableProgressProvider).value;
    final resumablePassage = resumable == null
        ? null
        : ref.watch(passageProvider(resumable.passageId)).value;

    return EchoraScaffold(
      slivers: [
        const SliverToBoxAdapter(child: _Header()),
        const SliverGap(AppSpacing.sectionGap),
        SliverToBoxAdapter(
          child: resumable != null && resumablePassage != null
              ? _ContinueCard(
                  passage: resumablePassage,
                  progress: resumable,
                  onTap: () => onOpenPassage(resumablePassage.id),
                )
              : const _StartHereCard(),
        ),
        const SliverGap(AppSpacing.sectionGap),
        SliverToBoxAdapter(
          child: Text(
            Strings.topicsSectionTitle,
            style: context.typography.displaySmall,
          ),
        ),
        const SliverGap(AppSpacing.md),
        switch (topics) {
          AsyncData(:final value) => _TopicGrid(
            topics: value,
            onOpenTopic: onOpenTopic,
          ),
          AsyncError(:final error) => SliverToBoxAdapter(
            child: Text('$error', style: context.typography.bodySmall),
          ),
          _ => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = DateTime.now();
    final streak = ref.watch(practiceStatsProvider).value?.streakDays ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatVietnameseDate(now),
                style: context.typography.caption.copyWith(
                  color: colors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(greetingFor(now), style: context.typography.displayLarge),
            ],
          ),
        ),
        _StreakChip(days: streak),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    if (days == 0) return const SizedBox.shrink();

    final accent = context.colors.amber;
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smPlus,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.tint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: accent.tintBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 15, color: accent.base),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            Strings.streakDays(days),
            style: context.typography.caption.copyWith(color: accent.onTint),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.passage,
    required this.progress,
    required this.onTap,
  });

  final Passage passage;
  final PassageProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.violet;

    final totalMs = passage.wordCount / kReferenceWpm * 60000;
    final ratio = (progress.positionMs / totalMs).clamp(0.0, 1.0);
    final remainingMin = ((totalMs - progress.positionMs) / 60000).ceil();

    return Material(
      color: accent.tint,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: accent.tintBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Strings.continueTitle,
                style: context.typography.caption.copyWith(
                  color: accent.onTint,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                passage.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.displaySmall.copyWith(
                  color: accent.onTint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: colors.surface,
                  valueColor: AlwaysStoppedAnimation(accent.base),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Strings.completedPercent((ratio * 100).round()),
                    style: context.typography.caption.copyWith(
                      color: accent.onTint,
                    ),
                  ),
                  Text(
                    Strings.remainingMinutes(remainingMin),
                    style: context.typography.caption.copyWith(
                      color: accent.onTint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartHereCard extends StatelessWidget {
  const _StartHereCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.violet;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: accent.tint,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.tintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.emptyStateTitle,
            style: context.typography.displaySmall.copyWith(
              color: accent.onTint,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Strings.emptyStateBody,
            style: context.typography.bodySmall.copyWith(color: accent.onTint),
          ),
        ],
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.topics, required this.onOpenTopic});

  final List<Topic> topics;
  final void Function(String topicId) onOpenTopic;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      itemCount: topics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.gridGap,
        crossAxisSpacing: AppSpacing.gridGap,
        mainAxisExtent: 148,
      ),
      itemBuilder: (context, index) => TopicCard(
        topic: topics[index],
        onTap: () => onOpenTopic(topics[index].id),
      ),
    );
  }
}

class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.topic, required this.onTap});

  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.byToken(topic.colorToken);
    final locked = topic.comingSoon;

    final background = locked ? colors.surfaceMuted : accent.tint;
    final borderColor = locked ? colors.border : accent.tintBorder;
    final titleColor = locked ? colors.inkFaint : accent.onTint;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: context.typography.displaySmall.copyWith(
                  color: titleColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: Text(
                  topic.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.caption.copyWith(
                    color: locked ? colors.inkFaint : accent.onTint,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TopicBadge(
                label: locked ? Strings.comingSoon : topic.levelRange,
                foreground: locked ? colors.inkFaint : accent.base,
                background: locked ? colors.surface : colors.surface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicBadge extends StatelessWidget {
  const _TopicBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.typography.caption.copyWith(color: foreground),
      ),
    );
  }
}
