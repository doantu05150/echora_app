import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/strings.dart';
import '../../data/providers.dart';
import '../../ui/theme/app_theme.dart';
import 'display_mode.dart';
import 'player_controller.dart';
import 'session_settings_sheet.dart';
import 'playback/playback_clock.dart';
import 'playback/playback_timeline.dart';
import 'widgets/clock_builder.dart';
import 'widgets/karaoke_text_view.dart';
import 'widgets/line_text_view.dart';
import 'widgets/scroll_text_view.dart';
import 'widgets/sentence_haptics.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key, required this.passageId});

  final String passageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(playerControllerProvider(passageId));

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncData(:final value) => _PlayerBody(
            state: value,
            controller: ref.read(playerControllerProvider(passageId).notifier),
          ),
          AsyncError(:final error) => Center(
            child: Text('$error', style: context.typography.body),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _PlayerBody extends ConsumerWidget {
  const _PlayerBody({required this.state, required this.controller});

  final PlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final topic = ref.watch(topicProvider(state.passage.topicId)).value;
    final accent = topic == null
        ? colors.clay
        : colors.byToken(topic.colorToken);

    return Column(
      children: [
        _TopBar(
          topicTitle: topic?.title ?? '',
          passageOrder: state.passage.order,
          title: state.passage.title,
          bookmarked:
              ref
                  .watch(bookmarkedIdsProvider)
                  .value
                  ?.contains(state.passage.id) ??
              false,
          onToggleBookmark: controller.toggleBookmark,
        ),
        Expanded(
          child: ClockBuilder(
            clock: controller.clock,
            builder: (context, elapsedMs) => SentenceHaptics(
              timeline: state.timeline,
              elapsedMs: elapsedMs,
              enabled: state.preferences.hapticOnSentence,
              child: switch (state.displayMode) {
                DisplayMode.scroll || DisplayMode.voice => ScrollTextView(
                  timeline: state.timeline,
                  elapsedMs: elapsedMs,
                  fontSizeSp: state.fontSizeSp,
                ),
                DisplayMode.line => LineTextView(
                  timeline: state.timeline,
                  elapsedMs: elapsedMs,
                  fontSizeSp: state.fontSizeSp,
                  accent: accent,
                ),
                DisplayMode.karaoke => KaraokeTextView(
                  timeline: state.timeline,
                  elapsedMs: elapsedMs,
                  fontSizeSp: state.fontSizeSp,
                  accent: accent,
                ),
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.screenBottom,
          ),
          child: Column(
            children: [
              ClockBuilder(
                clock: controller.clock,
                builder: (context, elapsedMs) => _ProgressRow(
                  elapsedMs: elapsedMs,
                  timeline: state.timeline,
                ),
              ),
              const SizedBox(height: AppSpacing.lgPlus),
              _Controls(
                controller: controller,
                wpm: state.wpm,
                onOpenSettings: () => _openSettings(context, controller),
              ),
              const SizedBox(height: AppSpacing.lgPlus),
              const _RecordingTeaser(),
            ],
          ),
        ),
      ],
    );
  }
}

void _openSettings(BuildContext context, PlayerController controller) {
  showSessionSettingsSheet(
    context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final state = ref
            .watch(playerControllerProvider(controller.passageId))
            .requireValue;
        return SessionSettingsSheet(
          wpm: state.wpm,
          preferredDurationMin: state.preferences.preferredDurationMin,
          displayMode: state.displayMode,
          fontSizeSp: state.fontSizeSp,
          keepScreenOn: state.keepScreenOn,
          voiceAvailable: state.hasVoice,
          onWpm: controller.setWpm,
          onDuration: controller.setPreferredDurationMin,
          onDisplayMode: controller.setDisplayMode,
          onFontSize: controller.setFontSizeSp,
          onKeepScreenOn: controller.setKeepScreenOn,
        );
      },
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.topicTitle,
    required this.passageOrder,
    required this.title,
    required this.bookmarked,
    required this.onToggleBookmark,
  });

  final String topicTitle;
  final int passageOrder;
  final String title;
  final bool bookmarked;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSize.iconButton,
            height: AppSize.iconButton,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: Strings.back,
              icon: Icon(Icons.arrow_back_rounded, color: colors.ink),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$topicTitle · ${Strings.passageIndex(passageOrder)}',
                  style: context.typography.caption.copyWith(
                    color: colors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.title,
                ),
              ],
            ),
          ),
          SizedBox(
            width: AppSize.iconButton,
            height: AppSize.iconButton,
            child: IconButton(
              onPressed: onToggleBookmark,
              tooltip: bookmarked
                  ? Strings.bookmarkRemove
                  : Strings.bookmarkAdd,
              icon: Icon(
                bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: bookmarked ? colors.clay.base : colors.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.elapsedMs, required this.timeline});

  final int elapsedMs;
  final PlaybackTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: timeline.progressAt(elapsedMs),
            minHeight: 4,
            backgroundColor: colors.surfaceMuted,
            valueColor: AlwaysStoppedAnimation(colors.violet.base),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatClock(elapsedMs),
              style: context.typography.numeric.copyWith(
                color: colors.inkMuted,
              ),
            ),
            Text(
              Strings.wpmLabel(timeline.wpm),
              style: context.typography.numeric.copyWith(
                color: colors.inkMuted,
              ),
            ),
            Text(
              formatClock(timeline.totalMs),
              style: context.typography.numeric.copyWith(
                color: colors.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.wpm,
    required this.onOpenSettings,
  });

  final PlayerController controller;
  final int wpm;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SpeedChip(wpm: wpm, onTap: onOpenSettings),
        _SeekButton(
          icon: Icons.replay_10_rounded,
          tooltip: Strings.seekBack,
          onTap: () => controller.seekBy(const Duration(seconds: -10)),
        ),
        _PlayButton(clock: controller.clock, onTap: controller.togglePlay),
        _SeekButton(
          icon: Icons.forward_10_rounded,
          tooltip: Strings.seekForward,
          onTap: () => controller.seekBy(const Duration(seconds: 10)),
        ),
        SizedBox(
          width: AppSize.iconButton,
          height: AppSize.iconButton,
          child: IconButton(
            onPressed: onOpenSettings,
            tooltip: Strings.openSettings,
            icon: Icon(Icons.tune_rounded, color: colors.inkMuted),
          ),
        ),
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.wpm, required this.onTap});

  final int wpm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: AppSize.minTouchTarget,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mdPlus),
          child: Text(
            formatMultiplier(multiplierOf(wpm)),
            style: context.typography.label.copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }
}

class _SeekButton extends StatelessWidget {
  const _SeekButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: AppSize.seekButton,
      height: AppSize.seekButton,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 26, color: colors.ink),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.clock, required this.onTap});

  final PlaybackClock clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListenableBuilder(
      listenable: clock,
      builder: (context, _) {
        final playing = clock.isPlaying;
        return Semantics(
          button: true,
          label: playing ? Strings.pause : Strings.play,
          child: Material(
            color: colors.violet.base,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: AppSize.playButton,
                height: AppSize.playButton,
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: colors.surface,
                  size: 34,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecordingTeaser extends StatelessWidget {
  const _RecordingTeaser();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none_rounded, size: 16, color: colors.inkFaint),
          const SizedBox(width: AppSpacing.sm),
          Text(
            Strings.playerRecordingTeaser,
            style: context.typography.caption.copyWith(color: colors.inkFaint),
          ),
        ],
      ),
    );
  }
}
