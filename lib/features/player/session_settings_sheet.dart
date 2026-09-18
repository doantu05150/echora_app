import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../ui/theme/app_theme.dart';
import 'display_mode.dart';
import 'playback/playback_timeline.dart';

const _wpmPresets = <(String, int)>[
  (Strings.sheetPresetSlow, 70),
  (Strings.sheetPresetNormal, kReferenceWpm),
  (Strings.sheetPresetFast, 110),
  (Strings.sheetPresetVeryFast, 130),
];

const _durations = [2, 3, 5, 7];
const _minFontSizeSp = 20.0;
const _maxFontSizeSp = 40.0;

Future<void> showSessionSettingsSheet(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// Thay đổi có hiệu lực ngay khi chỉnh — người học cần nghe thấy tốc độ đổi
/// để chọn. Nút Áp dụng chỉ đóng sheet.
class SessionSettingsSheet extends StatelessWidget {
  const SessionSettingsSheet({
    super.key,
    required this.wpm,
    required this.preferredDurationMin,
    required this.displayMode,
    required this.fontSizeSp,
    required this.keepScreenOn,
    required this.onWpm,
    required this.onDuration,
    required this.onDisplayMode,
    required this.onFontSize,
    required this.onKeepScreenOn,
  });

  final int wpm;
  final int preferredDurationMin;
  final DisplayMode displayMode;
  final double fontSizeSp;
  final bool keepScreenOn;

  final ValueChanged<int> onWpm;
  final ValueChanged<int> onDuration;
  final ValueChanged<DisplayMode> onDisplayMode;
  final ValueChanged<double> onFontSize;
  final ValueChanged<bool> onKeepScreenOn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Strings.sheetTitle, style: context.typography.displaySmall),
            const SizedBox(height: AppSpacing.xl),

            _SectionLabel(
              label: Strings.sheetSpeed,
              trailing: Strings.wpmLabel(wpm),
            ),
            Slider(
              value: wpm.toDouble(),
              min: kMinWpm.toDouble(),
              max: kMaxWpm.toDouble(),
              divisions: (kMaxWpm - kMinWpm) ~/ kWpmStep,
              onChanged: (value) => onWpm(value.round()),
            ),
            Row(
              children: [
                for (final (label, value) in _wpmPresets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _ChoiceChip(
                        label: label,
                        selected: wpm == value,
                        onTap: () => onWpm(value),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            const _SectionLabel(label: Strings.sheetDuration),
            Text(
              Strings.sheetDurationHint,
              style: context.typography.caption.copyWith(
                color: colors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.smPlus),
            Row(
              children: [
                for (final value in _durations)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _ChoiceChip(
                        label: Strings.filterMinutes(value),
                        selected: preferredDurationMin == value,
                        onTap: () => onDuration(value),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            const _SectionLabel(label: Strings.sheetDisplayMode),
            const SizedBox(height: AppSpacing.sm),
            for (final mode in DisplayMode.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ModeOption(
                  mode: mode,
                  selected: displayMode == mode,
                  onTap: () => onDisplayMode(mode),
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            _SectionLabel(
              label: Strings.sheetFontSize,
              trailing: '${fontSizeSp.round()}sp',
            ),
            Slider(
              value: fontSizeSp.clamp(_minFontSizeSp, _maxFontSizeSp),
              min: _minFontSizeSp,
              max: _maxFontSizeSp,
              divisions: (_maxFontSizeSp - _minFontSizeSp) ~/ 1,
              onChanged: (value) => onFontSize(value.roundToDouble()),
            ),
            const SizedBox(height: AppSpacing.sm),

            SwitchListTile(
              value: keepScreenOn,
              onChanged: onKeepScreenOn,
              contentPadding: EdgeInsets.zero,
              title: Text(
                Strings.sheetKeepScreenOn,
                style: context.typography.title,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.violet.base,
                  foregroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  Strings.sheetApply,
                  style: context.typography.title.copyWith(
                    color: colors.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.typography.title),
        if (trailing != null)
          Text(
            trailing!,
            style: context.typography.numeric.copyWith(color: colors.inkMuted),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.violet.base : colors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: AppSize.minTouchTarget,
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.typography.caption.copyWith(
              color: selected ? colors.surface : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final DisplayMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.violet;

    final (title, hint) = switch (mode) {
      DisplayMode.scroll => (Strings.sheetModeScroll, Strings.sheetModeScrollHint),
      DisplayMode.line => (Strings.sheetModeLine, Strings.sheetModeLineHint),
      DisplayMode.karaoke => (
        Strings.sheetModeKaraoke,
        Strings.sheetModeKaraokeHint,
      ),
    };

    return Material(
      color: selected ? accent.tint : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.mdPlus),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? accent.tintBorder : colors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.typography.title.copyWith(
                        color: selected ? accent.onTint : colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: context.typography.caption.copyWith(
                        color: selected ? accent.onTint : colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent.base, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
