import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/strings.dart';
import '../../data/local/progress_repository.dart';
import '../../data/models/passage.dart';
import '../../data/providers.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/echora_scaffold.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.onOpenPassage});

  final void Function(String passageId) onOpenPassage;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(practiceStatsProvider).value;
    final bookmarks = ref.watch(bookmarkedIdsProvider).value ?? const <String>{};
    final sessions =
        ref.watch(recentSessionsProvider).value ?? const <PracticeSession>[];

    return EchoraScaffold(
      slivers: [
        SliverToBoxAdapter(child: _ProfileHeader(stats: stats)),
        const SliverGap(AppSpacing.sectionGap),
        SliverToBoxAdapter(
          child: _StatsRow(
            streakDays: stats?.streakDays ?? 0,
            minutes: stats?.totalMinutes ?? 0,
            passages: stats?.passageCount ?? 0,
          ),
        ),
        const SliverGap(AppSpacing.sectionGap),
        SliverToBoxAdapter(
          child: _Tabs(
            selected: _tab,
            onSelect: (value) => setState(() => _tab = value),
          ),
        ),
        const SliverGap(AppSpacing.md),
        if (_tab == 0)
          _PassageIdList(
            passageIds: bookmarks.toList(),
            emptyLabel: Strings.savedEmpty,
            onOpenPassage: widget.onOpenPassage,
          )
        else
          _HistoryList(
            sessions: sessions,
            onOpenPassage: widget.onOpenPassage,
          ),
      ],
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.stats});

  final PracticeStats? stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final level = ref.watch(practisedLevelProvider).value;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.violet.tint,
            shape: BoxShape.circle,
            border: Border.all(color: colors.violet.tintBorder),
          ),
          child: Text(
            Strings.learnerInitial,
            style: context.typography.displaySmall.copyWith(
              color: colors.violet.onTint,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.mdPlus),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Strings.learnerName, style: context.typography.displayMedium),
              const SizedBox(height: 2),
              Text(
                level ?? Strings.levelUnknown,
                style: context.typography.bodySmall.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.streakDays,
    required this.minutes,
    required this.passages,
  });

  final int streakDays;
  final int minutes;
  final int passages;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        _StatCard(
          label: Strings.statStreak,
          value: '$streakDays',
          accent: colors.amber,
        ),
        const SizedBox(width: AppSpacing.gridGap),
        _StatCard(
          label: Strings.statMinutes,
          value: '$minutes',
          accent: colors.teal,
        ),
        const SizedBox(width: AppSpacing.gridGap),
        _StatCard(
          label: Strings.statPassages,
          value: '$passages',
          accent: colors.violet,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final AccentColor accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.mdPlus,
        ),
        decoration: BoxDecoration(
          color: accent.tint,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accent.tintBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: context.typography.displayMedium.copyWith(
                color: accent.onTint,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: context.typography.caption.copyWith(color: accent.onTint),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          for (final (index, label) in [
            (0, Strings.tabSaved),
            (1, Strings.tabHistory),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(index),
                child: Container(
                  height: AppSize.minTouchTarget - AppSpacing.sm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == index ? colors.surface : null,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    label,
                    style: context.typography.label.copyWith(
                      color: selected == index ? colors.ink : colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PassageIdList extends ConsumerWidget {
  const _PassageIdList({
    required this.passageIds,
    required this.emptyLabel,
    required this.onOpenPassage,
  });

  final List<String> passageIds;
  final String emptyLabel;
  final void Function(String passageId) onOpenPassage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (passageIds.isEmpty) return _EmptyNote(label: emptyLabel);

    return SliverList.separated(
      itemCount: passageIds.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final passage = ref.watch(passageProvider(passageIds[index])).value;
        if (passage == null) return const SizedBox.shrink();
        return _PassageRow(
          passage: passage,
          onTap: () => onOpenPassage(passage.id),
        );
      },
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.sessions, required this.onOpenPassage});

  final List<PracticeSession> sessions;
  final void Function(String passageId) onOpenPassage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessions.isEmpty) return const _EmptyNote(label: Strings.historyEmpty);

    return SliverList.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final passage = ref.watch(passageProvider(session.passageId)).value;
        if (passage == null) return const SizedBox.shrink();

        return _PassageRow(
          passage: passage,
          trailing:
              '${formatVietnameseDate(session.startedAt)} · '
              '${(session.durationSec / 60).ceil()} phút',
          onTap: () => onOpenPassage(passage.id),
        );
      },
    );
  }
}

class _PassageRow extends StatelessWidget {
  const _PassageRow({
    required this.passage,
    required this.onTap,
    this.trailing,
  });

  final Passage passage;
  final String? trailing;
  final VoidCallback onTap;

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
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passage.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.title,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                trailing ??
                    '${Strings.durationLabel(passage.durationMin)} · '
                        '${passage.level}',
                style: context.typography.caption.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.typography.body.copyWith(
            color: context.colors.inkMuted,
          ),
        ),
      ),
    );
  }
}
