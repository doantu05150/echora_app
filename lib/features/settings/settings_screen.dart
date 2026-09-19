import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../data/providers.dart';
import '../../data/user_preferences.dart';
import '../../ui/theme/app_theme.dart';
import '../player/display_mode.dart';
import '../player/playback/playback_timeline.dart';
import '../player/session_settings_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final preferences = ref.watch(preferencesProvider).value;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
            AppSpacing.screenHorizontal,
            AppSpacing.screenBottom,
          ),
          children: [
            Row(
              children: [
                SizedBox(
                  width: AppSize.iconButton,
                  height: AppSize.iconButton,
                  child: IconButton(
                    onPressed: onBack,
                    tooltip: Strings.back,
                    icon: Icon(Icons.arrow_back_rounded, color: colors.ink),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Strings.settingsTitle,
                  style: context.typography.displayLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            if (preferences != null) ...[
              _Group(
                label: Strings.settingsDefaults,
                children: [
                  _NavRow(
                    label: Strings.sheetSpeed,
                    value: Strings.wpmLabel(preferences.wpm),
                    onTap: () => _openDefaultsSheet(context),
                  ),
                  _NavRow(
                    label: Strings.sheetDuration,
                    value: Strings.filterMinutes(
                      preferences.preferredDurationMin,
                    ),
                    onTap: () => _openDefaultsSheet(context),
                  ),
                  _NavRow(
                    label: Strings.sheetDisplayMode,
                    value: _modeLabel(preferences),
                    onTap: () => _openDefaultsSheet(context),
                  ),
                  _NavRow(
                    label: Strings.sheetFontSize,
                    value: '${preferences.fontSizeSp.round()}sp',
                    onTap: () => _openDefaultsSheet(context),
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              _Group(
                label: Strings.settingsDevice,
                children: [
                  _SwitchRow(
                    label: Strings.sheetKeepScreenOn,
                    value: preferences.keepScreenOn,
                    onChanged: (value) => ref
                        .read(preferencesProvider.notifier)
                        .save(preferences.copyWith(keepScreenOn: value)),
                  ),
                  _SwitchRow(
                    label: Strings.settingsHaptic,
                    value: preferences.hapticOnSentence,
                    onChanged: (value) => ref
                        .read(preferencesProvider.notifier)
                        .save(preferences.copyWith(hapticOnSentence: value)),
                    last: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],

            _Group(
              label: Strings.settingsUpcoming,
              children: [
                _NavRow(
                  label: Strings.settingsRecording,
                  value: Strings.settingsVersionTag,
                  onTap: null,
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            _Group(
              label: Strings.settingsOther,
              children: [
                _NavRow(
                  label: Strings.settingsLanguage,
                  value: Strings.settingsLanguageValue,
                  onTap: null,
                ),
                _NavRow(
                  label: Strings.settingsAbout,
                  value: Strings.appName,
                  onTap: null,
                  last: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _modeLabel(UserPreferences preferences) =>
      switch (preferences.displayMode) {
        DisplayMode.scroll => Strings.sheetModeScroll,
        DisplayMode.line => Strings.sheetModeLine,
        DisplayMode.karaoke => Strings.sheetModeKaraoke,
        DisplayMode.voice => Strings.sheetModeVoice,
      };
}

/// Sheet ở đây chỉnh mặc định cho buổi luyện sau, không có bài nào đang chạy.
void _openDefaultsSheet(BuildContext context) {
  showSessionSettingsSheet(
    context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final preferences = ref.watch(preferencesProvider).value;
        if (preferences == null) return const SizedBox.shrink();

        void save(UserPreferences value) =>
            ref.read(preferencesProvider.notifier).save(value);

        return SessionSettingsSheet(
          wpm: preferences.wpm,
          preferredDurationMin: preferences.preferredDurationMin,
          displayMode: preferences.displayMode,
          fontSizeSp: preferences.fontSizeSp,
          keepScreenOn: preferences.keepScreenOn,
          onWpm: (value) => save(
            preferences.copyWith(
              wpm: value.clamp(kMinWpm, kMaxWpm),
            ),
          ),
          onDuration: (value) =>
              save(preferences.copyWith(preferredDurationMin: value)),
          onDisplayMode: (value) =>
              save(preferences.copyWith(displayMode: value)),
          onFontSize: (value) => save(preferences.copyWith(fontSizeSp: value)),
          onKeepScreenOn: (value) =>
              save(preferences.copyWith(keepScreenOn: value)),
        );
      },
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xxs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: context.typography.caption.copyWith(color: colors.inkMuted),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.last = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSize.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: colors.borderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.typography.body.copyWith(
                  color: enabled ? colors.ink : colors.inkFaint,
                ),
              ),
            ),
            Text(
              value,
              style: context.typography.caption.copyWith(
                color: colors.inkMuted,
              ),
            ),
            if (enabled)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.inkFaint,
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.minTouchTarget),
      padding: const EdgeInsets.only(
        left: AppSpacing.cardPadding,
        right: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.typography.body)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
