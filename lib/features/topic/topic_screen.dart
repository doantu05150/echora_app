import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../data/local/progress_repository.dart';
import '../../data/models/passage.dart';
import '../../data/models/topic.dart';
import '../../data/providers.dart';
import '../../ui/theme/app_theme.dart';
import '../player/playback/playback_timeline.dart';

/// Bộ lọc độ dài đang chọn của màn Topic. `null` = tất cả.
class TopicDurationFilter extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? durationMin) => state = durationMin;
}

final topicDurationFilterProvider =
    NotifierProvider<TopicDurationFilter, int?>(
      TopicDurationFilter.new,
      isAutoDispose: true,
    );

const _durationFilters = <int?>[null, 2, 3, 5, 7];

class TopicScreen extends ConsumerWidget {
  const TopicScreen({
    super.key,
    required this.topicId,
    required this.onBack,
    required this.onOpenPassage,
  });

  final String topicId;
  final VoidCallback onBack;
  final void Function(String passageId) onOpenPassage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final topic = ref.watch(topicProvider(topicId)).value;
    final durationMin = ref.watch(topicDurationFilterProvider);
    final passages = ref.watch(
      passagesProvider((topicId: topicId, durationMin: durationMin)),
    );
    final accent = topic == null
        ? colors.violet
        : colors.byToken(topic.colorToken);

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TopicHeader(
                topic: topic,
                accent: accent,
                onBack: onBack,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.screenBottom,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _DurationFilterRow(
                      selected: durationMin,
                      accent: accent,
                      onSelect: ref
                          .read(topicDurationFilterProvider.notifier)
                          .select,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  switch (passages) {
                    AsyncData(:final value) when value.isEmpty =>
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: Text(
                            Strings.topicEmpty,
                            textAlign: TextAlign.center,
                            style: context.typography.body.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    AsyncData(:final value) => SliverList.separated(
                      itemCount: value.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.smPlus),
                      itemBuilder: (context, index) => PassageTile(
                        passage: value[index],
                        accent: accent,
                        progress: ref
                            .watch(progressByPassageProvider)
                            .value?[value[index].id],
                        bookmarked:
                            ref
                                .watch(bookmarkedIdsProvider)
                                .value
                                ?.contains(value[index].id) ??
                            false,
                        onTap: () => onOpenPassage(value[index].id),
                      ),
                    ),
                    _ => const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({
    required this.topic,
    required this.accent,
    required this.onBack,
  });

  final Topic? topic;
  final AccentColor accent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: accent.tint,
        border: Border(bottom: BorderSide(color: accent.tintBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSize.iconButton,
            height: AppSize.iconButton,
            child: IconButton(
              onPressed: onBack,
              tooltip: Strings.back,
              icon: Icon(Icons.arrow_back_rounded, color: accent.onTint),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic?.title ?? '',
                  style: context.typography.displayLarge.copyWith(
                    color: accent.onTint,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  topic?.description ?? '',
                  style: context.typography.bodySmall.copyWith(
                    color: accent.onTint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationFilterRow extends StatelessWidget {
  const _DurationFilterRow({
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final int? selected;
  final AccentColor accent;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in _durationFilters)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterChip(
                label: value == null
                    ? Strings.filterAll
                    : Strings.filterMinutes(value),
                selected: value == selected,
                accent: accent,
                colors: colors,
                onTap: () => onSelect(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AccentColor accent;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.violet.base : colors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSize.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
          child: Text(
            label,
            style: context.typography.label.copyWith(
              color: selected ? colors.surface : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class PassageTile extends StatelessWidget {
  const PassageTile({
    super.key,
    required this.passage,
    required this.accent,
    required this.progress,
    required this.bookmarked,
    required this.onTap,
  });

  final Passage passage;
  final AccentColor accent;
  final PassageProgress? progress;
  final bool bookmarked;
  final VoidCallback onTap;

  /// Bài đang dở: đã bắt đầu nhưng chưa xong.
  bool get _inProgress =>
      progress != null && !progress!.isCompleted && progress!.positionMs > 0;

  String get _statusLabel {
    final saved = progress;
    if (saved == null || saved.positionMs == 0) return Strings.notStarted;

    final totalMs = passage.wordCount / kReferenceWpm * 60000;
    final percent = (saved.positionMs / totalMs * 100).clamp(0, 100).round();
    return Strings.completedPercent(saved.isCompleted ? 100 : percent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _inProgress ? accent.base : colors.border,
              width: _inProgress ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  passage.order.toString().padLeft(2, '0'),
                  style: context.typography.numeric.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passage.title,
                      style: context.typography.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${Strings.durationLabel(passage.durationMin)} · '
                      '${passage.level} · $_statusLabel',
                      style: context.typography.caption.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (_inProgress)
                Icon(Icons.play_arrow_rounded, color: accent.base, size: 22)
              else
                Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: bookmarked ? colors.clay.base : colors.inkFaint,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
